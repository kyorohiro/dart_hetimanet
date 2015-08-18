part of hetimanet.chrome;

class HetiSocketChrome extends HetiSocket {

  bool _isClose = false;
  int clientSocketId;
  StreamController<HetiReceiveInfo> _controllerReceive = new StreamController.broadcast();
  StreamController<HetiCloseInfo> _controllerClose= new StreamController.broadcast();
  HetiSocketChrome.empty() {}

  HetiSocketChrome(int _clientSocketId) {
    HetiChromeSocketManager.getInstance().addClient(_clientSocketId, this);
    chrome.sockets.tcp.setPaused(_clientSocketId, false);
    clientSocketId = _clientSocketId;
  }

  Stream<HetiReceiveInfo> get onReceive => _controllerReceive.stream;

  void onReceiveInternal(chrome.ReceiveInfo info) {
    updateTime();
    List<int> tmp = info.data.getBytes();
    buffer.appendIntList(tmp, 0, tmp.length);
    _controllerReceive.add(new HetiReceiveInfo(info.data.getBytes()));
  }

  Future<HetiSendInfo> send(List<int> data) {
    updateTime();
    Completer<HetiSendInfo> completer = new Completer();
    new Future.sync(() {
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

  Future<HetiSocketInfo> getSocketInfo() {
    Completer<HetiSocketInfo> completer = new Completer();
    
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
  Future<HetiSocket> connect(String peerAddress, int peerPort) {
    Completer<HetiSocket> completer = new Completer();
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

  Stream<HetiCloseInfo> get onClose => _controllerClose.stream;
}
