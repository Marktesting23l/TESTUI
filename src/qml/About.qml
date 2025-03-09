import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Item {
  id: aboutPanel

  visible: false
  focus: visible

  Rectangle {
    color: "black"
    opacity: 0.9
    anchors.fill: parent
  }

  ColumnLayout {
    id: aboutContainer
    spacing: 6
    anchors.fill: parent
    anchors.margins: 20
    anchors.topMargin: 20 + mainWindow.sceneTopMargin
    anchors.bottomMargin: 20 + mainWindow.sceneBottomMargin

    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical: QfScrollBar {
      }
      contentItem: information
      contentWidth: information.width
      contentHeight: information.height
      clip: true

      MouseArea {
        anchors.fill: parent
        onClicked: aboutPanel.visible = false
      }

      ColumnLayout {
        id: information
        spacing: 10
        width: aboutPanel.width - 40
        height: Math.max(mainWindow.height - sponsorshipButton.height - linksButton.height - qfieldAppDirectoryLabel.height - aboutContainer.spacing * 3 - aboutContainer.anchors.topMargin - aboutContainer.anchors.bottomMargin - 10, qfieldPart.height + opengisPart.height + customImagePart.height + spacing * 2)

        // First section - SIGPACGO logo and info
        ColumnLayout {
          id: qfieldPart
          Layout.fillWidth: true
          Layout.preferredHeight: implicitHeight
          spacing: 5

          MouseArea {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter
            Image {
              id: qfieldLogo
              width: parent.width
              height: parent.height
              fillMode: Image.PreserveAspectFit
              source: "qrc:/images/sigpacgo_logo.svg"
              sourceSize.width: width * screen.devicePixelRatio
              sourceSize.height: height * screen.devicePixelRatio
            }
            onClicked: Qt.openUrlExternally("https://qfield.org/")
          }

          Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            font: Theme.strongFont
            color: Theme.light
            textFormat: Text.RichText
            wrapMode: Text.WordWrap

            text: {
              let links = '<a href="https://github.com/opengisch/QField/commit/' + gitRev + '">' + gitRev.substr(0, 6) + '</a>';
              if (appVersion && appVersion !== '1.0.0') {
                links += ' <a href="https://github.com/opengisch/QField/releases/tag/' + appVersion + '">' + appVersion + '</a>';
              }
              // the `qgisVersion` has the format `<int>.<int>.<int>-<any text>`, so we get everything before the first `-`
              const qgisVersionWithoutName = qgisVersion.split("-", 1)[0];
              const dependencies = [["QGIS", qgisVersionWithoutName], ["GDAL/OGR", gdalVersion], ["Qt", qVersion]];
              const dependenciesStr = dependencies.map(pair => pair.join(" ")).join(" | ");
              return "SIGPACGO<br>" + appVersionStr + " (" + links + ")<br>" + dependenciesStr;
            }

            onLinkActivated: link => Qt.openUrlExternally(link)
          }
        }

        // Space for custom image
        ColumnLayout {
          id: customImagePart
          Layout.fillWidth: true
          Layout.preferredHeight: implicitHeight
          spacing: 5
          
          // This is a placeholder for your custom image
          Rectangle {
            id: customImagePlaceholder
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignHCenter
            color: "transparent"
            border.color: "#33ffffff"
            border.width: 1
            
            Text {
              anchors.centerIn: parent
              text: "Add your image here"
              color: Theme.light
              font.pixelSize: 12
            }
          }
          
          // Optional label for your custom image
          Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            font: Theme.strongFont
            color: Theme.light
            textFormat: Text.RichText
            wrapMode: Text.WordWrap
            text: "Custom Image"
          }
        }

        // OpenGIS section
        ColumnLayout {
          id: opengisPart
          Layout.fillWidth: true
          Layout.preferredHeight: implicitHeight
          spacing: 5

          MouseArea {
            Layout.preferredWidth: 80
            Layout.preferredHeight: 100
            Layout.alignment: Qt.AlignHCenter
            Image {
              id: opengisLogo
              width: parent.width
              height: parent.height
              fillMode: Image.PreserveAspectFit
              source: "qrc:/images/imagr-logo.svg"
              sourceSize.width: width * screen.devicePixelRatio
              sourceSize.height: height * screen.devicePixelRatio
            }
            onClicked: Qt.openUrlExternally("https://opengis.ch")
          }

          Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            font: Theme.strongFont
            color: Theme.light
            textFormat: Text.RichText
            text: qsTr("Developed by") + '<br><a href="https://opengis.ch">OPENGIS.ch</a>'
            onLinkActivated: link => Qt.openUrlExternally(link)
          }
        }
      }
    }

    Label {
      id: qfieldAppDirectoryLabel
      Layout.fillWidth: true
      Layout.maximumWidth: parent.width
      Layout.alignment: Qt.AlignCenter
      Layout.bottomMargin: 10
      horizontalAlignment: Text.AlignHCenter
      font: Theme.tinyFont
      color: Theme.secondaryTextColor
      textFormat: Text.RichText
      wrapMode: Text.WordWrap

      text: {
        let label = '';
        let isDesktopPlatform = Qt.platform.os !== "ios" && Qt.platform.os !== "android";
        let dataDirs = platformUtilities.appDataDirs();
        if (dataDirs.length > 0) {
          label = dataDirs.length > 1 ? qsTr('SIGPACGO app directories') : qsTr('SIGPACGO app directory');
          for (let dataDir of dataDirs) {
            if (isDesktopPlatform) {
              label += '<br><a href="' + UrlUtils.fromString(dataDir) + '">' + dataDir + '</a>';
            } else {
              label += '<br>' + dataDir;
            }
          }
        }
        return label;
      }

      onLinkActivated: link => Qt.openUrlExternally(link)
    }

    // Row layout for smaller buttons side by side
    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      
      QfButton {
        id: sponsorshipButton
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.maximumWidth: parent.width / 2 - 5
        icon.source: Theme.getThemeVectorIcon('ic_sponsor_white_24dp')
        icon.width: 18
        icon.height: 18
        font.pixelSize: 12

        text: qsTr('Support')
        onClicked: Qt.openUrlExternally("https://github.com/sponsors/opengisch")
      }

      QfButton {
        id: linksButton
        dropdown: true
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.maximumWidth: parent.width / 2 - 5
        icon.source: Theme.getThemeVectorIcon('ic_book_white_24dp')
        icon.width: 18
        icon.height: 18
        font.pixelSize: 12

        text: qsTr('Documentation')

        onClicked: {
          Qt.openUrlExternally("https://docs.qfield.org/");
        }

        onDropdownClicked: {
          linksMenu.popup(linksButton.width - linksMenu.width + 10, linksButton.y + 10);
        }
      }
    }
  }

  Menu {
    id: linksMenu
    title: qsTr("Links Menu")

    width: {
      var result = 0;
      var padding = 0;
      for (var i = 0; i < count; ++i) {
        var item = itemAt(i);
        result = Math.max(item.contentItem.implicitWidth, result);
        padding = Math.max(item.padding, padding);
      }
      return result + padding * 2;
    }

    MenuItem {
      text: qsTr('Changelog')

      font: Theme.defaultFont
      height: 48
      leftPadding: Theme.menuItemLeftPadding
      icon.source: Theme.getThemeVectorIcon('ic_speaker_white_24dp')

      onTriggered: {
        changelogPopup.open();
      }
    }
  }

  Keys.onReleased: event => {
    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
      event.accepted = true;
      visible = false;
    }
  }
}
