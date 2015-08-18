library hetimanet.base;
import 'dart:async' as async;
import 'package:hetimacore/hetimacore.dart' as heti;

abstract class HetiSocketBuilder {
  HetiSocket createClient();
  HetiUdpSocket createUdpClient();
  async.Future<HetiServerSocket> startServer(String address, int port) ;
  async.Future<List<HetiNetworkInterface>> getNetworkInterfaces(); 
}

abstract class HetiServerSocket {
  async.Stream<HetiSocket> onAccept();
  void close();
}

class HetiServerSocketError {
  static const ID_NONE = 0;
  static const ID_START = 1;
  static const REASON_NONE = 0;
  int id = 0;
  int reason = 0;
}

abstract class HetiSocket {
  int lastUpdateTime = 0;
  heti.ArrayBuilder buffer = new heti.ArrayBuilder();
  async.Future<HetiSocket> connect(String peerAddress, int peerPort) ;
  async.Future<HetiSendInfo> send(List<int> data);
  async.Future<HetiSocketInfo> getSocketInfo();
  async.Stream<HetiReceiveInfo> onReceive;
  async.Stream<HetiCloseInfo> onClose;
  bool isClosed = false;
  void close() {
    buffer.immutable = true;
    isClosed = true;
  }

  void updateTime() {
    lastUpdateTime = (new DateTime.now()).millisecondsSinceEpoch;
  }
}

abstract class HetiUdpSocket {
  ///
  /// The result code returned from the underlying network call. A
  /// negative value indicates an error.
  ///
  async.Future<HetiBindResult> bind(String address, int port, {bool multicast:false});
  async.Future<HetiUdpSendInfo> send(List<int> buffer, String address, int port);
  async.Stream<HetiReceiveUdpInfo> onReceive;
  async.Future<dynamic> close();
}

class HetiBindResult {
  
}

class HetiNetworkInterface
{
  String address;
  int prefixLength;
  String name;
}

class HetiSocketInfo {
  String peerAddress = "";
  int peerPort = 0;
  String localAddress = "";
  int localPort = 0;
}

class HetiSendInfo {
  int resultCode = 0;
  HetiSendInfo(int _resultCode) {
    resultCode = _resultCode;
  }
}

class HetiReceiveInfo {
  List<int> data;
  HetiReceiveInfo(List<int> _data) {
    data = _data;
  }
}

class HetiCloseInfo {
  
}

//
// print("a:"+s["remoteAddress"]);
// print("p:"+s["remotePort"]
//
class HetiReceiveUdpInfo {
  List<int> data;
  String remoteAddress;
  int remotePort;
  HetiReceiveUdpInfo(List<int> adata, String aremoteAddress, int aport) {
    data = adata;
    remoteAddress = aremoteAddress;
    remotePort = aport;
  }
}

class HetiUdpSendInfo {
  int resultCode = 0;
  HetiUdpSendInfo(int _resultCode) {
    resultCode = _resultCode;
  }
}