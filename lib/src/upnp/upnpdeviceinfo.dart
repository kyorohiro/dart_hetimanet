library hetimanet.upnp.deviceinfo;

import 'dart:convert' as convert;
import 'dart:async';
import '../net/hetisocket.dart';
import '../http/hetihttp.dart';
import '../util/hetiutil.dart';
import 'package:xml/xml.dart' as xml;
export 'upnpdeviceinfo.dart';
export 'upnpdevicesearcher.dart';
export 'upnppppdevice.dart';

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
    for (String key in _headerMap.keys) {
      buffer.write("__" + key + ":" + _headerMap[key] + ";\r\n");
    }
    buffer.write("#service;\r\n");
    for (UpnpDeviceServiceInfo service in _serviceList) {
      buffer.write("__" + service.serviceId + ";\r\n");
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
    try {
      xml.XmlDocument document = xml.parse(_serviceXml);

      //print("########_serviceXml===${_serviceXml}########");
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
    } catch (e) {
      print("xml parse error: ${_serviceXml}");
    }
  }

  String _extractFirstValue(xml.XmlElement element, String key, String defaultValue) {
    Iterable<xml.XmlElement> elements = element.findAllElements(key);
    if (elements == null || elements.length == 0 || null == elements.first || elements.first.text == null) {
      return defaultValue;
    }

    return elements.first.text;
  }
  String _serviceXml = "";

  Future<int> extractService() async {
    _serviceXml = await requestServiceList();
    _updateServiceXml();
    return 0;
  }

  Future<String> requestServiceList() async {
    String location = getValue(UpnpDeviceInfo.KEY_LOCATION, "");
    if (location == "" || location == null) {
      throw {"message": "invalid location"};
    }

    HetiHttpClient client = new HetiHttpClient(socketBuilder, verbose: true);
    HttpUrl url = HttpUrlDecoder.decodeUrl(location);
    await client.connect(url.host, url.port);
    HetiHttpClientResponse res = await client.get(url.path);
    await new Future.delayed(new Duration(seconds: 1));
    await res.body.rawcompleterFin.future;
    int length = await res.body.getLength();
    List<int> v = await res.body.getByteFuture(0, length);
    return convert.UTF8.decode(v);
  }
}

class UpnpDeviceServiceInfo {
  String serviceType = "";
  String serviceId = "";
  String controlURL = "";
  String eventSubURL = "";
  String SCPDURL = "";
}
