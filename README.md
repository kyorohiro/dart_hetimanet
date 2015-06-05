# dart_hetimanet

A library for Dart developers. 
* HttpServer
* HttpClient
* UPnP PortMap

### Sample 
* HttpServer
https://github.com/kyorohiro/HetimaDelphinium

* UPnPPortMap
https://github.com/kyorohiro/HetimaPortMap

### Http Server
* [Retirect Server Sample](example/redirectserver)

### UPnP Portmap
#### create Searcher
```
  hetima.UpnpDeviceSearcher.createInstance(new HetiSocketBuilderChrome()).then((UpnpDeviceSearcher deviceSearcher) {
    print("### ok setupUpnp ${searcher}");
  }).catchError((e) {
    print("### error");
  });
```

#### search Router
```
  deviceSearcher.searchWanPPPDevice().then((int v) {
    if (deviceSearcher.deviceInfoList == null || deviceSearcher.deviceInfoList.length <= 0) {
      print("not found router");
    }
    for (hetima.UpnpDeviceInfo info in deviceSearcher.deviceInfoList) {
      print(info.getValue(hetima.UpnpDeviceInfo.KEY_USN, "*"));
    }
  }).catchError((e) {
    print("error");
  });
```

#### request global ip
```
  UpnpPPPDevice pppDevice = new UpnpPPPDevice(info);
  pppDevice.requestGetExternalIPAddress().then((UpnpGetExternalIPAddressResponse ip) {
    print("${ip.externalIp}");
  }).catchError((e) {
    print("error");
  });
```

#### request generic port mapping
```
  pppDevice.requestGetGenericPortMapping(newPortmappingIndex, mode).then((UpnpGetGenericPortMappingResponse r) {
    if (r.resultCode != 200) {
      print("failed");
      return;
    }

    print("publicPort = ${r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewExternalPort, "")}");
    print("localIp = ${r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewInternalClient, "")}");
    print("localPort = ${r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewInternalPort, "")}");
    print("protocol = ${r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewProtocol, "")}");
    print("portMapInfo.description = ${r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "")}");

  }).catchError((e) {
    print("error");
  });
```

#### request add port mapping
```
  pppDevice.requestAddPortMapping(publicPort, "tcp", localPort, localIp, 1, "test", 0)
  .then((hetima.UpnpAddPortMappingResponse resp) {
    if (resp.resultCode == 200) {
      print("ok");
    } else {
      print("failed");
    }
  }).catchError((e) {
      print("error");
  });
```

#### request remove port mapping
```
  pppDevice.requestDeletePortMapping(publicPort, "tcp")
  .then((hetima.UpnpDeletePortMappingResponse resp) {
    if (resp.resultCode == 200) {
      print("ok");
    } else {
      print("failed");
    }
  }).catchError((e) {
      print("error");
  });
```