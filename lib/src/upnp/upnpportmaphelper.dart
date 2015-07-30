library hetimanet.upnp.helper;

import 'dart:async' as async;
import '../net/hetisocket.dart';
import 'upnpdeviceinfo.dart';
import 'upnpdevicesearcher.dart';
import 'upnppppdevice.dart';

/**
 * app parts
 */
class UpnpPortMapHelper {
  String appid = "";
  String localAddress = "0.0.0.0";
  int basePort = 18085;
  int localPort = 18085;
  int numOfRetry = 0;
  int _externalPort = 18085;
  String _externalAddress = "";

  int get externalPort => _externalPort;
  HetiSocketBuilder builder = null;
  String get externalIp => _externalAddress;
  String get appIdDesc => "hetim(${appid})";

  List<UpnpDeviceInfo> _currentUpnpDeviceInfo = [];

  UpnpPortMapHelper(HetiSocketBuilder builder, String appid) {
    this.appid = appid;
    this.builder = builder;
  }
  async.StreamController<String> _controllerUpdateGlobalPort = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateGlobalPort => _controllerUpdateGlobalPort.stream;

  async.StreamController<String> _controllerUpdateGlobalIp = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateGlobalIp => _controllerUpdateGlobalIp.stream;

  async.StreamController<String> _controllerUpdateLocalIp = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateLocalIp => _controllerUpdateLocalIp.stream;

  //
  //
  // ####
  async.Future<StartGetExternalIp> startGetExternalIp({bool reuseRouter: false}) {
    _externalPort = basePort;
    return searchRoutder(reuseRouter: reuseRouter).then((List<UpnpDeviceInfo> deviceInfoList) {
      UpnpDeviceInfo info = deviceInfoList.first;
      UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
      return pppDevice.requestGetExternalIPAddress().then((UpnpGetExternalIPAddressResponse res) {
        _externalAddress = res.externalIp;
        _controllerUpdateGlobalIp.add(res.externalIp);
        return new StartGetExternalIp(res.externalIp);
      });
    }).catchError((e) {
      throw e;
    });
  }

  async.Future<StartPortMapResult> startPortMap({bool reuseRouter: false,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP}) {
    _externalPort = basePort;
    return searchRoutder(reuseRouter: reuseRouter).then((List<UpnpDeviceInfo> deviceInfoList) {
      UpnpDeviceInfo info = deviceInfoList.first;
      UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
      int maxRetryExternalPort = _externalPort + numOfRetry;

      tryAddPortMap() {
        print("############### ${this.localPort} ${this.localAddress}");
        return pppDevice
            .requestAddPortMapping(_externalPort, newProtocol, localPort, localAddress, UpnpPPPDevice.VALUE_ENABLE, appIdDesc, 0)
            .then((UpnpAddPortMappingResponse res) {
          if (200 == res.resultCode) {
            _controllerUpdateGlobalPort.add("${_externalPort}");
            return new StartPortMapResult();
          } else if (500 == res.resultCode) {
            _externalPort++;
            if (_externalPort < maxRetryExternalPort) {
              return tryAddPortMap();
            } else {
              throw {"failed": "redirect max"};
            }
          } else {
            throw {"failed": "unexpected error code ${res.resultCode}"};
          }
        });
      }

      return tryAddPortMap();
    }).catchError((e) {
      throw e;
    });
  }

  async.Future<DeleteAllPortMapResult> deletePortMapFromAppIdDesc({bool reuseRouter: false}) {
    return getPortMapInfo(target: appIdDesc, reuseRouter: reuseRouter).then((GetPortMapInfoResult result) {
      List<int> externalPortList = [];
      for (PortMapInfo info in result.infos) {
        try {
          externalPortList.add(int.parse(info.externalPort));
        } catch (e) {
          ;
        }
      }
      return deleteAllPortMap(externalPortList);
    });
  }

  async.Future<List<UpnpDeviceInfo>> searchRoutder({bool reuseRouter: false}) {
    return new async.Future(() {
      if (reuseRouter == true && _currentUpnpDeviceInfo.length > 0) {
        return _currentUpnpDeviceInfo;
      } else {
        return UpnpDeviceSearcher.createInstance(this.builder).then((UpnpDeviceSearcher searcher) {
          return searcher.searchWanPPPDevice().then((int e) {
            if (searcher.deviceInfoList.length <= 0) {
              throw {"failed": "not found router"};
            }
            _currentUpnpDeviceInfo.clear();
            _currentUpnpDeviceInfo.addAll(searcher.deviceInfoList);
            return searcher.deviceInfoList;
          }).whenComplete(() {
            try {
              searcher.close();
            } catch (e) {}
          });
        });
      }
    });
  }

  void clearSearchedRouterInfo() {
    _currentUpnpDeviceInfo.clear();
  }

  async.Future<DeleteAllPortMapResult> deleteAllPortMap(List<int> deleteExternalPortList, {bool reuseRouter: false,newProtocol:UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP}) {
    return searchRoutder(reuseRouter: reuseRouter).then((List<UpnpDeviceInfo> deviceInfoList) {
      List<async.Future> futures = [];
      UpnpDeviceInfo info = deviceInfoList.first;
      UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
      for (int port in deleteExternalPortList) {
        futures.add(pppDevice.requestDeletePortMapping(port, newProtocol));
      }
      return async.Future.wait(futures).then((List<dynamic> d) {
        return new DeleteAllPortMapResult();
      });
    });
  }

  async.Future<GetPortMapInfoResult> getPortMapInfo({String target: null, bool reuseRouter: false}) {
    return searchRoutder(reuseRouter: reuseRouter).then((List<UpnpDeviceInfo> deviceInfoList) {
      UpnpDeviceInfo info = deviceInfoList.first;

      int index = 0;
      GetPortMapInfoResult result = new GetPortMapInfoResult();

      tryGetPortMapInfo() {
        UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
        return pppDevice.requestGetGenericPortMapping(index++).then((UpnpGetGenericPortMappingResponse res) {
          if (res.resultCode != 200) {
            return result;
          }
          String description = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
          String externalPort = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
          String internalPort = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewInternalPort, "");
          String ip = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
          String type = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewProtocol, "");
          if (target == null || description.contains(target)) {
            //"hetim(${appid})") {
            result.add(ip, internalPort, externalPort, description, type);
          }
          if (externalPort.replaceAll(" |\t|\r|\n", "") == "" && ip.replaceAll(" |\t|\r|\n", "") == "") {
            return result;
          }
          return tryGetPortMapInfo();
        }).catchError((e) {
          throw e;
        });
      }
      return tryGetPortMapInfo();
    });
  }

  async.Future<StartGetLocalIPResult> startGetLocalIp() {
    return (this.builder).getNetworkInterfaces().then((List<HetiNetworkInterface> l) {
      // search 24
      for (HetiNetworkInterface i in l) {
        if (i.prefixLength == 24 && !i.address.startsWith("127")) {
          _controllerUpdateLocalIp.add(i.address);
          return new StartGetLocalIPResult(i.address, l);
        }
      }
      //
      for (HetiNetworkInterface i in l) {
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
  StartGetLocalIPResult(String address, List<HetiNetworkInterface> l) {
    localIP = address;
    networkInterface.addAll(l);
  }
  String localIP = "";
  bool get founded => localIP != null;
  List<HetiNetworkInterface> networkInterface = [];
}
