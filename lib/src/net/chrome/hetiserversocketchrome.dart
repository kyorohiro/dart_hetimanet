part of hetimanet.chrome;

class HetimaServerSocketChrome extends HetimaServerSocket {
  StreamController<HetimaSocket> _controller = new StreamController();
  chrome.CreateInfo _mInfo = null;

  HetimaServerSocketChrome._internal(chrome.CreateInfo info) {
    _mInfo = info;
  }

  Stream<HetimaSocket> onAccept() => _controller.stream;

  void onAcceptInternal(chrome.AcceptInfo info) {
    _controller.add(new HetimaSocketChrome(info.clientSocketId));
  }

  void close() {
    chrome.sockets.tcpServer.close(_mInfo.socketId);
    HetimaChromeSocketManager.getInstance().removeServer(_mInfo);
  }

  static Future<HetimaServerSocket> startServer(String address, int port) {
    Completer<HetimaServerSocket> completer = new Completer();

    chrome.sockets.tcpServer.create(new chrome.SocketProperties()).then((chrome.CreateInfo info) {
      HetimaChromeSocketManager.getInstance();
      return chrome.sockets.tcpServer.listen(info.socketId, address, port).then((int backlog) {
        HetimaServerSocketChrome server = new HetimaServerSocketChrome._internal(info);
        HetimaChromeSocketManager.getInstance().addServer(info, server);
        completer.complete(server);
      });
    }).catchError((e) {
      completer.completeError(new HetimaServerSocketError()..id=HetimaServerSocketError.ID_START);
    });
    return completer.future;
  }
}

