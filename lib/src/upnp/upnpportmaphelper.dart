library hetimanet.upnp.helper;

import 'dart:async';
import '../net/hetisocket.dart';
import 'upnpdeviceinfo.dart';
import 'upnpdevicesearcher.dart';
import 'upnppppdevice.dart';
import 'upnppppdevice_result.dart';

/**
 * app parts
 */
class UpnpPortMapHelper {
  String appid = "";
  String localIp = "0.0.0.0";
  int basePort = 18085;
  int numOfRetry = 0;
  int _requestedPort = 18085;
  String _externalAddress = "";

  int get externalPort => _requestedPort;
  HetimaSocketBuilder builder = null;
  String get externalIp => _externalAddress;
  String get appIdDesc => "hetim(${appid})";

  List<UpnpDeviceInfo> _currentUpnpDeviceInfo = [];
  bool _verbose = false;
  bool get verbose => _verbose;

  UpnpPortMapHelper(HetimaSocketBuilder builder, String appid, {bool verbose: false, String ip: "0.0.0.0", int port: 18080, int retry: 0}) {
    this.appid = appid;
    this.builder = builder;
    this._verbose = verbose;
    this.localIp = ip;
    this.basePort = port;
    this.numOfRetry = retry;
  }

  StreamController<String> _controllerUpdateGlobalPort = new StreamController.broadcast();
  Stream<String> get onUpdateGlobalPort => _controllerUpdateGlobalPort.stream;

  StreamController<String> _controllerUpdateGlobalIp = new StreamController.broadcast();
  Stream<String> get onUpdateGlobalIp => _controllerUpdateGlobalIp.stream;

  StreamController<String> _controllerUpdateLocalIp = new StreamController.broadcast();
  Stream<String> get onUpdateLocalIp => _controllerUpdateLocalIp.stream;

  //
  //
  // ####
  Future<List<StartGetExternalIp>> startGetExternalIp({bool reuseRouter: false}) async {
    List<UpnpDeviceInfo> deviceInfoList = await searchRoutder(reuseRouter: reuseRouter);
    List<String> externalIps = [];

    for (UpnpDeviceInfo info in deviceInfoList) {
      UpnpPPPDevice pppDevice = new UpnpPPPDevice(info, verbose: _verbose);
      UpnpGetExternalIPAddressResponse res = await pppDevice.requestGetExternalIPAddress();
      _externalAddress = res.externalIp;
      _controllerUpdateGlobalIp.add(res.externalIp);
      externalIps.add(res.externalIp);
    }
    List<StartGetExternalIp> ret = [];
    for (String ip in externalIps) {
      ret.add(new StartGetExternalIp(ip));
    }
    return ret;
  }

  Future<StartPortMapResult> startPortMap({bool reuseRouter: false, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP, eagerError: false}) async {
    _requestedPort = basePort;
    List<UpnpDeviceInfo> deviceInfoList = await searchRoutder(reuseRouter: reuseRouter);

    UpnpDeviceInfo info = deviceInfoList.first;
    UpnpPPPDevice pppDevice = new UpnpPPPDevice(info, verbose: _verbose);
    int maxRetryExternalPort = _requestedPort + numOfRetry;

    tryAddPortMap() async {
      List<Future> r = [];
      r.add(pppDevice.requestAddPortMapping(_requestedPort, newProtocol, _requestedPort, localIp, UpnpPPPDevice.VALUE_ENABLE, appIdDesc, 0));
      List<UpnpAddPortMappingResponse> ress = await Future.wait(r, eagerError: false);

      bool have500 = false;
      bool all200 = true;
      bool have200 = false;
      StringBuffer message = new StringBuffer();
      for (UpnpAddPortMappingResponse r in ress) {
        if (r.resultCode == 500) {
          have500 = true;
        }
        if (r.resultCode != 200) {
          all200 = false;
        } else {
          have200 = true;
        }
        message.write("${r.resultCode},");
      }

      if (eagerError == false && have200 == true) {
        _controllerUpdateGlobalPort.add("${_requestedPort}");
        return new StartPortMapResult();
      } else if (true == all200) {
        _controllerUpdateGlobalPort.add("${_requestedPort}");
        return new StartPortMapResult();
      } else if (true == have500) {
        _requestedPort++;
        if (_requestedPort < maxRetryExternalPort) {
          return tryAddPortMap();
        } else {
          throw {"failed": "redirect max"};
        }
      } else {
        throw {"failed": "unexpected error code ${message}"};
      }
    }

    return tryAddPortMap();
  }

  Future<DeleteAllPortMapResult> deletePortMapFromAppIdDesc({bool reuseRouter: false, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP, eagerError: false}) {
    return getPortMapInfo(target: appIdDesc, reuseRouter: reuseRouter, eagerError: eagerError).then((List<GetPortMapInfoResult> results) {
      List<Future> r = [];
      for (GetPortMapInfoResult result in results) {
        List<int> externalPortList = [];
        for (PortMapInfo info in result.infos) {
          try {
            externalPortList.add(int.parse(info.externalPort));
          } catch (e) {
            ;
          }
        }
        r.add(deleteAllPortMap(externalPortList, newProtocol: newProtocol));
      }

      return Future.wait(r, eagerError: eagerError).then((d) {
        return new DeleteAllPortMapResult();
      });
    });
  }

  Future<List<UpnpDeviceInfo>> searchRoutder({bool reuseRouter: false}) async {
    if (reuseRouter == true && _currentUpnpDeviceInfo.length > 0) {
      return _currentUpnpDeviceInfo;
    } else {
      _currentUpnpDeviceInfo.clear();
      StartGetLocalIPResult r = await this.startGetLocalIp();
      List<Future> f = [];
      if(localIp == null) {
      for (HetimaNetworkInterface i in r.networkInterface) {
        if (i.prefixLength == 24 && i.address != "127.0.0.1") {
          f.add(searchRoutderFromAddress(i.address, reuseRouter: reuseRouter));
        }
      }
      } else {
        f.add(searchRoutderFromAddress(localIp, reuseRouter: reuseRouter));
      }
      List<UpnpDeviceInfo> ret = [];
      return Future.wait(f).then((List<List<UpnpDeviceInfo>> rs) {
        for (List<UpnpDeviceInfo> r in rs) {
          _currentUpnpDeviceInfo.addAll(r);
          ret.addAll(r);
        }
        return ret;
      });
    }
  }

  //
  //
  //
  Future<List<UpnpDeviceInfo>> searchRoutderFromAddress(String address, {bool reuseRouter: false}) async {
    UpnpDeviceSearcher searcher = null;
    try {
      searcher = await UpnpDeviceSearcher.createInstance(this.builder, verbose: _verbose, ip: address);
      await searcher.searchWanPPPDevice(3);
      if (searcher.deviceInfoList.length <= 0) {
        throw {"failed": "not found router"};
      }
      return searcher.deviceInfoList;
    } finally {
      try {
        if(searcher != null) {
           searcher.close();
        }
      } catch (e) {}
    }
  }

  void clearSearchedRouterInfo() {
    _currentUpnpDeviceInfo.clear();
  }

  Future<DeleteAllPortMapResult> deleteAllPortMap(List<int> deleteExternalPortList, {bool reuseRouter: false, newProtocol: UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP}) {
    return searchRoutder(reuseRouter: reuseRouter).then((List<UpnpDeviceInfo> deviceInfoList) {
      List<Future> futures = [];
      UpnpDeviceInfo info = deviceInfoList.first;
      UpnpPPPDevice pppDevice = new UpnpPPPDevice(info, verbose: _verbose);
      for (int port in deleteExternalPortList) {
        futures.add(pppDevice.requestDeletePortMapping(port, newProtocol));
      }
      return Future.wait(futures).then((List<dynamic> d) {
        return new DeleteAllPortMapResult();
      });
    });
  }

  Future<List<GetPortMapInfoResult>> getPortMapInfo({String target: null, bool reuseRouter: false, eagerError: true}) async {
    List<UpnpDeviceInfo> deviceInfoList = await searchRoutder(reuseRouter: reuseRouter);
    List<Future> ret = [];
    for (UpnpDeviceInfo i in deviceInfoList) {
      ret.add(_getPortMapInfoFromUpnpDeviceInfo(i, target));
    }
    return await Future.wait(ret, eagerError: eagerError);
  }

  Future<GetPortMapInfoResult> _getPortMapInfoFromUpnpDeviceInfo(UpnpDeviceInfo info, String target) {
    int index = 0;
    GetPortMapInfoResult result = new GetPortMapInfoResult();

    tryGetPortMapInfo() async {
      UpnpPPPDevice pppDevice = new UpnpPPPDevice(info, verbose: _verbose);
      UpnpGetGenericPortMappingResponse res = await pppDevice.requestGetGenericPortMapping(index++);
      if (res.resultCode != 200) {
        return result;
      }
      String description = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
      String externalPort = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
      String internalPort = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewInternalPort, "");
      String ip = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
      String type = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewProtocol, "");
      if (target == null || description.contains(target)) {
        result.add(ip, internalPort, externalPort, description, type);
      }
      if (externalPort.replaceAll(" |\t|\r|\n", "") == "" && ip.replaceAll(" |\t|\r|\n", "") == "") {
        return result;
      }
      return tryGetPortMapInfo();
    }
    return tryGetPortMapInfo();
  }

  Future<StartGetLocalIPResult> startGetLocalIp() {
    return (this.builder).getNetworkInterfaces().then((List<HetimaNetworkInterface> l) {
      // search 24
      for (HetimaNetworkInterface i in l) {
        if (i.prefixLength == 24 && !i.address.startsWith("127")) {
          _controllerUpdateLocalIp.add(i.address);
          return new StartGetLocalIPResult(i.address, l);
        }
      }
      //
      for (HetimaNetworkInterface i in l) {
        if (i.prefixLength == 64) {
          _controllerUpdateLocalIp.add(i.address);
          return new StartGetLocalIPResult(i.address, l);
        }
      }
      return new StartGetLocalIPResult("0.0.0.0", l);
    });
  }
}

class DeleteAllPortMapResult {}
class StartPortMapResult {}

class PortMapInfo {
  String description = "";
  String externalPort = "";
  String internalPort = "";
  String ip = "";
  String type = "";
}
class GetPortMapInfoResult {
  List<PortMapInfo> infos = [];
  add(String ip, String internalPort, String externalPort, String description, String type) {
    infos.add(new PortMapInfo()
      ..description = description
      ..externalPort = externalPort
      ..ip = ip
      ..type = type
      ..internalPort = internalPort);
  }
}

class StartGetExternalIp {
  String _externalIp = "";
  String get externalIp => _externalIp;

  StartGetExternalIp(String externalIp) {
    this._externalIp = externalIp;
  }
}

class StartGetLocalIPResult {
  StartGetLocalIPResult(String address, List<HetimaNetworkInterface> l) {
    localIP = address;
    networkInterface.addAll(l);
  }
  String localIP = "";
  bool get founded => localIP != null;
  List<HetimaNetworkInterface> networkInterface = [];
}
