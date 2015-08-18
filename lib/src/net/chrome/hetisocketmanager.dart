part of hetimanet.chrome;

class HetiSocketBuilderChrome extends HetiSocketBuilder {

  HetiSocket createClient() {
    return new HetiSocketChrome.empty();
  }

  Future<HetiServerSocket> startServer(String address, int port) {
    return HetiServerSocketChrome.startServer(address, port);
  }

  HetiUdpSocket createUdpClient() {
    return new HetiUdpSocketChrome.empty();
  }

  Future<List<HetiNetworkInterface>> getNetworkInterfaces() {
    Completer<List<HetiNetworkInterface>> completer = new Completer();
    List<HetiNetworkInterface> interfaceList = new List();
    chrome.system.network.getNetworkInterfaces().then((List<chrome.NetworkInterface> nl) {
      for (chrome.NetworkInterface i in nl) {
        HetiNetworkInterface inter = new HetiNetworkInterface();
        inter.address = i.address;
        inter.prefixLength = i.prefixLength;
        inter.name = i.name;
        interfaceList.add(inter);
      }
      completer.complete(interfaceList);
    }).catchError((e){
      completer.completeError(e);
    });
    return completer.future;
  }
}

class HetiChromeSocketManager {
  Map<int, HetiServerSocket> _serverList = new Map();
  Map<int, HetiSocket> _clientList = new Map();
  Map<int, HetiUdpSocket> _udpList = new Map();
  static final HetiChromeSocketManager _instance = new HetiChromeSocketManager._internal();
  factory HetiChromeSocketManager() {
    return _instance;
  }

  HetiChromeSocketManager._internal() {
    manageServerSocket();
  }

  static HetiChromeSocketManager getInstance() {
    return _instance;
  }

  void manageServerSocket() {
    chrome.sockets.tcpServer.onAccept.listen((chrome.AcceptInfo info) {
      print("--accept ok " + info.socketId.toString() + "," + info.clientSocketId.toString());
      HetiServerSocketChrome server = _serverList[info.socketId];
      if (server != null) {
        server.onAcceptInternal(info);
      }
    });

    chrome.sockets.tcpServer.onAcceptError.listen((chrome.AcceptErrorInfo info) {
      print("--accept error");
    });

    bool closeChecking = false;
    chrome.sockets.tcp.onReceive.listen((chrome.ReceiveInfo info) {
     // core.print("--receive " + info.socketId.toString() + "," + info.data.getBytes().length.toString());
      HetiSocketChrome socket = _clientList[info.socketId];
      if (socket != null) {
        socket.onReceiveInternal(info);
      }
    });
    chrome.sockets.tcp.onReceiveError.listen((chrome.ReceiveErrorInfo info) {
      print("--receive error " + info.socketId.toString() + "," + info.resultCode.toString());
      HetiSocketChrome socket = _clientList[info.socketId];
      if (socket != null) {
        closeChecking = true;
        socket.close();
      }
    });
    
    chrome.sockets.udp.onReceive.listen((chrome.ReceiveInfo info) {
      HetiUdpSocketChrome socket = _udpList[info.socketId];
      if (socket != null) {
        socket.onReceiveInternal(info);
      }
    });
    chrome.sockets.udp.onReceiveError.listen((chrome.ReceiveErrorInfo info) {
      print("--receive udp error " + info.socketId.toString() + "," + info.resultCode.toString());
    });
  }

  void addServer(chrome.CreateInfo info, HetiServerSocketChrome socket) {
    _serverList[info.socketId] = socket;
  }

  void removeServer(chrome.CreateInfo info) {
    _serverList.remove(info.socketId);
  }

  void addClient(int socketId, HetiSocketChrome socket) {
    _clientList[socketId] = socket;
  }

  void removeClient(int socketId) {
    _clientList.remove(socketId);
  }

  void addUdp(int socketId, HetiUdpSocket socket) {
    _udpList[socketId] = socket;
  }

  void removeUdp(int socketId) {
    _udpList.remove(socketId);
  }

}

