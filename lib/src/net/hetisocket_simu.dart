library hetimanet.simu;

import 'dart:async';
import 'hetisocket.dart';

class HetiSocketBuilderSimu extends HetimaSocketBuilder {
  HetimaSocket createClient({int mode:HetimaSocketBuilder.BUFFER_NOTIFY}) {
    return null;
  }
  HetimaUdpSocket createUdpClient() {
    return new HetiUdpSocketSimu();
  }
  Future<HetimaServerSocket> startServer(String address, int port, {int mode:HetimaSocketBuilder.BUFFER_NOTIFY}) {
    return null;
  }
  Future<List<HetimaNetworkInterface>> getNetworkInterfaces() {
    return null;
  }
}

class HetiUdpSocketSimuMane {
  HetiUdpSocketSimuMane._em();
  static HetiUdpSocketSimuMane _mane = new HetiUdpSocketSimuMane._em();
  static HetiUdpSocketSimuMane get instance => _mane;

  Map<String, HetiUdpSocketSimu> nodes = {};
}

class HetiUdpSocketSimu extends HetimaUdpSocket {
  String _ip = "";
  int _port;

  String get ip => _ip;
  int get port => _port;

  Future<HetimaBindResult> bind(String ip, int port,{bool multicast:false}) {
    this._ip = ip;
    this._port = port;
    return new Future(() {
      if (HetiUdpSocketSimuMane.instance.nodes.containsKey("${ip}:${port}")) {
        throw {"": "already start"};
      }
      HetiUdpSocketSimuMane.instance.nodes["${ip}:${port}"] = this;
    });
  }

  Future<dynamic> close() {
    return new Future(() {
      HetiUdpSocketSimuMane.instance.nodes["${ip}:${port}"] = this;
    });
  }

  Future<HetimaUdpSendInfo> send(List<int> buffer, String ip, int port) {
    return new Future(() {
      if (!HetiUdpSocketSimuMane.instance.nodes.containsKey("${ip}:${port}")) {
        throw {"": "not found"};
      }
      return HetiUdpSocketSimuMane.instance.nodes["${ip}:${port}"].receive(buffer, _ip, _port);
    });
  }

  StreamController _receiveMessage = new StreamController.broadcast();
  Stream<HetimaReceiveUdpInfo> get onReceive => _receiveMessage.stream;

  Future receive(List<int> bytes, String ip, int port) {
    return new Future(() {
      _receiveMessage.add(new HetimaReceiveUdpInfo(bytes, ip, port));
    });
  }
}
