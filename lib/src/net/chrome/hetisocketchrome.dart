part of hetimanet.chrome;

class HetimaSocketChrome extends HetimaSocket {

  bool _isClose = false;
  int clientSocketId;
  StreamController<HetimaReceiveInfo> _controllerReceive = new StreamController.broadcast();
  StreamController<HetimaCloseInfo> _controllerClose= new StreamController.broadcast();
  HetimaSocketChrome.empty() {}

  HetimaSocketChrome(int _clientSocketId) {
    HetimaChromeSocketManager.getInstance().addClient(_clientSocketId, this);
    chrome.sockets.tcp.setPaused(_clientSocketId, false);
    clientSocketId = _clientSocketId;
  }

  Stream<HetimaReceiveInfo> get onReceive => _controllerReceive.stream;

  void onReceiveInternal(chrome.ReceiveInfo info) {
    updateTime();
    List<int> tmp = info.data.getBytes();
    buffer.appendIntList(tmp, 0, tmp.length);
    _controllerReceive.add(new HetimaReceiveInfo(info.data.getBytes()));
  }

  Future<HetimaSendInfo> send(List<int> data) {
    updateTime();
    Completer<HetimaSendInfo> completer = new Completer();
    new Future.sync(() {
      chrome.ArrayBuffer buffer = new chrome.ArrayBuffer.fromBytes(data);
      return chrome.sockets.tcp.send(clientSocketId, buffer).then((chrome.SendInfo info) {
        updateTime();
        completer.complete(new HetimaSendInfo(info.resultCode));
      });
    }).catchError((e) {
      completer.complete(new HetimaSendInfo(-1999));
    });
    return completer.future;
  }

  Future<HetimaSocketInfo> getSocketInfo() {
    Completer<HetimaSocketInfo> completer = new Completer();
    
    chrome.sockets.tcp.getInfo(clientSocketId).then((chrome.SocketInfo info) {
      HetimaSocketInfo ret = new HetimaSocketInfo()
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
  Future<HetimaSocket> connect(String peerAddress, int peerPort) {
    Completer<HetimaSocket> completer = new Completer();
    chrome.SocketProperties properties = new chrome.SocketProperties();
    chrome.sockets.tcp.create(properties).then((chrome.CreateInfo info) {
      return chrome.sockets.tcp.connect(info.socketId, peerAddress, peerPort).then((int e) {
          chrome.sockets.tcp.setPaused(info.socketId, false);
          clientSocketId = info.socketId;
          HetimaChromeSocketManager.getInstance().addClient(info.socketId, this);
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
    _controllerClose.add(new HetimaCloseInfo());
    HetimaChromeSocketManager.getInstance().removeClient(clientSocketId);
    _isClose = true;
  }

  Stream<HetimaCloseInfo> get onClose => _controllerClose.stream;
}
