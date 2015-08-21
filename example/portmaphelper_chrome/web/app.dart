import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
//
//

import 'dart:isolate';


main() async {
  HetimaSocketBuilder builder = new HetimaSocketBuilderChrome(); 
  UpnpPortMapHelper helper = new UpnpPortMapHelper(builder, "test", ip:null, port:18080, retry:3);

  //
  // get network interface
  List<HetimaNetworkInterface> interfaces = await builder.getNetworkInterfaces();
  for (HetimaNetworkInterface i in interfaces) {
    print("<ni>${i.address} ${i.prefixLength} ${i.name}");
  }
  //
  // portmapping 
  try {
    for(StartGetExternalIp exip in await helper.startGetExternalIp(reuseRouter: true)) {
      print("<exip> ${exip.externalIp}");
    }
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
