library hetimanet.http.server.plus;

import 'dart:convert' as convert;
import 'dart:async' as async;
import 'package:hetimacore/hetimacore.dart';
import '../net/hetisocket.dart';
import '../util/hetiutil.dart';
import 'hetihttp.dart';
import 'hetihttpresponse.dart';
import 'hetihttpserver.dart';
import 'dart:typed_data' as typed_data;

class HetiHttpStartServerResult {
  
}

class HetiHttpServerHelper {
  String localIP = "0.0.0.0";
  int basePort = 18085;
  int _localPort = 18085;
  int numOfRetry = 100;
  int get localPort => _localPort;

  HetiHttpServer _server = null;
  HetiSocketBuilder _socketBuilder = null;

  async.StreamController<String> _controllerUpdateLocalServer = new async.StreamController.broadcast();
  async.Stream<String> get onUpdateLocalServer => _controllerUpdateLocalServer.stream;
  async.StreamController<HetiHttpServerPlusResponseItem> _onResponse = new async.StreamController();
  async.Stream<HetiHttpServerPlusResponseItem> get onResponse => _onResponse.stream;

  HetiHttpServerHelper(HetiSocketBuilder socketBuilder) {
    _socketBuilder = socketBuilder;
  }

  void stopServer() {
    if (_server == null) {
      return;
    }
    _server.close();
    _server = null;
  }

  async.Future<HetiHttpStartServerResult> startServer() {
    //print("startServer");
    _localPort = basePort;
    async.Completer<HetiHttpStartServerResult> completer = new async.Completer();
    if (_server != null) {
      completer.completeError({});
      return completer.future;
    }

    _retryBind().then((HetiHttpServer server) {
      _controllerUpdateLocalServer.add("${_localPort}");
      _server = server;
      completer.complete(new HetiHttpStartServerResult());
      server.onNewRequest().listen(_hundleRequest);
    }).catchError((e) {
      completer.completeError(e);
    });

    return completer.future;
  }

  void _hundleRequest(HetiHttpServerRequest req) {
   // print("${req.info.line.requestTarget}");
    if (req.info.line.requestTarget.length < 0) {
      req.socket.close();
      return;
    }
    _onResponse.add(new HetiHttpServerPlusResponseItem(req));
  }


  void response(HetiHttpServerRequest req, HetimaData file, {String contentType:"application/octet-stream", Map<String,String> headerList:null, int statusCode:null}) {
    if(headerList == null) {headerList = {};}
    headerList["Content-Type"] = contentType;
    HetiHttpResponseHeaderField fieldRangeHeader = req.info.find(RfcTable.HEADER_FIELD_RANGE);
    if (fieldRangeHeader != null && statusCode == null) {
      typed_data.Uint8List buff = new typed_data.Uint8List.fromList(convert.UTF8.encode(fieldRangeHeader.fieldValue));
      ArrayBuilder builder = new ArrayBuilder.fromList(buff);
      builder.fin();
      HetiHttpResponse.decodeRequestRangeValue(new EasyParser(builder)).then((HetiHttpRequestRange range) {
        _startResponseRangeFile(req.socket, file, headerList, range.start, range.end);
      });
    } else {
      _startResponseFile(req.socket, statusCode, headerList, file);
    }
  }


  void _startResponseRangeFile(HetiSocket socket, HetimaData file, Map<String,String> header, int start, int end) {
    ArrayBuilder response = new ArrayBuilder();
    file.getLength().then((int length) {
      if (end == -1 || end > length - 1) {
        end = length - 1;
      }
      int contentLength = end - start + 1;
      response.appendString("HTTP/1.1 206 Partial Content\r\n");
      response.appendString("Connection: close\r\n");
      response.appendString("Content-Length: ${contentLength}\r\n");
      response.appendString("Content-Range: bytes ${start}-${end}/${length}\r\n");
      for(String key in header.keys) {
        response.appendString("${key}: ${header[key]}\r\n");
      }
      response.appendString("\r\n");
      //print(response.toText());
      socket.send(response.toList()).then((HetiSendInfo i) {
        _startResponseBuffer(socket, file, start, contentLength);
      }).catchError((e) {
        socket.close();
      });
    });
  }

  void _startResponseFile(HetiSocket socket, int statuCode, Map<String,String> header, HetimaData file) {
    ArrayBuilder response = new ArrayBuilder();
    if(statuCode == null) {
      statuCode = 200;
    }
    file.getLength().then((int length) {
      response.appendString("HTTP/1.1 ${statuCode} OK\r\n");
      response.appendString("Connection: close\r\n");
      response.appendString("Content-Length: ${length}\r\n");
      for(String key in header.keys) {
        response.appendString("${key}: ${header[key]}\r\n");
      }
      response.appendString("\r\n");
      socket.send(response.toList()).then((HetiSendInfo i) {
        _startResponseBuffer(socket, file, 0, length);
      }).catchError((e) {
        socket.close();
      });
    });
  }

  void _startResponseBuffer(HetiSocket socket, HetimaData file, int index, int length) {
    int start = index;
    responseTask() {
      int end = start + 256 * 1024;
      if (end > (index + length)) {
        end = (index + length);
      }
      //print("####### ${start} ${end}");
      file.read(start, end-start).then((ReadResult readResult) {
        return socket.send(readResult.buffer);
      }).then((HetiSendInfo i) {
        if (end >= (index + length)) {
          socket.close();
        } else {
          start = end;
          responseTask();
        }
      }).catchError((e) {
        socket.close();
      }).catchError((e) {

      });
    }
    responseTask();
  }


  async.Future<HetiHttpServer> _retryBind() {
    async.Completer<HetiHttpServer> completer = new async.Completer();
    int portMax = _localPort + numOfRetry;
    bindFunc() {
      HetiHttpServer.bind(_socketBuilder, localIP, _localPort).then((HetiHttpServer server) {
        completer.complete(server);
      }).catchError((e) {
        _localPort++;
        if (_localPort < portMax) {
          bindFunc();
        } else {
          completer.completeError(e);
        }
      });
    }
    bindFunc();
    return completer.future;
  }

}

class HetiHttpServerPlusResponseItem {
  HetiHttpServerRequest req;
  
  HetiHttpServerPlusResponseItem(HetiHttpServerRequest req) {
    this.req = req;
  }

  HetiSocket get socket => req.socket;
  String get targetLine => req.info.line.requestTarget;
  String get path {
    int index = targetLine.indexOf("?");
    if (index == -1) {
      index = targetLine.length;
    }
    return targetLine.substring(0, index);
  }

  String get option {
    int index = targetLine.indexOf("?");
    if (index == -1) {
      index = targetLine.length;
    }
    return targetLine.substring(index);
  }
}

