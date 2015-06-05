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
  html.TextAreaElement addr = html.querySelector('#wgetaddr');
  html.ButtonElement btn = html.querySelector('#editor-now');

  btn.onClick.listen((html.MouseEvent e) {
    print(addr.value);
    List<String> addrs = addr.value.split(new RegExp(r"\r\n|\n"));
    startGet(toHttpUrl(addrs));
  });
}

List<HttpUrl> toHttpUrl(List<String> addrs) {
  List<HttpUrl> ret = [];
  for (String addr in addrs) {
    ret.add(HttpUrlDecoder.decodeUrl(addr));
  }
  return ret;
}

void startGet(List<HttpUrl> addrs) {
  HetiSocketBuilderChrome builder = new HetiSocketBuilderChrome();
  a() {
    if (addrs.length <= 0) {
      return;
    }
    HttpUrl addr = addrs.removeLast();
    HetiHttpClientHelper client = new HetiHttpClientHelper(addr.host, addr.port, builder);
    client.get(addr.path).then((HetimaFile f) {
      a();
    }).catchError((e){a();});
  }
  a();
}
