# dart_hetimanet

A library for Dart developers. 
* TCP Socket(chrome, dart:io)
* UDP Socket(chrome, dart:io)
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
* sample app 
  example/HetimaPortMap
  https://chrome.google.com/webstore/detail/hetimaportmap/naifildeohmcocnmibaampijofhcohif
* sample source
  example/portmaphelper

```
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_dartio.dart';
//
//
main()  async {
  HetimaSocketBuilder builder = new HetimaSocketBuilderDartIO(); 
  UpnpPortMapHelper helper = new UpnpPortMapHelper(builder, "test");
  //
  // get network interface
  List<HetimaNetworkInterface> interfaces = await builder.getNetworkInterfaces();
  for (HetimaNetworkInterface i in interfaces) {
    print("<ni>${i.address} ${i.prefixLength} ${i.name}");
  }
  //
  // portmapping 
  try {
    StartGetExternalIp exip = await helper.startGetExternalIp(reuseRouter: true);
    print("<exip> ${exip.externalIp}");
  } catch (e) {
    print("<exip ERROR> ${e}");
  }
  //
  // get local ip
  try {
    StartGetLocalIPResult loip = await helper.startGetLocalIp();
    for(HetimaNetworkInterface i in loip.networkInterface) {
      print("<glip> ${i.address} ${i.name}");      
    }
  } catch (e) {
    print("<glip ERROR> ${e}");
  }
  //
  // start portmap
  try {
    StartPortMapResult sp = await helper.startPortMap();
    print("<add> ${sp}");
  } catch (e) {
    print("<add ERROR> ${e}");
  }
  //
  // end portmap
  try {
    DeleteAllPortMapResult ep = await helper.deletePortMapFromAppIdDesc();
    print("<del> ${ep}");
  } catch (e) {
    print("<del ERROR> ${e}");
  }
}
```