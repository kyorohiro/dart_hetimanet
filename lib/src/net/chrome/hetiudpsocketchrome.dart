part of hetimanet.chrome;

class HetiUdpSocketChrome extends HetiUdpSocket {
  
  chrome.CreateInfo _info = null;
  async.StreamController<HetiReceiveUdpInfo> receiveStream = new async.StreamController();
  HetiUdpSocketChrome.empty() {
  }

  async.Future<int> bind(String address, int port, {bool multicast:false}) {
    //chrome.sockets.udp.onReceive.listen(onReceiveInternal);
    async.Completer<int> completer = new async.Completer();
    chrome.SocketProperties properties = new chrome.SocketProperties();
    chrome.sockets.udp.create(properties).then((chrome.CreateInfo info) {
      _info = info;
      HetiChromeSocketManager.getInstance().addUdp(info.socketId, this);
      return chrome.sockets.udp.setMulticastLoopbackMode(_info.socketId, multicast);
    }).then((v) {
      return chrome.sockets.udp.bind(_info.socketId, address, port);
    }).then((int v) {
      completer.complete(v);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  void onReceiveInternal(chrome.ReceiveInfo info){
    if(_info.socketId != info.socketId) {
      return;
    }
    js.JsObject s= info.toJs();
    String remoteAddress = s["remoteAddress"];
    int remotePort = s["remotePort"];
    print("-------debug test onReceiveInternal");
    receiveStream.add(new HetiReceiveUdpInfo(info.data.getBytes(), remoteAddress, remotePort));
  }

  async.Future close() {
    HetiChromeSocketManager.getInstance().removeUdp(_info.socketId);
    return chrome.sockets.udp.close(_info.socketId);
  }

  async.Stream<HetiReceiveUdpInfo> onReceive() {
   return receiveStream.stream;
  }

  async.Future<HetiUdpSendInfo> send(List<int> buffer, String address, int port) {
    async.Completer<HetiUdpSendInfo> completer = new async.Completer();
    print("-------debug test send");
    chrome.sockets.udp.send(_info.socketId, new chrome.ArrayBuffer.fromBytes(buffer), address, port).then((chrome.SendInfo info) {
      completer.complete(new HetiUdpSendInfo(info.resultCode));      
    });
    return completer.future;
  }
}
