
import 'package:unittest/unittest.dart' as unit;
import 'package:hetimanet/hetimanet.dart' as hetima;
import 'package:hetimanet/hetimanet_chrome.dart' as hetima_cl;
//import '../lib/hetimanet_chrome.dart' as hetima_cl;
import 'dart:typed_data' as type;
import 'dart:convert' as convert;
import 'dart:html' as html;
import 'dart:async' as async;

//void main() {
//  print("--#--");
//
//  hetima_cl.HetiSocketBuilderChrome builder = new hetima_cl.HetiSocketBuilderChrome();
//  builder.startServer("0.0.0.0", 8089).then((hetima.HetiServerSocket socket) {
//    print("--#--");
//  });
//}

///*
void main() {
  print("--##-");
  hetima_cl.HetiSocketBuilderChrome builder = new hetima_cl.HetiSocketBuilderChrome();
  hetima.HetiHttpClient client = new hetima.HetiHttpClient(builder);
  //  client.connect("www.yahoo.co.jp", 80).then((int v){//"157.7.205.138"
  client.connect("www.google.com", 80).then((hetima.HetiHttpClientConnectResult v) {//"157.7.205.138"
    //  client.connect("157.7.205.138", 80).then((int v){//
    Map<String, String> t = {};
    t["Connection"] = "keep-alive";
    client.get("/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=android", t).then((hetima.HetiHttpClientResponse res) {
      for (hetima.HetiHttpResponseHeaderField f in res.message.headerField) {
        print(f.fieldName + ":" + f.fieldValue);
      }
      res.body.getByteFuture(0, res.message.index).then((List<int> v) {
        print("\r\n####header##\r\n" + convert.UTF8.decode(v) + "\r\n####\r\n");
        int len = res.getContentLength();
        print("--##AA00-");
        if (len != -1) {
          print("--##AA01-");
          res.body.getByteFuture(0, len).then((List<int> v) {
            print("--##AA01 AA-");
          });
        } else {
          print("--##AA02-");
          res.body.onFin().then((e) {
            res.body.getLength().then((int size) {
              client.close();
              print("--##AA02 BB-" + size.toString());
              res.body.getByteFuture(0, size).then((List<int> v) {
                print("--##AA03 BB-" + convert.UTF8.decode(v));
              });
            });
          });
        }
      });
    });
  });

}
