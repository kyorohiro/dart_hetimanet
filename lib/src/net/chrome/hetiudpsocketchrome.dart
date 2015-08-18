part of hetimanet.chrome;

class HetiUdpSocketChrome extends HetiUdpSocket {
  chrome.CreateInfo _info = null;
  StreamController<HetiReceiveUdpInfo> _receiveStream = new StreamController();
  HetiUdpSocketChrome.empty() {}

  Future<HetiBindResult> bind(String address, int port, {bool multicast: false}) async {
    chrome.SocketProperties properties = new chrome.SocketProperties();
    chrome.CreateInfo info = _info = await chrome.sockets.udp.create(properties);

    HetiChromeSocketManager.getInstance().addUdp(info.socketId, this);
    await chrome.sockets.udp.setMulticastLoopbackMode(_info.socketId, multicast);
    int v = await chrome.sockets.udp.bind(_info.socketId, address, port);
    if (v < 0) {
      throw {"resultCode": v};
    }
    return new HetiBindResult();
  }

  void onReceiveInternal(chrome.ReceiveInfo info) {
    if (_info.socketId != info.socketId) {
      return;
    }
    js.JsObject s = info.toJs();
    String remoteAddress = s["remoteAddress"];
    int remotePort = s["remotePort"];
    _receiveStream.add(new HetiReceiveUdpInfo(info.data.getBytes(), remoteAddress, remotePort));
  }

  Future close() {
    HetiChromeSocketManager.getInstance().removeUdp(_info.socketId);
    return chrome.sockets.udp.close(_info.socketId);
  }

  Stream<HetiReceiveUdpInfo> get onReceive => _receiveStream.stream;

  Future<HetiUdpSendInfo> send(List<int> buffer, String address, int port) async {
    chrome.SendInfo info = await chrome.sockets.udp.send(_info.socketId, new chrome.ArrayBuffer.fromBytes(buffer), address, port);
    if (info.resultCode < 0) {
      throw {"resultCode": info.resultCode};
    }
    return new HetiUdpSendInfo(info.resultCode);
  }
}
