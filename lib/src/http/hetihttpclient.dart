library hetimanet.http.client;

import 'dart:convert' as convert;
import 'dart:async' as async;
import 'package:hetimacore/hetimacore.dart';
import '../net/hetisocket.dart';
import '../util/hetiutil.dart';
import 'hetihttpresponse.dart';
import 'chunkedbuilderadapter.dart';

class HetiHttpClientResponse {
  HetiHttpMessageWithoutBody message;
  HetimaReader body;
  int getContentLength() {
    HetiHttpResponseHeaderField contentLength = message.find(RfcTable.HEADER_FIELD_CONTENT_LENGTH);
    if (contentLength != null) {
      try {
        return int.parse(contentLength.fieldValue);
      } catch (e) {}
    }
    return -1;
  }
}

class HetiHttpClientConnectResult {
  
}
class HetiHttpClient {
  HetiSocketBuilder _socketBuilder;
  HetimaDataBuilder _dataBuilder;
  HetiSocket socket = null;
  String host;
  int port;

  bool _verbose = false;
  //, [HetimaDataBuilder b]
  HetiHttpClient(HetiSocketBuilder socketBuilder, {HetimaDataBuilder dataBuilder:null, bool verbose:false}) {
    _socketBuilder = socketBuilder;
    _verbose = verbose;
  }

  async.Future<HetiHttpClientConnectResult> connect(String _host, int _port) {
    host = _host;
    port = _port;
    async.Completer<HetiHttpClientConnectResult> completer = new async.Completer();
    socket = _socketBuilder.createClient();
    if (socket == null) {
      completer.completeError(new Exception(""));
      return completer.future;
    }
    if(_verbose == true) {
      print("<hetihttpclient f=connect> ${socket}");
    }
    socket.connect(host, port).then((HetiSocket socket) {
      if (socket == null) {
        completer.completeError(new Exception(""));
      } else {
        completer.complete(new HetiHttpClientConnectResult());
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<HetiHttpClientResponse> get(String path, [Map<String, String> header]) {
    async.Completer<HetiHttpClientResponse> completer = new async.Completer();

    Map<String, String> headerTmp = {};
    headerTmp["Host"] = host + ":" + port.toString();
    headerTmp["Connection"] = "Close";
    if (header != null) {
      for (String key in header.keys) {
        headerTmp[key] = header[key];
      }
    }

    ArrayBuilder builder = new ArrayBuilder();
    builder.appendString("GET" + " " + path + " " + "HTTP/1.1" + "\r\n");
    for (String key in headerTmp.keys) {
      builder.appendString("" + key + ": " + headerTmp[key] + "\r\n");
    }
    builder.appendString("\r\n");

    socket.onReceive.listen((HetiReceiveInfo info) {
      if(_verbose == true) {
        print("<hetihttpclient f=onReceive> Length${path}:${info.data.length} ${convert.UTF8.decode(info.data)}</hetihttpclient>");
      }
    });
    socket.send(builder.toList()).then((HetiSendInfo info) {});

    handleResponse(completer);
    return completer.future;
  }

  //
  // post
  //
  async.Future<HetiHttpClientResponse> post(String path, List<int> body, [Map<String, String> header]) {
    async.Completer<HetiHttpClientResponse> completer = new async.Completer();

    Map<String, String> headerTmp = {};
    headerTmp["Host"] = host + ":" + port.toString();
    headerTmp["Connection"] = "Close";
    if (header != null) {
      for (String key in header.keys) {
        headerTmp[key] = header[key];
      }
    }
    headerTmp[RfcTable.HEADER_FIELD_CONTENT_LENGTH] = body.length.toString();

    ArrayBuilder builder = new ArrayBuilder();
    builder.appendString("POST" + " " + path + " " + "HTTP/1.1" + "\r\n");
    for (String key in headerTmp.keys) {
      builder.appendString("" + key + ": " + headerTmp[key] + "\r\n");
    }

    builder.appendString("\r\n");
    builder.appendIntList(body, 0, body.length);

    //
    builder.getLength().then((int len) {
      builder.getByteFuture(0, len).then((List<int> data) {
        //print("request\r\n" + convert.UTF8.decode(data));
      });
    });
    //
    socket.onReceive.listen((HetiReceiveInfo info) {});
    socket.send(builder.toList()).then((HetiSendInfo info) {});

    handleResponse(completer);
    return completer.future;
  }

  //
  // mpost for upnp protocol
  //
  async.Future<HetiHttpClientResponse> mpost(String path, List<int> body, [Map<String, String> header]) {
    async.Completer<HetiHttpClientResponse> completer = new async.Completer();

    Map<String, String> headerTmp = {};
    headerTmp["Host"] = host + ":" + port.toString();
    headerTmp["Connection"] = "Close";
    if (header != null) {
      for (String key in header.keys) {
        headerTmp[key] = header[key];
      }
    }
    headerTmp[RfcTable.HEADER_FIELD_CONTENT_LENGTH] = body.length.toString();

    ArrayBuilder builder = new ArrayBuilder();
    builder.appendString("M-POST" + " " + path + " " + "HTTP/1.1" + "\r\n");
    for (String key in headerTmp.keys) {
      builder.appendString("" + key + ": " + headerTmp[key] + "\r\n");
    }

    builder.appendString("\r\n");
    builder.appendIntList(body, 0, body.length);

    //
    builder.getLength().then((int len) {
      builder.getByteFuture(0, len).then((List<int> data) {
        //print("request\r\n" + convert.UTF8.decode(data));
      });
    });
    //
    socket.onReceive.listen((HetiReceiveInfo info) {});
    socket.send(builder.toList()).then((HetiSendInfo info) {});

    handleResponse(completer);
    return completer.future;
  }

  void handleResponse(async.Completer<HetiHttpClientResponse> completer) {
    EasyParser parser = new EasyParser(socket.buffer);
    HetiHttpResponse.decodeHttpMessage(parser).then((HetiHttpMessageWithoutBody message) {
      HetiHttpClientResponse result = new HetiHttpClientResponse();
      result.message = message;
      //
      {
        socket.buffer.getByteFuture(0, message.index).then((List<int> buffer) {
          //print("response\r\n" + convert.UTF8.decode(buffer));
        });
      }
      //
      HetiHttpResponseHeaderField transferEncodingField = message.find("Transfer-Encoding");
      if (transferEncodingField == null || transferEncodingField.fieldValue != "chunked") {
        result.body = new HetimaReaderAdapter(socket.buffer, message.index);
        if (result.message.contentLength > 0) {
          result.body.getByteFuture(0, result.message.contentLength).then((e) {
            if(_verbose == true) {
               print("-------------------- immutable =true;[B] ${result.message.contentLength} ${message.index}");
            }
            result.body.immutable = true;
          });
        } else {
          if(_verbose == true) {
              print("-------------------- immutable =true; [A}");
           }
          result.body.immutable = true;
        }
      } else {
        result.body = new ChunkedBuilderAdapter(new HetimaReaderAdapter(socket.buffer, message.index)).start();
      }
      completer.complete(result);
    }).catchError((e) {
      completer.completeError(e);
    });
  }

  void close() {
    if (socket != null) {
      socket.close();
    }
  }
}
