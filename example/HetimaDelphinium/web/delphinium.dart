library delphiniumapp;
import 'dart:html' as html;
import 'dart:convert' as convert;
import 'dart:async' as async;
import 'dart:typed_data' as typed_data;
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimacore/hetimacore_cl.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;
import 'package:hetimanet/hetimanet_chrome.dart' as hetima;
import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/util.dart' as util;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/text.dart' as text;
import 'package:dart_web_toolkit/scheduler.dart' as scheduler;
import 'package:dart_web_toolkit/validation.dart' as validation;
import 'package:crypto/crypto.dart' as crypt;

part 'mainpanel.dart';
part 'filelistpanel.dart';
part 'mainview.dart';
part 'httpserver.dart';
part 'infopanel.dart';
part 'swfplayer.dart';

void main() {
  String downloadPath = "hetima";
  MainView mainView = new MainView();
  mainView.downloadPath = downloadPath;
  DelphiniumHttpServer httpServer = new DelphiniumHttpServer();
  httpServer.dataPath = downloadPath;
  hetima.UpnpPortMapHelper  portMap = new hetima.UpnpPortMapHelper(new hetima.HetimaSocketBuilderChrome(), "HetimaDelphinium", retry: 5);

  httpServer.onUpdateLocalServer.listen((String localPort){
    mainView.localPort = localPort;
    portMap.basePort = int.parse(localPort);
  });
  portMap.onUpdateGlobalIp.listen((String globalIp) {
    mainView.globalIP = globalIp;
  });
  portMap.onUpdateGlobalPort.listen((String globalPort) {
    mainView.globalPort = globalPort;
  });
  portMap.onUpdateLocalIp.listen((String localIP) {
    mainView.localIP = localIP;
  });

  mainView.onChRootPath.listen((String path){
    httpServer.localIP = path;
    mainView.downloadPath = path;
  });

  mainView.onInitAddress.listen((String ip) {
    httpServer.localIP = ip;    
  });
  mainView.init();
  mainView.onChangeMainButtonState.listen((bool isDown) {
    if (isDown) {
      httpServer.startServer().then((hetima.HetiHttpStartServerResult v) {
        return portMap.startGetLocalIp();
      }).then((_) {
        portMap.startPortMap();
      }).then((_){
        portMap.startGetExternalIp(reuseRouter: true);
      });
    } else {
      httpServer.stopServer();
      portMap.deletePortMapFromAppIdDesc(reuseRouter: true);
    }
  });

  mainView.onSelectFile.listen((FileSelectResult result) {
    String label = "${result.fname}";
    httpServer.addFile(label, result);
    mainView.addFile(label);
  });

  mainView.onDeleteFileFromList.listen((String fname) {
    httpServer.removeFile(fname);
  });

  chrome.app.window.current().onClosed.listen((d) {
    portMap.deletePortMapFromAppIdDesc(reuseRouter: true);
    httpServer.stopServer();
  });
}

