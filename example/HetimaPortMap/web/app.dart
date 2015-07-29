import 'dart:html' as html;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimanet/hetimanet.dart' as hetima;
import 'package:hetimanet/hetimanet_chrome.dart' as hetima;
import 'package:HetimaPortMap/mainview.dart' as appview;
//import 'package:HetimaPortMap/mainviewimpl.dart' deferred as impl;
import 'package:HetimaPortMap/mainviewimpl.dart' as impl;

hetima.UpnpDeviceSearcher deviceSearcher = null;
var mainView = null;

void main() {
  print("### main()");
  {
    mainView = new impl.MainViewImpl();
    html.Element loader = html.document.getElementById("loader");
    if (loader != null) {
      loader.remove();
    }
    setupUI();
    setupUpnp();    
  }
}

void setupUI() {
  print("### st setupUI");
  mainView.intialize();

  mainView.onClickSearchButton.listen((int v) {
    print("### search router");
    startSearchPPPDevice();
  });
  mainView.onSelectTab.listen((int v) {
    print("### select tag ${v}");
    if (v == appview.MainView.MAIN) {} else if (v == appview.MainView.LIST) {
      startUpdatePortMappedList();
    } else if (v == appview.MainView.INFO) {
      startUpdateIpInfo();
    } else {}
  });

  mainView.onSelectRouter.listen((String v) {
    print("### select router ${v}");
  });

  mainView.onClieckAddPortMapButton.listen((i) {
    print("### add port map ${i.description}");
    startAddPortMapp(i);
  });

  mainView.onClieckDelPortMapButton.listen((i) {
    print("### del port map ${i.description}");
    startDeletePortMapp(i);
  });
}

void setupUpnp() {
  print("### st setupUpnp");
  hetima.UpnpDeviceSearcher.createInstance(new hetima.HetiSocketBuilderChrome()).then((hetima.UpnpDeviceSearcher searcher) {
    print("### ok setupUpnp ${searcher}");
    deviceSearcher = searcher;
    searcher.onReceive().listen((hetima.UpnpDeviceInfo info) {
      print("###log:" + info.toString());
      mainView.addFoundRouterList(info.getValue(hetima.UpnpDeviceInfo.KEY_USN, "*"));
    });
  }).catchError((e) {
    print("### er setupUpnp ${e}");
  });
}

hetima.UpnpDeviceInfo getCurrentRouter() {
  if (deviceSearcher.deviceInfoList.length <= 0) {
    return null;
  }
  String routerName = mainView.currentSelectRouter();
  for (hetima.UpnpDeviceInfo info in deviceSearcher.deviceInfoList) {
    if (info == null) {
      continue;
    }
    if (routerName == info.getValue(hetima.UpnpDeviceInfo.KEY_USN, "*")) {
      return info;
    }
  }
  return deviceSearcher.deviceInfoList.first;
}

void startUpdateIpInfo() {
  if (deviceSearcher == null) {
    return;
  }

  hetima.UpnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return;
  }

  hetima.UpnpPPPDevice pppDevice = new hetima.UpnpPPPDevice(info);
  pppDevice.requestGetExternalIPAddress().then((hetima.UpnpGetExternalIPAddressResponse ip) {
    if (ip.resultCode == 405) {
      //retry at mpost request
      return pppDevice.requestGetExternalIPAddress(hetima.UpnpPPPDevice.MODE_M_POST).then((hetima.UpnpGetExternalIPAddressResponse ip) {
        mainView.setGlobalIp(ip.externalIp);
      });
    } else {
      mainView.setGlobalIp(ip.externalIp);
    }
  }).catchError((e) {
    mainView.setGlobalIp("failed");
  });

  (new hetima.HetiSocketBuilderChrome()).getNetworkInterfaces().then((List<hetima.HetiNetworkInterface> interfaceList) {
    mainView.clearNetworkInterface();
    for (hetima.HetiNetworkInterface i in interfaceList) {
      var interface = new appview.AppNetworkInterface();
      interface.ip = i.address;
      interface.length = "${i.prefixLength}";
      interface.name = "${i.name}";
      mainView.addNetworkInterface(interface);
    }
  });

  mainView.setRouterAddress(info.presentationURL);
}

void startUpdatePortMappedList() {
  mainView.clearPortMappInfo();
  if (deviceSearcher == null) {
    return;
  }
  hetima.UpnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return;
  }
  int newPortmappingIndex = 0;
  hetima.UpnpPPPDevice pppDevice = new hetima.UpnpPPPDevice(info);
  int mode = hetima.UpnpPPPDevice.MODE_POST;
  requestPortMapInfo() {
    pppDevice.requestGetGenericPortMapping(newPortmappingIndex, mode).then((hetima.UpnpGetGenericPortMappingResponse r) {
      if (r.resultCode == 405 && mode == hetima.UpnpPPPDevice.MODE_POST) {
        mode = hetima.UpnpPPPDevice.MODE_M_POST;
        requestPortMapInfo();
        return;
      }

      if (r.resultCode != 200) {
        return;
      }

      var portMapInfo = new appview.AppPortMapInfo();
      portMapInfo.publicPort = r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewExternalPort, "");
      portMapInfo.localIp = r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewInternalClient, "");
      portMapInfo.localPort = r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewInternalPort, "");
      portMapInfo.protocol = r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewProtocol, "");
      portMapInfo.description = r.getValue(hetima.UpnpGetGenericPortMappingResponse.KEY_NewPortMappingDescription, "");
      if (portMapInfo.localPort.replaceAll(" |\t|\r|\n", "") == "" && portMapInfo.localIp.replaceAll(" |\t|\r|\n", "") == "") {
        return;
      }
      mainView.addPortMappInfo(portMapInfo);
      newPortmappingIndex++;
      requestPortMapInfo();
    }).catchError((e) {});
  }
  requestPortMapInfo();
}

bool isSearching = false;
void startSearchPPPDevice() {
  if (deviceSearcher == null || isSearching) {
    print("### search router:null");
    _showDialog("#### Search Router ####", "Not Found Router");
    return;
  }
  mainView.clearFoundRouterList();

  deviceSearcher.searchWanPPPDevice().then((int v) {
    isSearching = false;
    mainView.clearFoundRouterList();
    if (deviceSearcher.deviceInfoList == null || deviceSearcher.deviceInfoList.length <= 0) {
      _showDialog("#### Search Router ####", "Not Found Router");
      return;
    }
    for (hetima.UpnpDeviceInfo info in deviceSearcher.deviceInfoList) {
      mainView.addFoundRouterList(info.getValue(hetima.UpnpDeviceInfo.KEY_USN, "*"));
    }
  }).catchError((e) {
    print("error ${e.toString()}");
    isSearching = false;
  });
}

void _showDialog(String title, String message) {
  ui.DialogBox dialogBox = mainView.createDialogBox(title, new ui.Html(message));
  dialogBox.show();
  dialogBox.center();
}

void startAddPortMapp(var i) {
  hetima.UpnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return null;
  }
  hetima.UpnpPPPDevice pppDevice = new hetima.UpnpPPPDevice(info);

  showDialogAPM(hetima.UpnpAddPortMappingResponse resp) {
    String result = "OK";
    if (resp.resultCode != 200) {
      result = " $result resultCode = ${resp.resultCode}";
    }
    _showDialog("#### Port Map ####", result);
  }
  ;
  pppDevice.requestAddPortMapping(int.parse(i.publicPort), i.protocol, int.parse(i.localPort), i.localIp, 1, i.description, 0).then((hetima.UpnpAddPortMappingResponse resp) {
    if (resp.resultCode == 405) {
      return pppDevice
          .requestAddPortMapping(int.parse(i.publicPort), i.protocol, int.parse(i.localPort), i.localIp, 1, i.description, 0, hetima.UpnpPPPDevice.MODE_M_POST)
          .then((hetima.UpnpAddPortMappingResponse resp) {
        showDialogAPM(resp);
      });
    } else {
      showDialogAPM(resp);
    }
  }).catchError((e) {
    _showDialog("#### ERROR ####", "failed add port mapping");
  });
}

void startDeletePortMapp(var i) {
  hetima.UpnpDeviceInfo info = getCurrentRouter();
  if (info == null) {
    return;
  }
  hetima.UpnpPPPDevice pppDevice = new hetima.UpnpPPPDevice(info);

  showDialogDPM(hetima.UpnpDeletePortMappingResponse resp) {
    if (resp.resultCode != 200) {
      _showDialog("#### Delete Port Map NG ####", "resultCode = ${resp.resultCode}");
    } else {
      //_showDialog("#### Delete Port Map OK ####", "OK");
    }
  }
  ;
  pppDevice.requestDeletePortMapping(int.parse(i.publicPort), i.protocol).then((hetima.UpnpDeletePortMappingResponse resp) {
    if (resp.resultCode == 405) {
      return pppDevice.requestDeletePortMapping(int.parse(i.publicPort), i.protocol, hetima.UpnpPPPDevice.MODE_M_POST).then((hetima.UpnpDeletePortMappingResponse resp) {
        showDialogDPM(resp);
      });
    } else {
      showDialogDPM(resp);
    }
  }).catchError((e) {
    _showDialog("#### ERROR ####", "failed delete port mapping");
  });
}
