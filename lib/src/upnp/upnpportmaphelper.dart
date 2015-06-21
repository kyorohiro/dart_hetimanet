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
  async.Future<StartGetExternalIp> startGetExternalIp() {
    _externalPort = basePort;
    return UpnpDeviceSearcher.createInstance(this.builder).then((UpnpDeviceSearcher searcher) {
      return searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          throw {"failed": "not found rooter"};
        }

        UpnpDeviceInfo info = searcher.deviceInfoList.first;
        UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
        pppDevice.requestGetExternalIPAddress().then((UpnpGetExternalIPAddressResponse res) {
          _externalAddress = res.externalIp;
          _controllerUpdateGlobalIp.add(res.externalIp);
          return new StartGetExternalIp(res.externalIp);
        });
      }).catchError((e) {
        searcher.close();
        throw e;
      });
    });
  }

  async.Future<StartPortMapResult> startPortMap() {
    _externalPort = basePort;
    return UpnpDeviceSearcher.createInstance(this.builder).then((UpnpDeviceSearcher searcher) {
      return searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          throw {"failed": "not found rooter"};
        }

        UpnpDeviceInfo info = searcher.deviceInfoList.first;
        UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
        int maxRetryExternalPort = _externalPort + numOfRetry;

        tryAddPortMap() {
          print("############### ${this.localPort} ${this.localAddress}");
          return pppDevice
              .requestAddPortMapping(_externalPort, UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP, localPort, localAddress, UpnpPPPDevice.VALUE_ENABLE, appIdDesc, 0)
              .then((UpnpAddPortMappingResponse res) {
            if (200 == res.resultCode) {
              _controllerUpdateGlobalPort.add("${_externalPort}");
              searcher.close();
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
        searcher.close();
        throw e;
      });
    });
  }

  async.Future<DeleteAllPortMapResult> deleteAllPortMap(List<int> deletePortList) {
    return UpnpDeviceSearcher.createInstance(this.builder).then((UpnpDeviceSearcher searcher) {
      return searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          throw {"failed": "not found router"};
        }
        int index = 0;
        List<int> deletePortList = [];
        List<async.Future> futures = [];
        UpnpDeviceInfo info = searcher.deviceInfoList.first;
        UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
        for (int port in deletePortList) {
          futures.add(pppDevice.requestDeletePortMapping(port, UpnpPPPDevice.VALUE_PORT_MAPPING_PROTOCOL_TCP));
        }
        return async.Future.wait(futures).then((List<dynamic> d) {
          searcher.close();
          return new DeleteAllPortMapResult();
        });
      });
    });
  }

  async.Future<GetPortMapInfoResult> getPortMapInfo([String target = null]) {
    return UpnpDeviceSearcher.createInstance(this.builder).then((UpnpDeviceSearcher searcher) {
      return searcher.searchWanPPPDevice().then((int e) {
        if (searcher.deviceInfoList.length <= 0) {
          throw {"failed": "not found router"};
        }

        int index = 0;
        List<int> deletePortList = [];

        tryGetPortMapInfo() {
          UpnpDeviceInfo info = searcher.deviceInfoList.first;
          UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
          pppDevice.requestGetGenericPortMapping(index++).then((UpnpGetGenericPortMappingResponse res) {
            if (res.resultCode != 200) {
              return new GetPortMapInfoResult();
            }
            String description = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
            String port = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
            String ip = res.getValue(UpnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
            if (target == null || description.contains(target)) {
              //"hetim(${appid})") {
              int portAsNum = int.parse(port);
              deletePortList.add(portAsNum);
            }
            if (port.replaceAll(" |\t|\r|\n", "") == "" && ip.replaceAll(" |\t|\r|\n", "") == "") {
              return new GetPortMapInfoResult();
            }
            return tryGetPortMapInfo();
          }).catchError((e) {
            searcher.close();
            throw e;
          });
        }
        return tryGetPortMapInfo();
      });
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
class GetPortMapInfoResult {}

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
