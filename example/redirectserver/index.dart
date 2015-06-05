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
  HetiHttpServerHelper server = new HetiHttpServerHelper(builder);
  server.basePort = 8080;
  server.numOfRetry = 0;

  server.startServer().then((HetiHttpStartServerResult result) {
    print("passed start");
  }).catchError((e) {
    print("failed start");
  });

  server.onResponse.listen((HetiHttpServerPlusResponseItem item) {
    print("==${item.path}==${item.option}");
    if(item.path.compareTo("/test/index.htm")==0) {
      ArrayBuilder builder = new ArrayBuilder.fromList(convert.UTF8.encode("redirect"), true);
      HetimaFile file = new HetimaBuilderToFile(builder);
      Map<String, String> headerList = {"Location": "http://127.0.0.1:8080/test/index.html"};    
      server.response(item.req, file, headerList: headerList, statusCode:301);
    } else {
      ArrayBuilder builder = new ArrayBuilder.fromList(convert.UTF8.encode("hello"), true);
      HetimaFile file = new HetimaBuilderToFile(builder);
      server.response(item.req, file,contentType:"text/text");    
    }
  });
}
