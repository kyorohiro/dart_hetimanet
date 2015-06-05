library hetimanet.http.client.helper;

import 'dart:convert' as convert;
import 'dart:async' as async;
import 'package:hetimacore/hetimacore.dart';
import '../net/hetisocket.dart';
import '../util/hetiutil.dart';
import 'hetihttpresponse.dart';
import 'chunkedbuilderadapter.dart';
import 'hetihttpclient.dart';


class HetiHttpClientHelper {
  String _address;
  int _port;
  HetiSocketBuilder _builder;
  String get address => _address;
  int get port => _port;

  HetiHttpClientHelper(String address, int port, HetiSocketBuilder builder) {
    this._address = address;
    this._port = port;
    this._builder = builder;
  }

  async.Future<HetimaFile> get(String pathAndOption) {
    HetiHttpClient client  = new HetiHttpClient(_builder);
    client.connect(_address, _port).then((HetiHttpClientConnectResult b){
      
    });
  }
}