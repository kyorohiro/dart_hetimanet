library hetimanet.base;
import 'dart:async' as async;
import 'package:hetimacore/hetimacore.dart' as heti;

abstract class HetimaSocketBuilder {
  HetimaSocket createClient();
  HetimaUdpSocket createUdpClient();
  async.Future<HetimaServerSocket> startServer(String address, int port) ;
  async.Future<List<HetimaNetworkInterface>> getNetworkInterfaces(); 
}

abstract class HetimaServerSocket {
  async.Stream<HetimaSocket> onAccept();
  void close();
}

class HetimaServerSocketError {
  static const ID_NONE = 0;
  static const ID_START = 1;
  static const REASON_NONE = 0;
  int id = 0;
  int reason = 0;
}

abstract class HetimaSocket {
  int lastUpdateTime = 0;
  heti.ArrayBuilder buffer = new heti.ArrayBuilder();
  async.Future<HetimaSocket> connect(String peerAddress, int peerPort) ;
  async.Future<HetimaSendInfo> send(List<int> data);
  async.Future<HetimaSocketInfo> getSocketInfo();
  async.Stream<HetimaReceiveInfo> onReceive;
  async.Stream<HetimaCloseInfo> onClose;
  bool isClosed = false;
  void close() {
    buffer.immutable = true;
    isClosed = true;
  }

  void updateTime() {
    lastUpdateTime = (new DateTime.now()).millisecondsSinceEpoch;
  }
}

abstract class HetimaUdpSocket {
  ///
  /// The result code returned from the underlying network call. A
  /// negative value indicates an error.
  ///
  async.Future<HetimaBindResult> bind(String address, int port, {bool multicast:false});
  async.Future<HetimaUdpSendInfo> send(List<int> buffer, String address, int port);
  async.Stream<HetimaReceiveUdpInfo> onReceive;
  async.Future<dynamic> close();
}

class HetimaBindResult {
  
}

class HetimaNetworkInterface
{
  String address;
  int prefixLength;
  String name;
}

class HetimaSocketInfo {
  String peerAddress = "";
  int peerPort = 0;
  String localAddress = "";
  int localPort = 0;
}

class HetimaSendInfo {
  int resultCode = 0;
  HetimaSendInfo(int _resultCode) {
    resultCode = _resultCode;
  }
}

class HetimaReceiveInfo {
  List<int> data;
  HetimaReceiveInfo(List<int> _data) {
    data = _data;
  }
}

class HetimaCloseInfo {
  
}

//
// print("a:"+s["remoteAddress"]);
// print("p:"+s["remotePort"]
//
class HetimaReceiveUdpInfo {
  List<int> data;
  String remoteAddress;
  int remotePort;
  HetimaReceiveUdpInfo(List<int> adata, String aremoteAddress, int aport) {
    data = adata;
    remoteAddress = aremoteAddress;
    remotePort = aport;
  }
}

class HetimaUdpSendInfo {
  int resultCode = 0;
  HetimaUdpSendInfo(int _resultCode) {
    resultCode = _resultCode;
  }
}