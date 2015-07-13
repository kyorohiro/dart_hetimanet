library HetimaPortMap.impl;
import 'package:dart_web_toolkit/event.dart' as event;
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'dart:async' as async;
import 'mainview.dart';

class MainViewImpl extends MainView {

  static const int MAIN = 0;
  static const int LIST = 1;
  static const int INFO = 2;

  ui.ListBox _foundRouter = new ui.ListBox();
  ui.VerticalPanel _mainPanel = new ui.VerticalPanel();
  ui.VerticalPanel _subPanel = new ui.VerticalPanel();

  ui.VerticalPanel _mainForSubPanel = new ui.VerticalPanel();
  ui.VerticalPanel _otherForSubPanel = new ui.VerticalPanel();
  ui.VerticalPanel _infoForSubPanel = new ui.VerticalPanel();

  async.StreamController _controllerSearchButton = new async.StreamController.broadcast();
  async.StreamController _controllerTab = new async.StreamController.broadcast();
  async.StreamController _controllerSelectRouter = new async.StreamController.broadcast();
  async.StreamController _controllerAddPortMapButton = new async.StreamController.broadcast();
  async.StreamController _controllerDelPortMapButton = new async.StreamController.broadcast();

  async.Stream<int> get onClickSearchButton => _controllerSearchButton.stream;
  async.Stream<int> get onSelectTab => _controllerTab.stream;
  async.Stream<String> get onSelectRouter => _controllerSelectRouter.stream;
  async.Stream<AppPortMapInfo> get onClieckAddPortMapButton => _controllerAddPortMapButton.stream;
  async.Stream<AppPortMapInfo> get onClieckDelPortMapButton => _controllerDelPortMapButton.stream;

  ui.Html _globalIpBox = new ui.Html("");
  ui.Html _routerAddress = new ui.Html("");

  List<AppPortMapInfo> portMapList = [];
  List<AppNetworkInterface> networkInterfaceList = [];

  void clearFoundRouterList() {
    _foundRouter.clear();
  }

  void addFoundRouterList(String itemName) {
    _foundRouter.addItem(itemName);
  }

  void setGlobalIp(String ip) {
    _globalIpBox.text = ip;
  }

  void setRouterAddress(String address) {
    _routerAddress.text = address;
  }

  void clearPortMappInfo() {
    portMapList.clear();
    updateRouterList();
  }

  void addPortMappInfo(AppPortMapInfo info) {
    portMapList.add(info);
    updateRouterList();
  }

  void clearNetworkInterface() {
    networkInterfaceList.clear();
  }

  void addNetworkInterface(AppNetworkInterface value) {
    networkInterfaceList.add(value);
    updateInfoPanel();
  }

  String currentSelectRouter() {
    if (_foundRouter.getSelectedIndex() == -1) {
      return "";
    }
    return _foundRouter.getValue(_foundRouter.getSelectedIndex());
  }

  void intialize() {
    initTopPanel();
    initMainTab();
    initTab();
    _mainPanel.spacing = 10;

    _foundRouter.addChangeHandler(new event.ChangeHandlerAdapter((event.ChangeEvent event) {
      _controllerSelectRouter.add(_foundRouter.getValue(_foundRouter.getSelectedIndex()));
    }));

    ui.RootPanel.get().add(_mainPanel);
    _subPanel.clear();

    _subPanel.add(_mainForSubPanel);

  }

  void initTopPanel() {
    ui.Button button = new ui.Button("search router", new event.ClickHandlerAdapter((event.ClickEvent event) {
      _controllerSearchButton.add(0);
    }));
    _mainPanel.add(button);
  }

  void initMainTab() {
    _mainPanel.add(_foundRouter);
    _foundRouter.addChangeHandler(new event.ChangeHandlerAdapter((event.ChangeEvent event) {
    }));
    _mainForSubPanel.add(new ui.Label("main operation"));
    initMainPanel();
    _otherForSubPanel.add(new ui.Label("other operation"));
    updateRouterList();
  }

  void initMainPanel() {
    ui.FlexTable layout = new ui.FlexTable();
    layout.setCellSpacing(6);
    ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

    layout.setHtml(0, 0, "Enter Port Map");
    cellFormatter.setColSpan(0, 0, 2);
    cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);

    ui.TextBox localPortBox = new ui.TextBox();
    ui.TextBox localAddressBox = new ui.TextBox();
    ui.TextBox publicPortBox = new ui.TextBox();
    ui.TextBox descriptionBox = new ui.TextBox();
    ui.RadioButton radioTCP = new ui.RadioButton("protocol", "TCP");
    ui.RadioButton radioUDP = new ui.RadioButton("protocol", "UDP");

    layout.setHtml(1, 0, "Local Port:");
    layout.setWidget(1, 1, localPortBox);
    layout.setHtml(2, 0, "Public Port:");
    layout.setWidget(2, 1, publicPortBox);
    layout.setHtml(3, 0, "Protocol:");
    {
      ui.VerticalPanel vPanel = new ui.VerticalPanel();
      vPanel.add(radioTCP);
      vPanel.add(radioUDP);
      radioTCP.setValue(true);
      layout.setWidget(3, 1, vPanel);
    }
    layout.setHtml(4, 0, "Local Address:");
    layout.setWidget(4, 1, localAddressBox);
    layout.setHtml(5, 0, "Description:");
    layout.setWidget(5, 1, descriptionBox);

    ui.Button button = new ui.Button("add", new event.ClickHandlerAdapter((event.ClickEvent event) {
      AppPortMapInfo info = new AppPortMapInfo();
      info.description = descriptionBox.text;
      info.localPort = localPortBox.text;
      info.localIp = localAddressBox.text;
      info.publicPort = publicPortBox.text;
      if (radioTCP.enabled) {
        info.protocol = "TCP";
      } else {
        info.protocol = "UDP";
      }
      _controllerAddPortMapButton.add(info);
    }));
    layout.setWidget(6, 1, button);

    ui.DecoratorPanel decPanel = new ui.DecoratorPanel();
    decPanel.addStyleName("hetima-grid");
    decPanel.setWidget(layout);
    _mainForSubPanel.add(decPanel);
  }

  void initTab() {
    ui.TabBar bar = new ui.TabBar();
    bar.addTabText("main");
    bar.addTabText("list");
    bar.addTabText("info");
    bar.selectTab(0);
    _mainPanel.add(bar);
    _mainPanel.add(_subPanel);

    bar.addSelectionHandler(new event.SelectionHandlerAdapter((event.SelectionEvent evt) {
      int selectedTabIndx = evt.getSelectedItem();
      if (selectedTabIndx == 0) {
        _subPanel.clear();
        _subPanel.add(_mainForSubPanel);
        _controllerTab.add(MAIN);
      } else if (selectedTabIndx == 1) {
        _subPanel.clear();
        _subPanel.add(_otherForSubPanel);
        _controllerTab.add(LIST);
      } else {
        _subPanel.clear();
        _subPanel.add(_infoForSubPanel);
        updateInfoPanel();
        _controllerTab.add(INFO);
      }
    }));

  }

  void updateRouterList() {
    //
    // clear
    _otherForSubPanel.clear();

    //
    // Create a grid
    ui.Grid grid = new ui.Grid(1 + portMapList.length, 6);
    grid.addStyleName("cw-FlexTable");

    // Add images to the grid
    int numRows = grid.getRowCount();
    int numColumns = grid.getColumnCount();
    {
      grid.setWidget(0, 5, new ui.Html("Description"));
      grid.setWidget(0, 0, new ui.Html("@"));
      grid.setWidget(0, 1, new ui.Html("Protocol"));
      grid.setWidget(0, 2, new ui.Html("Public Port"));
      grid.setWidget(0, 3, new ui.Html("Local IP"));
      grid.setWidget(0, 4, new ui.Html("Local Port"));
    }

    int row = 1;
    for (AppPortMapInfo i in portMapList) {
      ui.Html l0 = new ui.Html("${i.description}");
      ui.Html l1 = new ui.Html("${i.protocol}");
      ui.Html l2 = new ui.Html("${i.publicPort}");
      ui.Html l3 = new ui.Html("${i.localIp}");
      ui.Html l4 = new ui.Html("${i.localPort}");
      l0.addStyleName("hetima-grid");
      l1.addStyleName("hetima-grid");
      l2.addStyleName("hetima-grid");
      l3.addStyleName("hetima-grid");
      l4.addStyleName("hetima-grid");

      int crow = row;
      ui.Button b = new ui.Button("x", new event.ClickHandlerAdapter((event.ClickEvent evt) {
        _controllerDelPortMapButton.add(i);
        grid.setWidget(crow, 0, new ui.Html("-"));
      }));
      grid.setWidget(row, 5, l0);
      grid.setWidget(row, 0, b);
      grid.setWidget(row, 1, l1);
      grid.setWidget(row, 2, l2);
      grid.setWidget(row, 3, l3);
      grid.setWidget(row, 4, l4);
      row++;
    }
    _otherForSubPanel.add(grid);
  }

  void updateInfoPanel() {
    _infoForSubPanel.clear();

    ui.FlexTable layout = new ui.FlexTable();
    layout.setCellSpacing(6);
    ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();
    layout.setHtml(0, 0, "Information");
    cellFormatter.setColSpan(0, 0, 2);
    cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);

    layout.setHtml(1, 0, "Global IP:");
    _globalIpBox.addStyleName("hetima-grid");
    layout.setWidget(2, 1, _globalIpBox);

    layout.setHtml(3, 0, "Local IP:");
    {
      ui.Grid grid = new ui.Grid(1 + networkInterfaceList.length, 5);
      grid.addStyleName("cw-FlexTable");
      grid.setWidget(0, 0, new ui.Html("IP"));
      grid.setWidget(0, 1, new ui.Html("Length"));
      grid.setWidget(0, 2, new ui.Html("Name"));
      {
        int index = 0;
        for (AppNetworkInterface i in networkInterfaceList) {
          ui.Html l0 = new ui.Html("${i.ip}");
          l0.addStyleName("hetima-grid");
          ui.Html l1 = new ui.Html("${i.length}");
          l1.addStyleName("hetima-grid");
          ui.Html l2 = new ui.Html("${i.name}");
          l2.addStyleName("hetima-grid");
          grid.setWidget(index + 1, 0, l0);
          grid.setWidget(index + 1, 1, l1);
          grid.setWidget(index + 1, 2, l2);
          index++;
        }
//        grid.setWidget(1, 1, widget);
      }

      layout.setWidget(4, 1, grid);
    }

    layout.setHtml(5, 0, "Router Address:");
    _routerAddress.addStyleName("hetima-grid");
    layout.setWidget(6, 1, _routerAddress);

    _infoForSubPanel.add(layout);
  }

  /**
   * ui.DialogBox dialogBox = createDialogBox(String title, ui.Widget body)
   * dialogBox.setGlassEnabled(false);
   * dialogBox.show();
   * dialogBox.center();
   */
  ui.DialogBox createDialogBox(String title, ui.Widget body) {
    ui.DialogBox dialogBox = new ui.DialogBox();
    dialogBox.text = title;

    // Create a table to layout the content
    ui.VerticalPanel dialogContents = new ui.VerticalPanel();
    dialogContents.spacing = 4;
    dialogBox.setWidget(dialogContents);

    // Add some text to the top of the dialog
    dialogContents.add(body);
    dialogContents.setWidgetCellHorizontalAlignment(body, i18n.HasHorizontalAlignment.ALIGN_CENTER);

    // Add a close button at the bottom of the dialog
    ui.Button closeButton = new ui.Button("Close", new event.ClickHandlerAdapter((event.ClickEvent evt) {
      dialogBox.hide();
    }));
    dialogContents.add(closeButton);
    if (i18n.LocaleInfo.getCurrentLocale().isRTL()) {
      dialogContents.setWidgetCellHorizontalAlignment(closeButton, i18n.HasHorizontalAlignment.ALIGN_LEFT);
    } else {
      dialogContents.setWidgetCellHorizontalAlignment(closeButton, i18n.HasHorizontalAlignment.ALIGN_RIGHT);
    }

    // Return the dialog box
    return dialogBox;
  }
}
