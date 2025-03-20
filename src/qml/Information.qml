import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import Theme
import Qt.labs.platform as Platform

/**
 * \ingroup qml
 */
Item {
  id: informationPanel

  visible: false
  focus: visible

  // Function to handle PDF files - checks if file exists and either opens it or shows a toast
  function openPdfDocument(pdfName) {
    var pdfPath = Qt.resolvedUrl("../../docs/" + pdfName)
    var fileInfo = Qt.createQmlObject('import Qt.labs.platform 1.1; FileInfo { url: "' + pdfPath + '" }', informationPanel)
    
    if (fileInfo.exists) {
      Qt.openUrlExternally(pdfPath)
    } else {
      displayToast(qsTr("El documento %1 no está disponible actualmente").arg(pdfName), "warning")
    }
  }

  // Function to open external URLs
  function openExternalUrl(url) {
    Qt.openUrlExternally(url)
  }

  // Function to show license text
  function showLicenseText() {
    var licenseDialog = licenseDialogComponent.createObject(informationPanel)
    licenseDialog.open()
  }

  // Component for license dialog
  Component {
    id: licenseDialogComponent
    
    Dialog {
      id: licenseDialog
      title: qsTr("Licencia GNU GPL v2.0")
      modal: true
      width: Math.min(parent.width * 0.9, 600)
      height: Math.min(parent.height * 0.8, 800)
      anchors.centerIn: parent
      standardButtons: Dialog.Close
      
      contentItem: ScrollView {
        clip: true
        ScrollBar.vertical: ScrollBar {}
        
        TextArea {
          id: licenseTextArea
          readOnly: true
          wrapMode: TextEdit.Wrap
          textFormat: TextEdit.PlainText
          
          Component.onCompleted: {
            var xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function() {
              if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                  licenseTextArea.text = xhr.responseText;
                } else {
                  licenseTextArea.text = qsTr("No se pudo cargar el texto de la licencia. Por favor, consulte el archivo LICENSE en la carpeta principal.");
                }
              }
            }
            xhr.open("GET", "file:///home/im/Documents/SIGPACGOEDITS/TESTUI-master/LICENSE");
            xhr.send();
          }
        }
      }
    }
  }

  Rectangle {
    color: "black"
    opacity: 0.9
    anchors.fill: parent
  }

  ScrollView {
    id: mainScrollView
    anchors.fill: parent
    anchors.margins: 20
    anchors.topMargin: 20 + mainWindow.sceneTopMargin
    anchors.bottomMargin: 20 + mainWindow.sceneBottomMargin
    clip: true
    ScrollBar.vertical: QfScrollBar {}
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    
    contentWidth: informationContent.width
    contentHeight: informationContent.height

    Column {
      id: informationContent
      width: mainScrollView.width
      spacing: 15

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

      Button {
        width: parent.width
        height: 50
        text: qsTr("¿Qué es SIGPAC-Go?")
        
        contentItem: Text {
          text: parent.text
          font.pixelSize: 20
          font.bold: true
          color: "white"
          horizontalAlignment: Text.AlignLeft
          verticalAlignment: Text.AlignVCenter
        }
        
        background: Rectangle {
          color: parent.down ? "#33ffffff" : "transparent"
          radius: 4
        }
        
        onClicked: {
          displayToast(qsTr("SIGPAC-Go es una aplicación móvil diseñada para facilitar el acceso y la consulta de información del Sistema de Información Geográfica de Parcelas Agrícolas directamente en el campo."), "info")
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: "#555555"
      }

      Button {
        width: parent.width
        height: 50
        text: qsTr("Objeto de esta APP: Del campo para el campo")
        
        contentItem: Text {
          text: parent.text
          font.pixelSize: 20
          font.bold: true
          color: "white"
          horizontalAlignment: Text.AlignLeft
          verticalAlignment: Text.AlignVCenter
        }
        
        background: Rectangle {
          color: parent.down ? "#33ffffff" : "transparent"
          radius: 4
        }
        
        onClicked: {
          displayToast(qsTr("SIGPAC-Go ha sido desarrollada con un enfoque práctico orientado al trabajo en campo. Permite consultar información parcelaria, realizar mediciones y recopilar datos sin conexión a internet."), "info")
        }
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

      Column {
        width: parent.width
        spacing: 5

        Repeater {
          model: [
            { title: "Guía de Inicio", url: "getting_started.pdf", content: "Esta guía ofrece información básica para comenzar a utilizar SIGPAC-Go." },
            { title: "Recolección de Datos de Campo", url: "field_data.pdf", content: "Aprenda a recolectar y gestionar datos durante sus visitas a campo." },
            { title: "Uso de Datos Meteorológicos", url: "weather_data.pdf", content: "Cómo acceder y utilizar información meteorológica en la aplicación." },
            { title: "Solución de Problemas", url: "troubleshooting.pdf", content: "Soluciones a problemas comunes que pueden surgir al utilizar la aplicación." }
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
              try {
                openPdfDocument(modelData.url)
              } catch (e) {
                displayToast(modelData.content, "info")
              }
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
        text: qsTr("Enlaces de interés")
        font.pixelSize: 20
        font.bold: true
        color: "white"
        wrapMode: Text.WordWrap
      }

      Column {
        width: parent.width
        spacing: 5

        Repeater {
          model: [
            { title: "Portal SIGPAC Oficial", url: "https://sigpac.mapama.gob.es/" },
            { title: "Ministerio de Agricultura, Pesca y Alimentación", url: "https://www.mapa.gob.es/" },
            { title: "Información PAC", url: "https://www.fega.es/" },
            { title: "Ayudas y Subvenciones Agrarias", url: "https://www.mapa.gob.es/es/agricultura/ayudas/" }
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
              openExternalUrl(modelData.url)
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

      Rectangle {
        width: parent.width
        height: 1
        color: "#555555"
      }

      Label {
        width: parent.width
        text: qsTr("Términos de uso")
        font.pixelSize: 20
        font.bold: true
        color: "white"
        wrapMode: Text.WordWrap
      }

      Label {
        width: parent.width
        text: qsTr("Al utilizar SIGPAC-Go, usted acepta cumplir con nuestros términos y condiciones. La aplicación se proporciona 'tal cual', sin garantías de ningún tipo. Los datos mostrados son de carácter informativo y no constituyen documentación oficial. El usuario es responsable de verificar la información con las fuentes oficiales antes de tomar decisiones basadas en los datos proporcionados por esta aplicación.")
        font.pixelSize: 16
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
        text: qsTr("Licencia")
        font.pixelSize: 20
        font.bold: true
        color: "white"
        wrapMode: Text.WordWrap
      }

      Label {
        width: parent.width
        text: qsTr("SIGPAC-Go se distribuye bajo la licencia GNU General Public License v2.0. Esto significa que puede utilizar, modificar y distribuir el software libremente, siempre que cualquier trabajo derivado también se distribuya bajo los mismos términos. El código fuente está disponible públicamente y las contribuciones son bienvenidas.")
        font.pixelSize: 16
        color: "white"
        wrapMode: Text.WordWrap
      }

      Button {
        text: qsTr("Ver texto completo de la licencia")
        anchors.horizontalCenter: parent.horizontalCenter
        height: 40
        
        contentItem: Text {
          text: parent.text
          font: parent.font
          color: Theme.mainColor
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
        
        background: Rectangle {
          color: parent.down ? "#33ffffff" : "#22ffffff"
          radius: 4
        }
        
        onClicked: {
          showLicenseText()
        }
      }

      Label {
        width: parent.width
        text: qsTr("Los datos geográficos utilizados están sujetos a sus propias licencias y términos de uso proporcionados por las entidades oficiales correspondientes.")
        font.pixelSize: 16
        color: "white"
        wrapMode: Text.WordWrap
      }
      
      Item {
        width: parent.width
        height: 20
      }
    }
  }
  
  Rectangle {
    id: closeButton
    width: 40
    height: 40
    radius: 20
    color: "#aa000000"
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 15
    anchors.topMargin: 15 + mainWindow.sceneTopMargin
    z: 10
    
    Text {
      anchors.centerIn: parent
      text: "✕"
      color: "white"
      font.pixelSize: 20
    }
    
    MouseArea {
      anchors.fill: parent
      onClicked: informationPanel.visible = false
    }
  }
} 