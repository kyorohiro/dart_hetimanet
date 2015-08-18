library hetimanet.upnp.searcher;

import 'dart:convert' as convert;
import 'dart:async';
import 'package:hetimacore/hetimacore.dart';
import '../net/hetisocket.dart';
import '../http/hetihttp.dart';

import 'upnpdeviceinfo.dart';

class UpnpDeviceSearcher {
  static const String SSDP_ADDRESS = "239.255.255.250";
  static const int SSDP_PORT = 1900;
  static const String SSDP_M_SEARCH =
      """M-SEARCH * HTTP/1.1\r\n""" + """MX: 3\r\n""" + """HOST: 239.255.255.250:1900\r\n""" + """MAN: "ssdp:discover"\r\n""" + """ST: upnp:rootdevice\r\n""" + """\r\n""";
  static const String SSDP_M_SEARCH_WANPPPConnectionV1 = """M-SEARCH * HTTP/1.1\r\n""" +
      """MX: 3\r\n""" +
      """HOST: 239.255.255.250:1900\r\n""" +
      """MAN: "ssdp:discover"\r\n""" +
      """ST: urn:schemas-upnp-org:service:WANPPPConnection:1\r\n""" +
      """\r\n""";
  static const String SSDP_M_SEARCH_WANIPConnectionV1 = """M-SEARCH * HTTP/1.1\r\n""" +
      """MX: 3\r\n""" +
      """HOST: 239.255.255.250:1900\r\n""" +
      """MAN: "ssdp:discover"\r\n""" +
      """ST: urn:schemas-upnp-org:service:WANIPConnection:1\r\n""" +
      """\r\n""";
  static const String SSDP_M_SEARCH_WANIPConnectionV2 = """M-SEARCH * HTTP/1.1\r\n""" +
      """MX: 3\r\n""" +
      """HOST: 239.255.255.250:1900\r\n""" +
      """MAN: "ssdp:discover"\r\n""" +
      """ST: urn:schemas-upnp-org:service:WANIPConnection:2\r\n""" +
      """\r\n""";

  List<UpnpDeviceInfo> deviceInfoList = new List();
  HetiUdpSocket _socket = null;
  StreamController<UpnpDeviceInfo> _streamer = new StreamController.broadcast();
  HetiSocketBuilder _socketBuilder = null;
  bool _nowSearching = false;

  bool _verbose = false;
  UpnpDeviceSearcher._fromSocketBuilder(HetiSocketBuilder builder, {bool verbose: false}) {
    _socketBuilder = builder;
    _verbose = verbose;
  }

  Future<HetiBindResult> _initialize(String address) {
    _socket = _socketBuilder.createUdpClient();
    _socket.onReceive.listen((HetiReceiveUdpInfo info) {
      if (_verbose == true) {
        print("<udp f=onReceive>" + convert.UTF8.decode(info.data) + "</udp>");
      }
      extractDeviceInfoFromUdpResponse(info.data);
    });
    return _socket.bind(address, 0, multicast: true);
  }

  bool get nowSearching => _nowSearching;

  Future<int> close() => _socket.close();

  /**
   * create UPnPDeviceSearcher Object.
   */
  static Future<UpnpDeviceSearcher> createInstance(HetiSocketBuilder builder, {String ip: "0.0.0.0", bool verbose: false}) async {
    UpnpDeviceSearcher returnValue = new UpnpDeviceSearcher._fromSocketBuilder(builder, verbose: verbose);
    try {
      await returnValue._initialize(ip);
      return returnValue;
    } catch (e) {
      throw new UpnpDeviceSearcherException("unexpected(${e})", UpnpDeviceSearcherException.UNEXPECTED);
    }
  }

  Stream<UpnpDeviceInfo> get onReceive => _streamer.stream;

  Future<dynamic> searchWanPPPDevice([int timeoutSec = 8]) async {
    if (_nowSearching == true) {
      throw new UpnpDeviceSearcherException("already run", UpnpDeviceSearcherException.ALREADY_RUN);
    }
    _nowSearching = true;
    deviceInfoList.clear();

    try {
      await _socket.send(convert.UTF8.encode(SSDP_M_SEARCH_WANPPPConnectionV1.replaceAll("MX: 3", "MX: ${timeoutSec~/2}")), SSDP_ADDRESS, SSDP_PORT);
      await _socket.send(convert.UTF8.encode(SSDP_M_SEARCH_WANIPConnectionV1.replaceAll("MX: 3", "MX: ${timeoutSec~/2}")), SSDP_ADDRESS, SSDP_PORT);
      await _socket.send(convert.UTF8.encode(SSDP_M_SEARCH_WANIPConnectionV2.replaceAll("MX: 3", "MX: ${timeoutSec~/2}")), SSDP_ADDRESS, SSDP_PORT);
    } catch (e) {
      _nowSearching = false;
      throw new UpnpDeviceSearcherException("failed search", UpnpDeviceSearcherException.FAILED_SEARCH);
    }

    return new Future.delayed(new Duration(seconds: (timeoutSec)), () {
      _nowSearching = false;
      return {};
    });
  }

  void extractDeviceInfoFromUdpResponse(List<int> buffer) {
    ArrayBuilder builder = new ArrayBuilder();
    EasyParser parser = new EasyParser(builder);
    builder.appendIntList(buffer, 0, buffer.length);
    HetiHttpResponse.decodeHttpMessage(parser).then((HetiHttpMessageWithoutBody message) {
      UpnpDeviceInfo info = new UpnpDeviceInfo(message.headerField, _socketBuilder);
      if (!deviceInfoList.contains(info)) {
        info.extractService().then((int v) {
          if (!deviceInfoList.contains(info)) {
            deviceInfoList.add(info);
            _streamer.add(info);
          }
        }).catchError((e) {});
      }
    });
  }
}

class UpnpDeviceSearcherException extends StateError {
  static const int ALREADY_RUN = 0;
  static const int UNEXPECTED = 1;
  static const int FAILED_SEARCH = 2;
  int id = 0;
  UpnpDeviceSearcherException(String mes, int id) : super(mes) {
    this.id = id;
  }

  String toString() {
    return message;
  }
}
