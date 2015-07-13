library HetimaPortMap.mainview;
import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'dart:async' as async;

abstract class MainView {

  static const int MAIN = 0;
  static const int LIST = 1;
  static const int INFO = 2;

  void clearFoundRouterList();
  void addFoundRouterList(String itemName);
  void setGlobalIp(String ip);
  void setRouterAddress(String address);
  void clearPortMappInfo();
  void addPortMappInfo(AppPortMapInfo info);
  void clearNetworkInterface();
  void addNetworkInterface(AppNetworkInterface value);
  String currentSelectRouter();
  void intialize();
  void initTopPanel();
  void initMainTab();

  void initMainPanel();
  void initTab();
  void updateRouterList();
  void updateInfoPanel();
}

class AppPortMapInfo {
  String protocol = "";
  String publicPort = "";
  String localIp = "";
  String localPort = "";
  String description = "";
}

class AppNetworkInterface {
  String ip = "";
  String length = "";
  String name = "";
} 