library hetimanet.upnp.searcher;

import 'dart:convert' as convert;
import 'dart:async' as async;
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
  async.StreamController<UpnpDeviceInfo> _streamer = new async.StreamController.broadcast();
  HetiSocketBuilder _socketBuilder = null;
  bool _nowSearching = false;

  UpnpDeviceSearcher._fromSocketBuilder(HetiSocketBuilder builder) {
    _socketBuilder = builder;
  }

  async.Future<int> _initialize() {
    _socket = _socketBuilder.createUdpClient();
    _socket.onReceive().listen((HetiReceiveUdpInfo info) {
//      print("" + convert.UTF8.decode(info.data));
      extractDeviceInfoFromUdpResponse(info.data);
    });
    return _socket.bind("0.0.0.0", 0, multicast:true);
  }

  bool get nowSearching => _nowSearching;

  async.Future<int> close() {
    return _socket.close();
  }

  /**
   * create UPnPDeviceSearcher Object.
   */
  static async.Future<UpnpDeviceSearcher> createInstance(HetiSocketBuilder builder) {
    async.Completer<UpnpDeviceSearcher> completer = new async.Completer();
    UpnpDeviceSearcher returnValue = new UpnpDeviceSearcher._fromSocketBuilder(builder);
    returnValue._initialize().then((int v) {
      if (v >= 0) {
        completer.complete(returnValue);
      } else {
        completer.completeError(new UpnpDeviceSearcherException("unexpected(${v})", UpnpDeviceSearcherException.UNEXPECTED));
      }
    }).catchError((e) {
      completer.completeError(new UpnpDeviceSearcherException("unexpected(${e})", UpnpDeviceSearcherException.UNEXPECTED));
    });
    return completer.future;
  }

  async.Stream<UpnpDeviceInfo> onReceive() {
    return _streamer.stream;
  }

  async.Future<dynamic> searchWanPPPDevice([int timeoutSec = 3]) {
    async.Completer completer = new async.Completer();

    if (_nowSearching == true) {
      completer.completeError(new UpnpDeviceSearcherException("already run", UpnpDeviceSearcherException.ALREADY_RUN));
      return completer.future;
    }

    deviceInfoList.clear();

    _socket.send(convert.UTF8.encode(SSDP_M_SEARCH_WANPPPConnectionV1.replaceAll("MX: 3", "MX: ${timeoutSec}")), SSDP_ADDRESS, SSDP_PORT).then((HetiUdpSendInfo iii) {
      return _socket.send(convert.UTF8.encode(SSDP_M_SEARCH_WANIPConnectionV1.replaceAll("MX: 3", "MX: ${timeoutSec}")), SSDP_ADDRESS, SSDP_PORT);
    }).then((HetiUdpSendInfo iii) {
      return _socket.send(convert.UTF8.encode(SSDP_M_SEARCH_WANIPConnectionV2.replaceAll("MX: 3", "MX: ${timeoutSec}")), SSDP_ADDRESS, SSDP_PORT);
    }).catchError((e) {
      _nowSearching = false;
      completer.completeError(new UpnpDeviceSearcherException("failed search", UpnpDeviceSearcherException.FAILED_SEARCH));
    });

    new async.Future.delayed(new Duration(seconds: (timeoutSec + 1)), () {
      _nowSearching = false;
      completer.complete({});
    });

    _nowSearching = true;
    return completer.future;
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
