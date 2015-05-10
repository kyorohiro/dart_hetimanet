part of hetimanet.upnp;

class UpnpPortMappingSample {
  List<UPnpPPPDevice> foundPPPDevice = new List();
  HetiSocketBuilder _builder;
  UpnpPortMappingSample(HetiSocketBuilder builder)
  {
    _builder = builder;
  }
  async.Future<UpnpPortMappingResult> addPortMapping(String localIp, int localPort, int remotePort, String protocol, [int timeoutSecound = 10, int durationMinute = 24 * 60, String label = "test"]) {
    async.Completer<UpnpPortMappingResult> completer = new async.Completer();
    List<UPnpPPPDevice> portMappedDevice = new List();
    UpnpDeviceSearcher.createInstance(_builder).then((UpnpDeviceSearcher searcher) {

      searcher.onReceive().listen((UPnpDeviceInfo deviceInfo) {
        UPnpPPPDevice pppDevice = new UPnpPPPDevice(deviceInfo);
        pppDevice.requestAddPortMapping(remotePort, protocol, localPort, localIp, UPnpPPPDevice.VALUE_ENABLE, label, durationMinute).then((UPnpAddPortMappingResponse v) {
            if (v.resultCode == 200) {
              portMappedDevice.add(pppDevice);
            }
            new async.Future.delayed(new Duration(seconds: 3)).then((t){
              if(portMappedDevice.length == 0) {
                completer.complete(new UpnpPortMappingResult.timeout());
              } else {
                completer.complete(new UpnpPortMappingResult.okmapping(portMappedDevice));                
              }
            });
        }).catchError((e){
        });
      });
      async.Future f = new async.Future.delayed(new Duration(seconds: timeoutSecound)).then((d) {
        if (!completer.isCompleted) {
          completer.complete(new UpnpPortMappingResult.timeout());
        }
      });
      return searcher.searchWanPPPDevice();
    }).catchError((e){
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }

  async.Future<UpnpPortMappingResult> delPortMapping(int remotePort, String protocol, [int timeoutSecound = 10]) {
    async.Completer<UpnpPortMappingResult> completer = new async.Completer();
    List<UPnpPPPDevice> portMappedDevice = new List();
    UpnpDeviceSearcher.createInstance(_builder).then((UpnpDeviceSearcher searcher) {

      searcher.onReceive().listen((UPnpDeviceInfo deviceInfo) {
        UPnpPPPDevice pppDevice = new UPnpPPPDevice(deviceInfo);
        pppDevice.requestDeletePortMapping(remotePort, protocol).then((UPnpDeletePortMappingResponse v) {
            if (v.resultCode == 200) {
              portMappedDevice.add(pppDevice);
            }
            new async.Future.delayed(new Duration(seconds: 3)).then((t){
              if(portMappedDevice.length == 0) {
                completer.complete(new UpnpPortMappingResult.timeout());
              } else {
                completer.complete(new UpnpPortMappingResult.okmapping(portMappedDevice));                
              }
            });
        }).catchError((e){
        });
      });
      async.Future f = new async.Future.delayed(new Duration(seconds: timeoutSecound)).then((d) {
        if (!completer.isCompleted) {
          completer.complete(new UpnpPortMappingResult.timeout());
        }
      });
      return searcher.searchWanPPPDevice();
    }).catchError((e){
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    });
    return completer.future;
  }
}

class UpnpPortMappingResult {
  static final int NOT_FOUND = -1;
  static final int FAILED_MAPPING = -2;
  static final int OK_MAPPING = 1;
  int result = 0;
  String message = "";
  List<UPnpPPPDevice> deviceList = new List();
  UpnpPortMappingResult.timeout() {
    result = NOT_FOUND;
    message = "timeout";
  }
  UpnpPortMappingResult.okmapping(List<UPnpPPPDevice> portMappedDevice) {
    result = OK_MAPPING;
    message = "timeout";
    deviceList = portMappedDevice; 
  }
  UpnpPortMappingResult.failed() {
    result = FAILED_MAPPING;
    message = "timeout";
  }
}

