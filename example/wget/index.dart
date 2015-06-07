import 'package:hetimacore/hetimacore.dart';
import 'package:hetimanet/hetimanet.dart';
import 'package:hetimanet/hetimanet_chrome.dart';
import 'package:hetimacore/hetimacore_cl.dart';
import 'dart:html' as html;

//
// HetimaFileBuilder
//

void main() {
  html.TextAreaElement addr = html.querySelector('#wgetaddr');
  html.ButtonElement btn = html.querySelector('#wgetbtn');

  btn.onClick.listen((html.MouseEvent e) {
    print(addr.value);
    List<String> addrs = addr.value.split(new RegExp(r"\r\n|\n"));
    startGet(toHttpUrl(addrs));
  });
}

List<HttpUrl> toHttpUrl(List<String> addrs) {
  List<HttpUrl> ret = [];
  for (String addr in addrs) {
    HttpUrl url = HttpUrlDecoder.decodeUrl(addr);
    if(url != null) {
     ret.add(HttpUrlDecoder.decodeUrl(addr));
    }
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
    print("test host:${addr.host} path:${addr.path} port:${addr.port}");

    HetiHttpClientHelper client = new HetiHttpClientHelper(addr.host, addr.port, builder, new HetimaDataFSBuilder());
    client.get(addr.path).then((HetimaData f) {
      a();
    }).catchError((e){a();});
  }
  a();
}
