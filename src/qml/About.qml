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

  // Add MouseArea that covers the entire panel
  MouseArea {
    anchors.fill: parent
    onClicked: aboutPanel.visible = false
  }

  Rectangle {
    color: "black"
    opacity: 0.9
    anchors.fill: parent
  }

  ColumnLayout {
    id: aboutContainer
    spacing: 4
    anchors.fill: parent
    anchors.margins: 15
    anchors.topMargin: 15 + mainWindow.sceneTopMargin
    anchors.bottomMargin: 15 + mainWindow.sceneBottomMargin

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

      ColumnLayout {
        id: information
        spacing: 20
        width: aboutPanel.width - 30
        height: Math.max(mainWindow.height - sponsorshipButton.height - linksButton.height - qfieldAppDirectoryLabel.height - aboutContainer.spacing * 3 - aboutContainer.anchors.topMargin - aboutContainer.anchors.bottomMargin - 10, qfieldPart.height + opengisPart.height + customImagePart.height + spacing * 2)

        ColumnLayout {
          id: qfieldPart
          Layout.fillWidth: true
          Layout.preferredHeight: implicitHeight
          Layout.bottomMargin: 10
          spacing: 6

          MouseArea {
            Layout.preferredWidth: 110
            Layout.preferredHeight: 110
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
            onClicked: {
              Qt.openUrlExternally("")
              mouse.accepted = true  // Prevent event from propagating
            }
          }

          Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            font: Theme.defaultFont
            color: Theme.light
            textFormat: Text.RichText
            wrapMode: Text.WordWrap

            text: {"Versión: beta1.1.0 | Desarrollo basado software libre: QGIS 3.40.3 BRATISLAVA | QField 3.5.2 | GDAL/OGR 3.10.1 | Qt 6.8.2 | ANDROID NDK 26 |"}
          }
        }

        ColumnLayout {
          id: sigpacgoPart
          Layout.fillWidth: true
          Layout.preferredHeight: implicitHeight
          Layout.topMargin: 10
          Layout.bottomMargin: 10
          spacing: 6

          MouseArea {
            Layout.preferredWidth: 180
            Layout.preferredHeight: 90
            Layout.alignment: Qt.AlignHCenter
            Image {
              id: imagritoolsLogo
              width: parent.width
              height: parent.height
              fillMode: Image.PreserveAspectFit
              source: "qrc:/images/imagr-logo.svg"
              sourceSize.width: width * screen.devicePixelRatio
              sourceSize.height: height * screen.devicePixelRatio
            }
            onClicked: {
              Qt.openUrlExternally("https://sites.google.com/view/intecnatur")
              mouse.accepted = true  // Prevent event from propagating
            }
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: creditText.implicitHeight
            
            // Prevent clicks on the text area from closing the panel
            MouseArea {
              anchors.fill: parent
              onClicked: mouse.accepted = true // Stop propagation
            }
            
            Text {
              id: creditText
              anchors.centerIn: parent
              width: Math.min(parent.width - 10, implicitWidth)
              horizontalAlignment: Text.AlignHCenter
              font: Theme.defaultFont
              color: Theme.light
              textFormat: Text.RichText
              wrapMode: Text.WordWrap
              text: qsTr('Mis agradecimientos a los amigos de <a href="https://sites.google.com/view/intecnatur">InTecnatur</a>')
              onLinkActivated: link => Qt.openUrlExternally(link)
            }
          }
        }

        ColumnLayout {
          id: intecnaturPart
          Layout.fillWidth: true
          Layout.preferredHeight: implicitHeight
          Layout.topMargin: 10
          spacing: 6

          MouseArea {
            Layout.preferredWidth: 180
            Layout.preferredHeight: 90
            Layout.alignment: Qt.AlignHCenter
            Image {
              id: inTecnaturLogo
              width: parent.width
              height: parent.height
              fillMode: Image.PreserveAspectFit
              source: "qrc:/images/intecnatur-logo.svg"
              sourceSize.width: width * screen.devicePixelRatio
              sourceSize.height: height * screen.devicePixelRatio
            }
            onClicked: {
              Qt.openUrlExternally("https://sites.google.com/view/intecnatur")
              mouse.accepted = true  // Prevent event from propagating
            }
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: creditText.implicitHeight
            
            // Prevent clicks on the text area from closing the panel
            MouseArea {
              anchors.fill: parent
              onClicked: mouse.accepted = true // Stop propagation
            }
            
            Text {
              id: crediText
              anchors.centerIn: parent
              width: Math.min(parent.width - 10, implicitWidth)
              horizontalAlignment: Text.AlignHCenter
              font: Theme.defaultFont
              color: Theme.light
              textFormat: Text.RichText
              wrapMode: Text.WordWrap
              text: qsTr('Mis agradecimientos a los amigos de <a href="https://sites.google.com/view/intecnatur">InTecnatur</a> consultoría agroecológica por el apoyo y confianza')
              onLinkActivated: link => Qt.openUrlExternally(link)
            }
          }
        }
      }
    }

    // Directory label with MouseArea to prevent panel closing
    Item {
      Layout.fillWidth: true
      Layout.maximumWidth: parent.width
      Layout.alignment: Qt.AlignCenter
      Layout.topMargin: 15
      Layout.bottomMargin: 10
      Layout.preferredHeight: qfieldAppDirectoryLabel.implicitHeight
      
      MouseArea {
        anchors.fill: parent
        onClicked: mouse.accepted = true // Stop propagation
      }
      
      Label {
        id: qfieldAppDirectoryLabel
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 8
        color: Theme.secondaryTextColor
        textFormat: Text.RichText
        wrapMode: Text.WordWrap

        text: {
          let label = '';
          let isDesktopPlatform = Qt.platform.os !== "ios" && Qt.platform.os !== "android";
          let dataDirs = platformUtilities.appDataDirs();
          if (dataDirs.length > 0) {
            label = dataDirs.length > 1 ? qsTr('SIGPACGO directorios') : qsTr('SIGPACGO directorio');
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
    }

    // Prevent the main MouseArea from capturing clicks on the buttons and labels
    MouseArea {
      id: buttonAreaBlocker
      anchors.fill: buttonContainer
      onClicked: mouse.accepted = true // Stop propagation
    }
    
    // Row layout for smaller buttons side by side
    ColumnLayout {
      id: buttonContainer
      Layout.fillWidth: true
      spacing: 15
      Layout.topMargin: 5
      
      QfButton {
        id: sponsorshipButton
        Layout.fillWidth: true
        Layout.preferredHeight: 40
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
        Layout.preferredHeight: 40
        icon.source: Theme.getThemeVectorIcon('ic_book_white_24dp')
        icon.width: 18
        icon.height: 18
        font.pixelSize: 12

        text: qsTr('Registro de cambios')

        onClicked: {
          changelogPopup.open();
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
