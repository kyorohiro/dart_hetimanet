part of hetimanet.chrome;

class HetiSocketChrome extends HetiSocket {

  bool _isClose = false;
  int clientSocketId;
  async.StreamController<HetiReceiveInfo> _controllerReceive = new async.StreamController.broadcast();
  async.StreamController<HetiCloseInfo> _controllerClose= new async.StreamController.broadcast();
  HetiSocketChrome.empty() {}

  HetiSocketChrome(int _clientSocketId) {
    HetiChromeSocketManager.getInstance().addClient(_clientSocketId, this);
    chrome.sockets.tcp.setPaused(_clientSocketId, false);
    clientSocketId = _clientSocketId;
  }

  async.Stream<HetiReceiveInfo> onReceive() => _controllerReceive.stream;

  void onReceiveInternal(chrome.ReceiveInfo info) {
    updateTime();
    List<int> tmp = info.data.getBytes();
    buffer.appendIntList(tmp, 0, tmp.length);
    _controllerReceive.add(new HetiReceiveInfo(info.data.getBytes()));
  }

  async.Future<HetiSendInfo> send(List<int> data) {
    updateTime();
    async.Completer<HetiSendInfo> completer = new async.Completer();
    new async.Future.sync(() {
      chrome.ArrayBuffer buffer = new chrome.ArrayBuffer.fromBytes(data);
      return chrome.sockets.tcp.send(clientSocketId, buffer).then((chrome.SendInfo info) {
        updateTime();
        completer.complete(new HetiSendInfo(info.resultCode));
      });
    }).catchError((e) {
      completer.complete(new HetiSendInfo(-1999));
    });
    return completer.future;
  }

  async.Future<HetiSocketInfo> getSocketInfo() {
    async.Completer<HetiSocketInfo> completer = new async.Completer();
    
    chrome.sockets.tcp.getInfo(clientSocketId).then((chrome.SocketInfo info) {
      HetiSocketInfo ret = new HetiSocketInfo()
      ..localAddress = info.localAddress
      ..localPort = info.localPort
      ..peerAddress = info.peerAddress
      ..peerPort = info.peerPort;
      completer.complete(ret);
    }).catchError((e){
      completer.completeError(e);
    });
     return completer.future;
  }
  async.Future<HetiSocket> connect(String peerAddress, int peerPort) {
    async.Completer<HetiSocket> completer = new async.Completer();
    chrome.SocketProperties properties = new chrome.SocketProperties();
    chrome.sockets.tcp.create(properties).then((chrome.CreateInfo info) {
      return chrome.sockets.tcp.connect(info.socketId, peerAddress, peerPort).then((int e) {
          chrome.sockets.tcp.setPaused(info.socketId, false);
          clientSocketId = info.socketId;
          HetiChromeSocketManager.getInstance().addClient(info.socketId, this);
          completer.complete(this);
      });
    }).catchError(completer.completeError);
    return completer.future;
  }

  void close() {
    super.close();
    if (_isClose) {
      return;
    }
    updateTime();
    chrome.sockets.tcp.close(clientSocketId).then((d) {
      print("##closed()");
    });
    _controllerClose.add(new HetiCloseInfo());
    HetiChromeSocketManager.getInstance().removeClient(clientSocketId);
    _isClose = true;
  }

  async.Stream<HetiCloseInfo> onClose() {
    return _controllerClose.stream;
  }
}
