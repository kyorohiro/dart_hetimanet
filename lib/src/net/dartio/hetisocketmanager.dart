part of hetimanet.dartio;

class HetiSocketBuilderChrome extends HetiSocketBuilder {
  HetiSocket createClient() {
    return new HetiSocketDartIo();
  }

  async.Future<HetiServerSocket> startServer(String address, int port) async {
    return HetiServerSocketDartIo.startServer(address, port);
  }

  HetiUdpSocket createUdpClient() {
    return new HetiUdpSocketDartIo();
  }

  async.Future<List<HetiNetworkInterface>> getNetworkInterfaces() async {
    List<NetworkInterface> interfaces = await NetworkInterface.list(includeLoopback: true, includeLinkLocal: true);
    List<HetiNetworkInterface> ret = [];
    for (NetworkInterface i in interfaces) {
      for (InternetAddress a in i.addresses) {
        int prefixLength = 24;
        if (a.rawAddress.length > 4) {
          prefixLength = 64;
        }
        ret.add(new HetiNetworkInterface()
          ..address = a.address
          ..name = i.name
          ..prefixLength = prefixLength);
      }
    }
    return ret;
  }
}

class HetiServerSocketDartIo extends HetiServerSocket {
  ServerSocket _server = null;
  async.StreamController<HetiSocket> _acceptStream = new async.StreamController.broadcast();

  HetiServerSocketDartIo(ServerSocket server) {
    _server = server;
    _server.listen((Socket socket) {
      _acceptStream.add(new HetiSocketDartIo.fromSocket(socket));
    });
  }

  static async.Future<HetiServerSocket> startServer(String address, int port) async {
    ServerSocket server = await ServerSocket.bind(address, port);
    return new HetiServerSocketDartIo(server);
  }

  @override
  void close() {
    _server.close();
  }

  @override
  async.Stream<HetiSocket> onAccept() {
    return _acceptStream.stream;
  }
}

class HetiSocketDartIo extends HetiSocket {
  Socket _socket = null;

  HetiSocketDartIo() {}
  HetiSocketDartIo.fromSocket(Socket socket) {
    _socket = socket;
  }

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
        print('<<<lis>>> ');//${data.length} ${UTF8.decode(data)}');
        this.buffer.appendIntList(data,0, data.length);
        _receiveStream.add(new HetiReceiveInfo(data));
      }, onDone: () {
        print('<<<Done>>>');
        _socket.close();
        _closeStream.add(new HetiCloseInfo());
      }, onError: (e) {
        print('<<<Got error>>> $e');
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

class HetiUdpSocketDartIo extends HetiUdpSocket {
  RawDatagramSocket _udpSocket = null;
  HetiUdpSocketDartIo() {}

  bool _isBindingNow = false;
  async.StreamController<HetiReceiveUdpInfo> _receiveStream = new async.StreamController.broadcast();
  
  @override
  async.Future<int> bind(String address, int port, {bool multicast: false}) async {
    if (_isBindingNow != false) {
      throw "now binding";
    }
    _isBindingNow = true;
    try {
      RawDatagramSocket socket = await RawDatagramSocket.bind(address, port, reuseAddress: true);
      _udpSocket = socket;
      socket.multicastLoopback = multicast;
      socket.listen((RawSocketEvent event) {
        if(event == RawSocketEvent.READ) {
          Datagram dg = socket.receive();
          print("read ${dg.address}:${dg.port} ${dg.data.length}");
          _receiveStream.add(new HetiReceiveUdpInfo(dg.data, dg.address.address, dg.port));
        }
      });
    } finally {
      _isBindingNow = false;
    }
    return 0;
  }

  @override
  async.Future close() async {
    _udpSocket.close();
    return 0;
  }

  @override
  async.Stream<HetiReceiveUdpInfo> onReceive() {
    return _receiveStream.stream;
  }

  @override
  async.Future<HetiUdpSendInfo> send(List<int> buffer, String address, int port) async {
   _udpSocket.send(buffer, new InternetAddress(address), port);
   return await new HetiUdpSendInfo(0);
  }
}
