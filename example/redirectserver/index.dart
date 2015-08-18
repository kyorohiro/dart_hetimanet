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
  HetimaSocketBuilder builder = new HetimaSocketBuilderChrome();
  HetiHttpServerHelper server = new HetiHttpServerHelper(builder);
  server.basePort = 8081;
  server.numOfRetry = 0;

  server.startServer().then((HetiHttpStartServerResult result) {
    print("passed start ${server.localIP}${server.localPort}");
  }).catchError((e) {
    print("failed start");
  });

  server.onResponse.listen((HetiHttpServerPlusResponseItem item) {
    print("==${item.path}==${item.option}");
    item.socket.getSocketInfo().then((HetimaSocketInfo info) {
      print("--");
      print("peer  : ${info.peerAddress} ${info.peerPort}");
      print("local : ${info.localAddress} ${info.localPort}");
    });
    if(item.path.compareTo("/test/index.html")!=0) {
      ArrayBuilder builder = new ArrayBuilder.fromList(convert.UTF8.encode("redirect"), true);
      HetimaData file = new HetimaBuilderToFile(builder);
      Map<String, String> headerList = {"Location": "http://127.0.0.1:8081/test/index.html"};    
      server.response(item.req, file, headerList: headerList, statusCode:301);
    } else {
      ArrayBuilder builder = new ArrayBuilder.fromList(convert.UTF8.encode("hello"), true);
      HetimaData file = new HetimaBuilderToFile(builder);
      server.response(item.req, file,contentType:"text/text");    
    }
  });
}
