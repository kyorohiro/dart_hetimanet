part of hetimanet.dartio;

class HetiSocketBuilderChrome extends HetiSocketBuilder {
  HetiSocket createClient() {
    return new HetiSocketDartIo();
  }

  async.Future<HetiServerSocket> startServer(String address, int port) {}

  HetiUdpSocket createUdpClient() {
    
  }

  async.Future<List<HetiNetworkInterface>> getNetworkInterfaces() async {
    List<NetworkInterface> interfaces = await NetworkInterface.list();
    List<HetiNetworkInterface> ret = [];
    for(NetworkInterface i in interfaces) {
      for(InternetAddress a in i.addresses) {
        int prefixLength = 24;
        if(a.rawAddress.length > 4) {
          prefixLength = 64;
        }
        ret.add(new HetiNetworkInterface()..address=a.address..name=i.name..prefixLength=prefixLength);
      }
    }
    return ret;
  }
}

class HetiSocketDartIo extends HetiSocket {
  Socket _socket = null;

  HetiSocketDartIo() {}

  bool _nowConnecting = false;
  async.StreamController<HetiCloseInfo> _closeStream = new async.StreamController.broadcast();
  async.StreamController<HetiReceiveInfo> _receiveStream = new async.StreamController.broadcast();
  @override
  async.Future<HetiSocket> connect(String peerAddress, int peerPort) async {
    if (_nowConnecting == true || _socket != null) {
      throw "connecting now";
    }
    _nowConnecting = true;
    try {
      _socket = await Socket.connect(peerAddress, peerPort);
      _socket.listen((List<int> data) {
        buffer.appendIntList(data);
      }, onDone: () {
        print('Done');
        _socket.close();
        _closeStream.add(new HetiCloseInfo());
      }, onError: (e) {
        print('Got error $e');
        _socket.close();
        _closeStream.add(new HetiCloseInfo());
      });
      return this;
    } finally {
      _nowConnecting = false;
    }
  }

  @override
  async.Future<HetiSocketInfo> getSocketInfo() async {
    HetiSocketInfo info = new HetiSocketInfo();
    info.localAddress = _socket.address.address;
    info.localPort = _socket.port;
    info.peerAddress = _socket.remoteAddress.address;
    info.peerPort = _socket.remotePort;
    return info;
  }

  void close() {
    if (isClosed == false) {
      _socket.close();
    }
    super.close();
  }

  @override
  async.Stream<HetiCloseInfo> onClose() {
    return _closeStream.stream;
  }

  @override
  async.Stream<HetiReceiveInfo> onReceive() {
    return _receiveStream.stream;
  }

  @override
  async.Future<HetiSendInfo> send(List<int> data) async {
    await _socket.add(data);
    return new HetiSendInfo(0);
  }
}
