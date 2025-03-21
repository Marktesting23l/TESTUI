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

  // Function to show the welcome guide
  function showWelcomeGuide() {
    var welcomeGuideDialog = welcomeGuideComponent.createObject(informationPanel)
    welcomeGuideDialog.open()
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

  // Component for welcome guide
  Component {
    id: welcomeGuideComponent
    
    Dialog {
      id: welcomeGuideDialog
      title: qsTr("Guía de Inicio - SIGPACGO")
      modal: true
      width: Math.min(parent.width * 0.95, 700)
      height: Math.min(parent.height * 0.9, 900)
      anchors.centerIn: parent
      standardButtons: Dialog.Close
      
      contentItem: ScrollView {
        id: guideScrollView
        clip: true
        ScrollBar.vertical: ScrollBar {}
        contentWidth: guideContent.width
        
        Item {
          width: guideScrollView.width - 20 // Adjusted width to prevent horizontal scrolling
          implicitHeight: guideContent.height + 20
          
          Column {
            id: guideContent
            width: parent.width
            spacing: 20
            padding: 10
            
            Image {
              source: "qrc:/images/sigpacgo_logo.svg"
              width: 150
              height: 150
              fillMode: Image.PreserveAspectFit
              anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
              width: parent.width - 20
              text: qsTr("Bienvenido a SIGPACGO")
              font.pixelSize: 28
              font.bold: true
              color: Theme.darkTheme ? "white" : "#333333"
              horizontalAlignment: Text.AlignHCenter
            }
            
            // Introduction
            Rectangle {
              width: parent.width - 20
              height: introText.height + 30
              color: Theme.mainColor
              radius: 8
              
              Text {
                id: introText
                width: parent.width - 20
                anchors.centerIn: parent
                text: qsTr("Esta guía te ayudará a familiarizarte con las principales funciones de SIGPACGO y comenzar a utilizar la aplicación de manera efectiva en tus trabajos de campo.")
                font.pixelSize: 16
                color: "white"
                wrapMode: Text.WordWrap
              }
            }
            
            // Features section with images
            SectionTitle { text: qsTr("Principales Características") }
            
            // Map Navigation
            FeatureItem {
              title: qsTr("1. Navegación del Mapa")
              description: qsTr("• Desplázate por el mapa con gestos de deslizamiento.\n• Amplía y reduce con gestos de pellizco o botones de zoom.\n• Pulsa sobre una parcela para ver su información detallada.\n• Activa tu ubicación GPS para centrarte en tu posición actual.")
              iconSource: Theme.getThemeVectorIcon("ic_map_white_24dp")
            }
            
            // Data Collection
            FeatureItem {
              title: qsTr("2. Captura de Datos")
              description: qsTr("• Toma fotos georeferenciadas con la cámara integrada.\n• Anota observaciones sobre parcelas y cultivos.\n• Marca puntos de interés y registra incidencias.\n• Dibuja sobre las fotos para destacar detalles importantes.")
              iconSource: Theme.getThemeVectorIcon("ic_photo_camera_white_24dp")
            }
            
            // Offline Functionality
            FeatureItem {
              title: qsTr("3. Funcionamiento Sin Conexión")
              description: qsTr("• Descarga mapas y datos antes de salir al campo.\n• Trabaja sin necesidad de conexión a internet.\n• Los datos se sincronizan automáticamente cuando recuperes conexión.\n• Ahorra batería y datos móviles.")
              iconSource: Theme.getThemeVectorIcon("ic_cloud_off_white_24dp")
            }
            
            // Measurements
            FeatureItem {
              title: qsTr("4. Mediciones")
              description: qsTr("• Calcula distancias entre puntos en el terreno.\n• Mide áreas y perímetros de parcelas.\n• Estima superficies cultivadas y linderos.\n• Exporta los datos para su posterior análisis.")
              iconSource: Theme.getThemeVectorIcon("ic_straighten_white_24dp")
            }
            
            // Weather Information
            FeatureItem {
              title: qsTr("5. Información Meteorológica")
              description: qsTr("• Consulta datos meteorológicos actuales.\n• Ve pronósticos para planificar tus visitas.\n• Registra condiciones climáticas durante inspecciones.\n• Establece alertas de condiciones adversas.")
              iconSource: Theme.getThemeVectorIcon("ic_wb_sunny_white_24dp")
            }
            
            // Quick Start Guide
            SectionTitle { text: qsTr("Primeros Pasos") }
            
            // Step 1
            StepItem {
              number: "1"
              title: qsTr("Configuración Inicial")
              description: qsTr("Al iniciar la aplicación por primera vez, se te pedirán permisos para acceder a tu ubicación, almacenamiento y cámara. Estos son necesarios para el correcto funcionamiento de SIGPACGO.")
            }
            
            // Step 2
            StepItem {
              number: "2"
              title: qsTr("Cargar Mapas")
              description: qsTr("Antes de ir al campo, asegúrate de descargar los mapas del área que vas a visitar. Ve a Configuración > Datos Sin Conexión y selecciona tu región de interés.")
            }
            
            // Step 3
            StepItem {
              number: "3"
              title: qsTr("Iniciar un Proyecto")
              description: qsTr("Crea un nuevo proyecto para cada visita o área. Esto te ayudará a organizar tus datos. Ve a Inicio > Nuevo Proyecto y completa la información requerida.")
            }
            
            // Step 4
            StepItem {
              number: "4"
              title: qsTr("Tomar Fotos")
              description: qsTr("Usa la cámara integrada (botón de cámara en la barra inferior) para capturar fotos georeferenciadas. Puedes añadir anotaciones y dibujar sobre las fotos para destacar detalles importantes.")
            }
            
            // Step 5
            StepItem {
              number: "5"
              title: qsTr("Sincronización")
              description: qsTr("Al finalizar tu trabajo de campo, conecta tu dispositivo a Internet para sincronizar los datos recogidos con el servidor. Ve a Configuración > Sincronización para verificar el estado.")
            }
            
            // Tips and Warnings
            SectionTitle { text: qsTr("Consejos y Advertencias") }
            
            // Battery Saving
            TipWarningItem {
              type: "tip"
              title: qsTr("Ahorro de Batería")
              description: qsTr("La aplicación puede consumir batería rápidamente cuando el GPS está activo. Para optimizar el uso de batería, activa el modo de ahorro en Configuración > Rendimiento.")
            }
            
            // Data Accuracy
            TipWarningItem {
              type: "warning"
              title: qsTr("Precisión de Datos")
              description: qsTr("La precisión del GPS puede variar según el dispositivo y la cobertura. Asegúrate de verificar el indicador de precisión antes de tomar medidas importantes.")
            }
            
            // Data Backup
            TipWarningItem {
              type: "tip"
              title: qsTr("Copia de Seguridad")
              description: qsTr("Realiza copias de seguridad periódicas de tus proyectos. Ve a Configuración > Copias de Seguridad para exportar tus datos a un archivo externo.")
            }
            
            // Internet Connection
            TipWarningItem {
              type: "warning"
              title: qsTr("Conexión a Internet")
              description: qsTr("Aunque SIGPACGO funciona sin conexión, algunas funciones como la sincronización y actualización de mapas requieren conectividad. Planifica tu trabajo en consecuencia.")
            }
            
            // Weather Conditions
            TipWarningItem {
              type: "tip"
              title: qsTr("Condiciones Meteorológicas")
              description: qsTr("Consulta el pronóstico del tiempo antes de salir al campo. Las condiciones meteorológicas adversas pueden afectar la precisión de los datos y la calidad de las fotos.")
            }
            
            // Additional Resources
            SectionTitle { text: qsTr("Recursos Adicionales") }
            
            Text {
              width: parent.width - 20
              text: qsTr("Para obtener más información sobre SIGPACGO, visita nuestro sitio web en www.sigpacgo.com o contacta con nuestro equipo de soporte en support@sigpacgo.com.")
              font.pixelSize: 16
              color: Theme.darkTheme ? "white" : "#333333"
              wrapMode: Text.WordWrap
            }
            
            Item {
              width: parent.width
              height: 40
            }
          }
        }
      }
    }
  }
  
  // Component for section titles in the guide
  component SectionTitle: Item {
    width: parent.width - 20
    height: 50
    property alias text: titleText.text
    
    Rectangle {
      anchors.fill: parent
      color: "#80" + Theme.mainColor.toString().substr(1)
      radius: 8
    }
    
    Text {
      id: titleText
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 15
      font.pixelSize: 22
      font.bold: true
      color: Theme.darkTheme ? "white" : "#333333"
    }
  }
  
  // Component for feature items with icons
  component FeatureItem: Rectangle {
    width: parent.width - 20
    height: featureColumn.height + 30
    color: Theme.darkTheme ? "#333333" : "#f5f5f5"
    radius: 8
    property string title
    property string description
    property string iconSource
    
    Row {
      anchors.fill: parent
      anchors.margins: 15
      spacing: 15
      
      Rectangle {
        width: 50
        height: 50
        radius: 25
        color: Theme.mainColor
        anchors.verticalCenter: parent.verticalCenter
        
        Image {
          anchors.centerIn: parent
          source: iconSource
          width: 30
          height: 30
          fillMode: Image.PreserveAspectFit
        }
      }
      
      Column {
        id: featureColumn
        width: parent.width - 80
        spacing: 10
        
        Text {
          width: parent.width
          text: title
          font.pixelSize: 18
          font.bold: true
          color: Theme.darkTheme ? "white" : "#333333"
        }
        
        Text {
          width: parent.width
          text: description
          font.pixelSize: 14
          color: Theme.darkTheme ? "#cccccc" : "#555555"
          wrapMode: Text.WordWrap
        }
      }
    }
  }
  
  // Component for step items
  component StepItem: Rectangle {
    width: parent.width - 20
    height: stepColumn.height + 30
    color: Theme.darkTheme ? "#333333" : "#f5f5f5"
    radius: 8
    property string number
    property string title
    property string description
    
    Row {
      anchors.fill: parent
      anchors.margins: 15
      spacing: 15
      
      Rectangle {
        width: 40
        height: 40
        radius: 20
        color: Theme.mainColor
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
          anchors.centerIn: parent
          text: number
          font.pixelSize: 20
          font.bold: true
          color: "white"
        }
      }
      
      Column {
        id: stepColumn
        width: parent.width - 70
        spacing: 10
        
        Text {
          width: parent.width
          text: title
          font.pixelSize: 18
          font.bold: true
          color: Theme.darkTheme ? "white" : "#333333"
        }
        
        Text {
          width: parent.width
          text: description
          font.pixelSize: 14
          color: Theme.darkTheme ? "#cccccc" : "#555555"
          wrapMode: Text.WordWrap
        }
      }
    }
  }
  
  // Component for tips and warnings
  component TipWarningItem: Rectangle {
    width: parent.width - 20
    height: itemColumn.height + 30
    color: type === "tip" ? (Theme.darkTheme ? "#1B5E20" : "#E8F5E9") : (Theme.darkTheme ? "#B71C1C" : "#FFEBEE")
    radius: 8
    property string type // "tip" or "warning"
    property string title
    property string description
    
    Row {
      anchors.fill: parent
      anchors.margins: 15
      spacing: 15
      
      Rectangle {
        width: 40
        height: 40
        radius: 20
        color: "transparent"
        border.width: 2
        border.color: type === "tip" ? "#4CAF50" : "#F44336"
        anchors.verticalCenter: parent.verticalCenter
        
        Text {
          anchors.centerIn: parent
          text: type === "tip" ? "✓" : "!"
          font.pixelSize: 20
          font.bold: true
          color: type === "tip" ? "#4CAF50" : "#F44336"
        }
      }
      
      Column {
        id: itemColumn
        width: parent.width - 70
        spacing: 10
        
        Text {
          width: parent.width
          text: title
          font.pixelSize: 18
          font.bold: true
          color: type === "tip" ? 
                 (Theme.darkTheme ? "#81C784" : "#2E7D32") : 
                 (Theme.darkTheme ? "#EF9A9A" : "#C62828")
        }
        
        Text {
          width: parent.width
          text: description
          font.pixelSize: 14
          color: type === "tip" ? 
                 (Theme.darkTheme ? "#A5D6A7" : "#1B5E20") : 
                 (Theme.darkTheme ? "#FFCDD2" : "#B71C1C")
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  // Component for troubleshooting guide
  Component {
    id: troubleshootingGuideComponent
    
    Dialog {
      id: troubleshootingDialog
      title: qsTr("Solución de Problemas")
      modal: true
      width: Math.min(parent.width * 0.95, 700)
      height: Math.min(parent.height * 0.9, 900)
      anchors.centerIn: parent
      standardButtons: Dialog.Close
      
      contentItem: ScrollView {
        id: troubleScrollView
        clip: true
        ScrollBar.vertical: ScrollBar {}
        contentWidth: troubleContent.width
        
        Item {
          width: troubleScrollView.width - 20
          implicitHeight: troubleContent.height + 20
          
          Column {
            id: troubleContent
            width: parent.width
            spacing: 20
            padding: 10
            
            Text {
              width: parent.width - 20
              text: qsTr("Guía de Solución de Problemas")
              font.pixelSize: 28
              font.bold: true
              color: Theme.darkTheme ? "white" : "#333333"
              horizontalAlignment: Text.AlignHCenter
            }
            
            // Introduction
            Rectangle {
              width: parent.width - 20
              height: troubleIntroText.height + 30
              color: Theme.mainColor
              radius: 8
              
              Text {
                id: troubleIntroText
                width: parent.width - 20
                anchors.centerIn: parent
                text: qsTr("Esta guía te ayudará a resolver los problemas más comunes que pueden surgir al utilizar SIGPACGO.")
                font.pixelSize: 16
                color: "white"
                wrapMode: Text.WordWrap
              }
            }
            
            // Common problems section
            SectionTitle { text: qsTr("Problemas comunes") }
            
            // GPS problems
            ProblemItem {
              title: qsTr("Problemas con la señal GPS")
              problem: qsTr("La aplicación no detecta mi ubicación o la precisión es muy baja.")
              solution: qsTr("• Verifica que el GPS está activado en tu dispositivo.\n• Sal al exterior o acércate a una ventana para mejorar la recepción.\n• Reinicia el GPS o tu dispositivo.\n• Comprueba que has dado permisos de ubicación a la aplicación.\n• Espera unos minutos para que el GPS adquiera buena señal.")
            }
            
            // Map loading problems
            ProblemItem {
              title: qsTr("Los mapas no cargan correctamente")
              problem: qsTr("Los mapas aparecen en blanco o no se cargan completamente.")
              solution: qsTr("• Verifica tu conexión a internet.\n• Intenta actualizar los mapas en Configuración > Mapas.\n• Limpia la caché en Configuración > Almacenamiento > Limpiar caché.\n• Descarga los mapas para uso offline antes de salir al campo.\n• Reinicia la aplicación.")
            }
            
            // Photo capture problems
            ProblemItem {
              title: qsTr("Problemas al capturar fotos")
              problem: qsTr("No puedo tomar fotos o la aplicación se cierra al intentarlo.")
              solution: qsTr("• Verifica que has concedido permiso de cámara a la aplicación.\n• Comprueba el espacio disponible en tu dispositivo.\n• Cierra otras aplicaciones para liberar memoria.\n• Si la cámara no responde, reinicia tu dispositivo.\n• Asegúrate de que la cámara no esté siendo utilizada por otra aplicación.")
            }
            
            // Synchronization problems
            ProblemItem {
              title: qsTr("Errores de sincronización")
              problem: qsTr("Los datos no se sincronizan correctamente con el servidor.")
              solution: qsTr("• Verifica que tienes conexión a internet estable.\n• Comprueba tus credenciales de usuario.\n• Verifica que el tamaño de los archivos no excede el límite permitido.\n• Intenta sincronizar archivos uno por uno en lugar de todos a la vez.\n• Contacta con soporte si persiste el problema.")
            }
            
            // App crashes
            ProblemItem {
              title: qsTr("La aplicación se cierra inesperadamente")
              problem: qsTr("SIGPACGO se cierra sin previo aviso durante su uso.")
              solution: qsTr("• Actualiza a la última versión de la aplicación.\n• Reinicia tu dispositivo.\n• Verifica que tienes suficiente espacio de almacenamiento.\n• Comprueba si hay actualizaciones pendientes del sistema operativo.\n• Desinstala y vuelve a instalar la aplicación como último recurso.")
            }
            
            // Battery problems
            ProblemItem {
              title: qsTr("Consumo excesivo de batería")
              problem: qsTr("La aplicación consume demasiada batería durante su uso.")
              solution: qsTr("• Activa el modo de ahorro de energía en Configuración > Rendimiento.\n• Reduce la frecuencia de actualización del GPS.\n• Baja el brillo de la pantalla.\n• Cierra la aplicación cuando no la uses.\n• Desactiva la sincronización automática cuando estés en campo.")
            }
            
            // Contact support section
            SectionTitle { text: qsTr("¿Necesitas más ayuda?") }
            
            Text {
              width: parent.width - 20
              text: qsTr("Si sigues experimentando problemas, contacta con nuestro equipo de soporte en support@sigpacgo.com o visita la sección de soporte en www.sigpacgo.com/soporte")
              font.pixelSize: 16
              color: Theme.darkTheme ? "white" : "#333333"
              wrapMode: Text.WordWrap
            }
            
            Item {
              width: parent.width
              height: 40
            }
          }
        }
      }
    }
  }
  
  // Component for problem items in troubleshooting guide
  component ProblemItem: Rectangle {
    width: parent.width - 20
    height: problemColumn.height + 30
    color: Theme.darkTheme ? "#333333" : "#f5f5f5"
    radius: 8
    property string title
    property string problem
    property string solution
    
    Column {
      id: problemColumn
      width: parent.width - 30
      anchors.centerIn: parent
      spacing: 10
      
      Text {
        width: parent.width
        text: title
        font.pixelSize: 18
        font.bold: true
        color: Theme.darkTheme ? "white" : "#333333"
      }
      
      Rectangle {
        width: parent.width
        height: 2
        color: Theme.mainColor
        opacity: 0.7
      }
      
      Text {
        width: parent.width
        text: qsTr("Problema: ") + problem
        font.pixelSize: 16
        font.italic: true
        color: Theme.darkTheme ? "#cccccc" : "#555555"
        wrapMode: Text.WordWrap
      }
      
      Text {
        width: parent.width
        text: qsTr("Solución:")
        font.pixelSize: 16
        font.bold: true
        color: Theme.darkTheme ? "#cccccc" : "#555555"
        wrapMode: Text.WordWrap
      }
      
      Text {
        width: parent.width
        text: solution
        font.pixelSize: 16
        color: Theme.darkTheme ? "#cccccc" : "#555555"
        wrapMode: Text.WordWrap
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
              if (modelData.title === "Guía de Inicio") {
                showWelcomeGuide()
              } else if (modelData.title === "Solución de Problemas") {
                var troubleshootingDialog = troubleshootingGuideComponent.createObject(informationPanel)
                troubleshootingDialog.open()
              } else {
                try {
                  openPdfDocument(modelData.url)
                } catch (e) {
                  displayToast(modelData.content, "info")
                }
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