import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_dartio.dart';

void main() {
  a();
}

a() async {
  HetiSocketBuilderChrome builder = new HetiSocketBuilderChrome();
  List<HetiNetworkInterface> interfaces = await builder.getNetworkInterfaces();
  for (HetiNetworkInterface i in interfaces) {
    print("### ${i.address} ${i.prefixLength} ${i.name}");
  }
  UpnpPortMapHelper helper = new UpnpPortMapHelper(builder, "test");
  helper.localAddress = "192.168.1.26";
  try {
    StartGetExternalIp exIP = await helper.startGetExternalIp(reuseRouter: true);
    print("#########${exIP.externalIp}");
  } catch (e) {
    print("####${e}");
  }
}
