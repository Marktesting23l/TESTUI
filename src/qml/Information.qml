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
      text: qsTr("Información de SIGPACGO")
      horizontalAlignment: Text.AlignHCenter
      font.pixelSize: 24
      font.bold: true
      color: "white"
      wrapMode: Text.WordWrap
    }

    Label {
      width: parent.width
      text: qsTr("Bienvenido al Centro de Información de SIGPACGO")
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
      text: qsTr("Guías de Usuario")
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
          { title: "Guía de Inicio", url: "getting_started.pdf" },
          { title: "Recolección de Datos de Campo", url: "field_data.pdf" },
          { title: "Uso de Datos Meteorológicos", url: "weather_data.pdf" },
          { title: "Solución de Problemas", url: "troubleshooting.pdf" }
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
            displayToast(qsTr("Abriendo %1...").arg(modelData.title), "info")
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
      text: qsTr("Información de Contacto")
      font.pixelSize: 20
      font.bold: true
      color: "white"
      wrapMode: Text.WordWrap
    }

    Label {
      width: parent.width
      text: qsTr("Para soporte, por favor contacte:\nsupport@sigpacgo.com\n\nSitio web: www.sigpacgo.com")
      font.pixelSize: 16
      color: "white"
      wrapMode: Text.WordWrap
    }
  }
} 