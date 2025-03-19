import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Popup {
  id: changelogPopup

  parent: mainWindow.contentItem
  width: mainWindow.width - Theme.popupScreenEdgeMargin * 2
  height: mainWindow.height - Math.max(Theme.popupScreenEdgeMargin * 2, mainWindow.sceneTopMargin * 2 + 4, mainWindow.sceneBottomMargin * 2 + 4)
  x: Theme.popupScreenEdgeMargin
  y: (mainWindow.height - height) / 2
  padding: 0
  modal: true
  closePolicy: Popup.CloseOnEscape
  focus: visible

  Page {
    focus: true
    anchors.fill: parent

    header: QfPageHeader {
      title: qsTr("Novedades en SIGPACGO")

      showApplyButton: false
      showCancelButton: false
      showBackButton: true

      onBack: {
        changelogPopup.close();
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 10

      Flickable {
        id: changelogFlickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        flickableDirection: Flickable.VerticalFlick
        interactive: true
        contentWidth: parent.width
        contentHeight: changelogContent.height
        clip: true

        Column {
          id: changelogContent
          width: parent.width
          spacing: 15

          Label {
            width: parent.width
            text: qsTr("Versión 1.2.0")
            font.bold: true
            font.pixelSize: 18
            color: Theme.mainTextColor
          }

          Label {
            width: parent.width
            text: qsTr("• Nuevas funcionalidades de mapeo\n• Mejor soporte para datos meteorológicos\n• Mejoras en la interfaz de usuario\n• Corrección de errores generales")
            wrapMode: Text.WordWrap
            color: Theme.mainTextColor
          }

          Rectangle {
            width: parent.width
            height: 1
            color: "#e0e0e0"
          }

          Label {
            width: parent.width
            text: qsTr("Versión 1.1.0")
            font.bold: true
            font.pixelSize: 18
            color: Theme.mainTextColor
          }

          Label {
            width: parent.width
            text: qsTr("• Integración con servicios de mapas externos\n• Mejora en la precisión de GPS\n• Nuevas funciones de exportación de datos\n• Optimización del rendimiento")
            wrapMode: Text.WordWrap
            color: Theme.mainTextColor
          }

          Rectangle {
            width: parent.width
            height: 1
            color: "#e0e0e0"
          }

          Label {
            width: parent.width
            text: qsTr("Versión 1.0.0")
            font.bold: true
            font.pixelSize: 18
            color: Theme.mainTextColor
          }

          Label {
            width: parent.width
            text: qsTr("• Lanzamiento inicial de SIGPACGO\n• Funcionalidades básicas de mapeo\n• Soporte para dispositivos Android e iOS\n• Recopilación de datos de campo")
            wrapMode: Text.WordWrap
            color: Theme.mainTextColor
          }
        }
      }

      QfButton {
        id: versionButton
        Layout.fillWidth: true

        text: qsTr('Versión actual: ') + appVersion
      }
    }
  }

  onClosed: {
    settings.setValue("/QField/ChangelogVersion", appVersion);
    changelogFlickable.contentY = 0;
  }
}
