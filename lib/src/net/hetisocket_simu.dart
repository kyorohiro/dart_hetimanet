library hetimanet.simu;

import 'dart:async';
import 'hetisocket.dart';

class HetiSocketBuilderSimu {
  HetiSocket createClient() {
    return null;
  }
  HetiUdpSocket createUdpClient() {
    return new HetiUdpSocketSimu();
  }
  Future<HetiServerSocket> startServer(String address, int port) {
    return null;
  }
  Future<List<HetiNetworkInterface>> getNetworkInterfaces() {
    return null;
  }
}

class HetiUdpSocketSimuMane {
  HetiUdpSocketSimuMane._em();
  static HetiUdpSocketSimuMane _mane = new HetiUdpSocketSimuMane._em();
  static HetiUdpSocketSimuMane get instance => _mane;

  Map<String, HetiUdpSocketSimu> nodes = {};
}

class HetiUdpSocketSimu extends HetiUdpSocket {
  String _ip = "";
  int _port;

  String get ip => _ip;
  int get port => _port;

  Future<int> bind(String ip, int port) {
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

  Future<HetiUdpSendInfo> send(List<int> buffer, String ip, int port) {
    return new Future(() {
      if (!HetiUdpSocketSimuMane.instance.nodes.containsKey("${ip}:${port}")) {
        throw {"": "not found"};
      }
      return HetiUdpSocketSimuMane.instance.nodes["${ip}:${port}"].receive(buffer, _ip, _port);
    });
  }

  StreamController _receiveMessage = new StreamController.broadcast();
  Stream<HetiReceiveUdpInfo> onReceive() {
    return _receiveMessage.stream;
  }

  Future receive(List<int> bytes, String ip, int port) {
    return new Future(() {
      _receiveMessage.add(new HetiReceiveUdpInfo(bytes, ip, port));
    });
  }
}
