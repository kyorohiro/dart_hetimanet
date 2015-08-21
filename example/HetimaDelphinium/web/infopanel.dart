part of delphiniumapp;

/**
 * ui parts
 */
class InfoPanel {
  ui.VerticalPanel infoForSubPanel = new ui.VerticalPanel();
  ui.TextBox _rootPath = new ui.TextBox();

  // Add a drop box with the list types
  ui.ListBox dropBox = new ui.ListBox();

  String get rootPath => _rootPath.text;
  String get initAddress => dropBox.getItemText(dropBox.getSelectedIndex());

  async.StreamController<String> _controllerRootPath = new async.StreamController.broadcast();
  async.Stream<String> get onChRootPath => _controllerRootPath.stream;

  async.StreamController<String> _controllerInitAddress = new async.StreamController.broadcast();
  async.Stream<String> get onInitAddress => _controllerInitAddress.stream;

  InfoPanel() {
    _rootPath.text = "hetima";
  }

  void setDownloadPath(String path) {
    _rootPath.text = path;
  }

  void initInfoPanel() {
    infoForSubPanel.clear();

    ui.FlexTable layout = new ui.FlexTable();
    layout.setCellSpacing(5);
    ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

    layout.setHtml(0, 0, "");
    cellFormatter.setColSpan(0, 0, 2);
    cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_CENTER);

    layout.setWidget(1, 0, new ui.HtmlPanel("root path"));
    layout.setWidget(2, 1, _rootPath);
    layout.setWidget(3, 0, new ui.HtmlPanel("initial ip"));
//    _rootPath
    infoForSubPanel.add(layout);
    layout.setWidget(4, 1, dropBox);
    dropBox.addItem("0.0.0.0");
    dropBox.setSelectedIndex(0);
    new hetima.HetimaSocketBuilderChrome().getNetworkInterfaces().then((List<hetima.HetimaNetworkInterface> interfaces) {
      for (hetima.HetimaNetworkInterface i in interfaces) {
        dropBox.addItem("${i.address}");
      }
    });
  }
}
