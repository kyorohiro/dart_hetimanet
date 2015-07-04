part of hetimanet.chrome;

class HetiServerSocketChrome extends HetiServerSocket {
  async.StreamController<HetiSocket> _controller = new async.StreamController();
  chrome.CreateInfo _mInfo = null;

  HetiServerSocketChrome._internal(chrome.CreateInfo info) {
    _mInfo = info;
  }

  async.Stream<HetiSocket> onAccept() => _controller.stream;

  void onAcceptInternal(chrome.AcceptInfo info) {
    _controller.add(new HetiSocketChrome(info.clientSocketId));
  }

  void close() {
    chrome.sockets.tcpServer.close(_mInfo.socketId);
    HetiChromeSocketManager.getInstance().removeServer(_mInfo);
  }

  static async.Future<HetiServerSocket> startServer(String address, int port) {
    async.Completer<HetiServerSocket> completer = new async.Completer();

    chrome.sockets.tcpServer.create(new chrome.SocketProperties()).then((chrome.CreateInfo info) {
      HetiChromeSocketManager.getInstance();
      return chrome.sockets.tcpServer.listen(info.socketId, address, port).then((int backlog) {
        HetiServerSocketChrome server = new HetiServerSocketChrome._internal(info);
        HetiChromeSocketManager.getInstance().addServer(info, server);
        completer.complete(server);
      });
    }).catchError((e) {
      completer.completeError(new HetiServerSocketError()..id=HetiServerSocketError.ID_START);
    });
    return completer.future;
  }
}

