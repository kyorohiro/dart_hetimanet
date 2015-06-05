
import 'package:unittest/unittest.dart' as unit;
import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
//import '../lib/hetimanet_chrome.dart' as hetima_cl;
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:html' as html;
import 'dart:async' as async;


void main() {
  HetiSocketBuilder builder = new HetiSocketBuilderChrome();
  HetiHttpServerPlus server = new HetiHttpServerPlus(builder);
  server.basePort = 8080;
  server.numOfRetry = 0;

  server.startServer().then((HetiHttpStartServerResult result) {
    ;
  });

  server.onResponse.listen((HetiHttpServerPlusResponseItem item) {
    ArrayBuilder builder = new ArrayBuilder.fromList(convert.UTF8.encode("redirect"), true);
    HetimaFile file = new HetimaBuilderToFile(builder);
    server.response(item.req, file);
  });

}
