import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_dartio.dart';
//
//
main()  async {
  HetiSocketBuilder builder = new HetiSocketBuilderDartIO(); 
  UpnpPortMapHelper helper = new UpnpPortMapHelper(builder, "test");
  //
  // get network interface
  List<HetiNetworkInterface> interfaces = await builder.getNetworkInterfaces();
  for (HetiNetworkInterface i in interfaces) {
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
    for(HetiNetworkInterface i in loip.networkInterface) {
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
