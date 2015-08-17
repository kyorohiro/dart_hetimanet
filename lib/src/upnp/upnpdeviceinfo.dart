library hetimanet.upnp.deviceinfo;

import 'dart:convert' as convert;
import 'dart:async' as async;
import '../net/hetisocket.dart';
import '../http/hetihttp.dart';
import '../util/hetiutil.dart';
import 'package:xml/xml.dart' as xml;
export 'upnpdeviceinfo.dart';
export 'upnpdevicesearcher.dart';
export  'upnppppdevice.dart';
export 'upnpportmapping.dart';

class UpnpDeviceInfo {
  static final String KEY_ST = "ST";
  static final String KEY_USN = "USN";
  static final String KEY_LOCATION = "Location";
  static final String KEY_OPT = "OPT";
  static final String KEY_01_NLS = "01-NLS";
  static final String KEY_CACHE_CONTROL = "Cache-Control";
  static final String KEY_SERVER = "Server";
  static final String KEY_EXT = "Ext";

  Map<String, String> _headerMap = {};
  List<UpnpDeviceServiceInfo> _serviceList = [];
  HetiSocketBuilder socketBuilder;

  UpnpDeviceInfo(List<HetiHttpResponseHeaderField> headerField, HetiSocketBuilder builder) {
    socketBuilder = builder;
    for (HetiHttpResponseHeaderField header in headerField) {
      if (header.fieldName != null) {
        _headerMap[header.fieldName] = header.fieldValue;
      }
    }
  }

  String get presentationURL {
    xml.XmlDocument document = xml.parse(_serviceXml);
    return _extractFirstValue(document.root, "presentationURL", "");
  }

  @override
  String toString() {
     StringBuffer buffer = new StringBuffer();
     buffer.write("#header;\r\n");
     for(String key in _headerMap.keys) {
       buffer.write("__"+key+":"+_headerMap[key]+";\r\n");
     }
     buffer.write("#service;\r\n");
     for(UpnpDeviceServiceInfo service in _serviceList) {
       buffer.write("__"+service.serviceId+";\r\n");       
     }
     return buffer.toString();
  }

  HetiSocketBuilder getSocketBuilder() {
    return socketBuilder;
  }

  String getValue(String key, String defaultValue) {
    if (key == null) {
      return defaultValue;
    }

    for (String k in _headerMap.keys) {
      if (k == null) {
        continue;
      }
      if (k.toLowerCase() == key.toLowerCase()) {
        return _headerMap[k];
      }
    }
    return defaultValue;
  }

  bool operator ==(Object other) {
    if (!(other is UpnpDeviceInfo)) {
      return false;
    }
    UpnpDeviceInfo otherAs = other as UpnpDeviceInfo;
    if (this._headerMap.keys.length != otherAs._headerMap.keys.length) {
      return false;
    }
    for (String k in this._headerMap.keys) {
      if (!otherAs._headerMap.containsKey(k)) {
        return false;
      }
      if (otherAs._headerMap[k] != this._headerMap[k]) {
        return false;
      }
    }
    return true;
  }


  List<UpnpDeviceServiceInfo> get serviceList => _serviceList;
  String URLBase = "";

  void _updateServiceXml() {
    _serviceList.clear();
    xml.XmlDocument document = xml.parse(_serviceXml);
    print("########_serviceXml===${_serviceXml}########");
    URLBase = _extractFirstValue(document.rootElement, "URLBase", "");
    Iterable<xml.XmlElement> elements = document.findAllElements("service");
    for (xml.XmlElement element in elements) {
      UpnpDeviceServiceInfo info = new UpnpDeviceServiceInfo();
      info.controlURL = _extractFirstValue(element, "controlURL", "");
      info.eventSubURL = _extractFirstValue(element, "eventSubURL", "");
      info.SCPDURL = _extractFirstValue(element, "SCPDURL", "");
      info.serviceType = _extractFirstValue(element, "serviceType", "");
      info.serviceId = _extractFirstValue(element, "serviceId", "");
      _serviceList.add(info);
    }
  }

  String _extractFirstValue(xml.XmlElement element, String key, String defaultValue) {
    Iterable<xml.XmlElement> elements = element.findAllElements(key);
    if(elements == null ||elements.length == 0 || null == elements.first || elements.first.text == null) {
      return defaultValue;
    } 
    
    return elements.first.text;
  }
  String _serviceXml = "";
  async.Future<int> extractService() {
    async.Completer completer = new async.Completer();
    print("----------------------------------------[A]");
    requestServiceList().then((String serviceXml) {
      print("----------------------------------------[B]");
      print("serviceXml=" + serviceXml);
      _serviceXml = serviceXml;
      _updateServiceXml();
      completer.complete(0);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<String> requestServiceList() {
    async.Completer<String> completer = new async.Completer();
    String location = getValue(UpnpDeviceInfo.KEY_LOCATION, "");
    if (location == "" || location == null) {
      completer.completeError({});
      return completer.future;
    }

    print("-----requestServiceList()");
    HetiHttpClient client = new HetiHttpClient(socketBuilder);
    HttpUrl url = HttpUrlDecoder.decodeUrl(location);
    client.connect(url.host, url.port).then((HetiHttpClientConnectResult d) {
      print("-----connected[1]");
      return client.get(url.path);
    }).then((HetiHttpClientResponse res) {
      print("-----get[2] ");
      //HetiHttpResponseHeaderField field = res.message.find(RfcTable.HEADER_FIELD_CONTENT_LENGTH);
      return new async.Future.delayed(new Duration(seconds:1)).then((_){
      //
      //
      print("-----get[2-0] ${res.body.immutable}");
      print("S1 ${res.body.rawcompleterFin.isCompleted}");
      //return res.body.onFin().then((b) {
      return res.body.rawcompleterFin.future.then((b){
        print("-----get[2-1]");
        return res.body.getLength().then((int length) {
          print("-----get[2-2]");
          return res.body.getByteFuture(0, length).then((List<int> v) {
            print("-----get[2-3]");
            completer.complete(convert.UTF8.decode(v));
          });
        });
      }).catchError((e){
        print("-----error[2-3]");
        throw e;
      });
      print("S2 ${res.body.rawcompleterFin.isCompleted}");
     // print("S2${res.body.completerFin.isCompleted}");
      //
      //
      });

    }).catchError((e) {
      print("-----error[3]");

      completer.completeError(e);
    });
    return completer.future;
  }

}


class UpnpDeviceServiceInfo 
{
  String serviceType = "";
  String serviceId = "";
  String controlURL = "";
  String eventSubURL = "";
  String SCPDURL = "";
}
