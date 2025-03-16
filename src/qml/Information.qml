import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Item {
  id: informationPanel

  visible: false
  focus: visible

  Rectangle {
    color: "black"
    opacity: 0.9
    anchors.fill: parent
  }

  ColumnLayout {
    id: informationContainer
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
      contentItem: informationContent
      contentWidth: informationContent.width
      contentHeight: informationContent.height
      clip: true

      MouseArea {
        anchors.fill: parent
        onClicked: informationPanel.visible = false
      }
    }
  }

  Column {
    id: informationContent
    width: informationContainer.width - 40
    spacing: 10

    Image {
      id: logo
      source: "qrc:/images/sigpacgo_logo.svg"
      width: 200
      height: 200
      fillMode: Image.PreserveAspectFit
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
      width: parent.width
      text: qsTr("SIGPACGO Information")
      horizontalAlignment: Text.AlignHCenter
      font.pixelSize: 24
      font.bold: true
      color: "white"
      wrapMode: Text.WordWrap
    }

    Label {
      width: parent.width
      text: qsTr("Welcome to SIGPACGO Information Center")
      horizontalAlignment: Text.AlignHCenter
      font.pixelSize: 18
      color: "white"
      wrapMode: Text.WordWrap
    }

    Rectangle {
      width: parent.width
      height: 1
      color: "#555555"
    }

    Label {
      width: parent.width
      text: qsTr("User Guides")
      font.pixelSize: 20
      font.bold: true
      color: "white"
      wrapMode: Text.WordWrap
    }

    // PDF links would go here
    Column {
      width: parent.width
      spacing: 5

      Repeater {
        model: [
          { title: "Getting Started Guide", url: "getting_started.pdf" },
          { title: "Field Data Collection", url: "field_data.pdf" },
          { title: "Weather Data Usage", url: "weather_data.pdf" },
          { title: "Troubleshooting", url: "troubleshooting.pdf" }
        ]

        delegate: Button {
          width: parent.width
          height: 40
          text: modelData.title
          
          contentItem: Text {
            text: modelData.title
            font: parent.font
            color: Theme.mainColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
          
          background: Rectangle {
            color: parent.down ? "#33ffffff" : "#22ffffff"
            radius: 4
          }
          
          onClicked: {
            // Here we would open the PDF file
            // For now, just display a message
            displayToast(qsTr("Opening %1...").arg(modelData.title), "info")
          }
        }
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: "#555555"
    }

    Label {
      width: parent.width
      text: qsTr("Contact Information")
      font.pixelSize: 20
      font.bold: true
      color: "white"
      wrapMode: Text.WordWrap
    }

    Label {
      width: parent.width
      text: qsTr("For support, please contact:\nsupport@sigpacgo.com\n\nWebsite: www.sigpacgo.com")
      font.pixelSize: 16
      color: "white"
      wrapMode: Text.WordWrap
    }
  }
} 