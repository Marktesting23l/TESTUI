import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml

import org.qgis 1.0
import Theme 1.0
import "." as AppComponents

Dialog {
    id: cultivoDeclaradoDialog

    // Store coordinates
    property real x_coord
    property real y_coord
    property string srid: "4258"  // Default to ETRS89
    
    // Set up the service
    property var service: cultivoDeclaradoService
    
    // Property to store clipboard object
    property var clipboard: null
    
    title: qsTr("Consulta Cultivo Declarado/Expediente")
    
    width: Math.min(parent.width * 0.95, 600)
    height: Math.min(parent.height * 0.95, 800)
    
    // Center the dialog in the parent
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Custom background for the entire dialog
    background: Rectangle {
        color: Theme.mainBackgroundColor
        border.color: Theme.mainColor
        border.width: 1
        radius: 4
    }

    // Query with coordinates
    function setCoordinates(x, y) {
        x_coord = x
        y_coord = y
        
        // Clear previous data
        resultText.text = "<center><i>Consultando datos de cultivo declarado...</i></center>"
        
        // Connect signals from service
        service.dataLoaded.connect(onDataLoaded)
        service.errorOccurred.connect(onErrorOccurred)
        service.loadingChanged.connect(onLoadingChanged)
        
        // Start the query
        service.queryByCoordinates(srid, x, y)
    }
    
    // Handle data loading completion
    function onDataLoaded(data) {
        var rawText = service.formatCultivoDeclaradoData(data)
        resultText.text = formatTextWithHTML(rawText)
        busyIndicator.running = false
    }
    
    // Format text with HTML for better display
    function formatTextWithHTML(text) {
        // Replace section titles with styled headers
        var formattedText = text
            .replace(/CULTIVO DECLARADO \((\d+)\/(\d+)\):/g, '<h2 style="color:' + Theme.mainColor + '">CULTIVO DECLARADO ($1/$2)</h2>')
            .replace(/  IDENTIFICACIÓN PARCELA:/g, '<h3 style="color:' + Theme.darkGray + '">IDENTIFICACIÓN PARCELA</h3>')
            .replace(/  DATOS EXPEDIENTE:/g, '<h3 style="color:' + Theme.darkGray + '">DATOS EXPEDIENTE</h3>')
            .replace(/  CULTIVO PRINCIPAL:/g, '<h3 style="color:' + Theme.darkGray + '">CULTIVO PRINCIPAL</h3>')
            .replace(/  CULTIVO SECUNDARIO:/g, '<h3 style="color:' + Theme.darkGray + '">CULTIVO SECUNDARIO</h3>')
            .replace(/  APROVECHAMIENTO:/g, '<h3 style="color:' + Theme.darkGray + '">APROVECHAMIENTO</h3>')
            .replace(/  OTROS DATOS:/g, '<h3 style="color:' + Theme.darkGray + '">OTROS DATOS</h3>')
            .replace(/  DATOS DE SISTEMA:/g, '<h3 style="color:' + Theme.darkGray + '">DATOS DE SISTEMA</h3>')
        
        // Replace field labels with styled text
        formattedText = formattedText.replace(/    ([^:]+):/g, '    <b>$1:</b>')
        
        // Replace null/undefined/empty values with "Sin datos"
        formattedText = formattedText.replace(/    <b>([^<]+)<\/b>: (undefined|null|No disponible|$)/g, 
            '    <b>$1</b>: <span style="color:#9e9e9e;font-style:italic">Sin datos</span>')
        
        // Replace empty lines with breaks
        formattedText = formattedText.replace(/\n\n/g, '<br/>')
        
        // Convert regular linebreaks to HTML breaks
        formattedText = formattedText.replace(/\n/g, '<br/>')
        
        // Format section dividers
        formattedText = formattedText.replace(/---/g, '<hr style="border: 1px dashed ' + Theme.lightGray + '"/>')
        
        return formattedText
    }
    
    // Handle errors
    function onErrorOccurred(errorMessage) {
        resultText.text = "<div style='color: #d32f2f; padding: 20px;'><h3>Error</h3><p>" + errorMessage + "</p></div>"
        busyIndicator.running = false
    }
    
    // Handle loading status changes
    function onLoadingChanged(isLoading) {
        busyIndicator.running = isLoading
    }
    
    // Clean up signal connections when closing
    function cleanup() {
        service.dataLoaded.disconnect(onDataLoaded)
        service.errorOccurred.disconnect(onErrorOccurred)
        service.loadingChanged.disconnect(onLoadingChanged)
    }
    
    // Clean up when closed
    onClosed: {
        cleanup()
    }
    
    // Header with title and close button
    header: Rectangle {
        width: parent.width
        height: 90 // Increased height to accommodate additional text
        color: Theme.mainColor
        
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 2
            
            RowLayout {
                Layout.fillWidth: true
                
                Image {
                    source: "qrc:///images/themes/default/mIconFieldCalendar.svg"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                
                Label {
                    text: cultivoDeclaradoDialog.title
                    color: "white"
                    font.bold: true
                    font.pointSize: 12
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "×"
                    font.pointSize: 16
                    flat: true
                    
                    background: Rectangle {
                        color: "transparent"
                        implicitWidth: 30
                        implicitHeight: 30
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        cultivoDeclaradoDialog.close()
                    }
                }
            }
            
            Label {
                text: "<a href='https://www.fega.gob.es/es'>Consultas servidores FEGA Cultivos Declarados/Expediente 2024</a>"
                color: "white"
                opacity: 0.9
                font.pointSize: 10
                Layout.fillWidth: true
                
                onLinkActivated: function(link) {
                    Qt.openUrlExternally(link)
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton // Don't eat the mouse clicks
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
            
            Label {
                text: "Consulta de datos online del FEGA campaña 2024 (datos de comunidades pueden variar dependiendo de cuando se los manden al FEGA)"
                color: "white"
                opacity: 0.8
                font.pointSize: 9
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                wrapMode: Text.Wrap
                elide: Text.ElideRight
            }
        }
    }
    
    // Content area
    contentItem: ColumnLayout {
        spacing: 10
        
        // Coordinates display panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: Theme.lightGray
            radius: 4
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                
                Image {
                    source: "qrc:///images/themes/default/mActionPan.svg"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                
                Label {
                    Layout.fillWidth: true
                    text: "Coordenadas: SRID=" + srid + ", X=" + x_coord.toFixed(6) + ", Y=" + y_coord.toFixed(6)
                    font.pointSize: 10
                    wrapMode: Text.Wrap
                }
            }
        }
        
        // Main content area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            border.color: Theme.lightGray
            border.width: 1
            radius: 4
            
            // Busy indicator while loading
            BusyIndicator {
                id: busyIndicator
                running: true
                anchors.centerIn: parent
                width: 50
                height: 50
                visible: running
            }
            
            // Content scrollable area
            Flickable {
                id: flickable
                anchors.fill: parent
                anchors.margins: 12
                contentWidth: resultContainer.width
                contentHeight: resultContainer.height
                clip: true
                
                // Container for the result text
                Item {
                    id: resultContainer
                    width: flickable.width
                    height: Math.max(resultText.height, flickable.height)
                    
                    // Text display
                    Text {
                        id: resultText
                        width: parent.width
                        text: "<center><i>Consultando datos de cultivo declarado...</i></center>"
                        wrapMode: Text.Wrap
                        textFormat: Text.RichText
                        font.pointSize: 10
                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    interactive: true
                    
                    background: Rectangle {
                        implicitWidth: 8
                        color: "transparent"
                    }
                    
                    contentItem: Rectangle {
                        implicitWidth: 6
                        implicitHeight: 100
                        radius: width / 2
                        color: parent.pressed ? Theme.mainColor : Theme.lightGray
                    }
                }
            }
        }
    }
    
    // Footer with action buttons
    footer: Rectangle {
        width: parent.width
        height: 60
        color: "transparent"
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            
            Item {
                Layout.fillWidth: true
            }
            
            Button {
                id: copyButton
                text: "Copiar"
                icon.source: "qrc:///images/themes/default/mActionEditCopy.svg"
                
                background: Rectangle {
                    implicitWidth: 100
                    implicitHeight: 32
                    color: parent.hovered ? Theme.lightGray : Theme.mainColor
                    radius: 4
                }
                
                contentItem: Text {
                    text: copyButton.text
                    font: Theme.tipFont || Font.font
                    color: Theme.buttonTextColor || "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (cultivoDeclaradoDialog.clipboard) {
                        cultivoDeclaradoDialog.clipboard.setText(resultText.text.replace(/<[^>]*>/g, ''))
                    } else {
                        console.error("Clipboard object not available")
                    }
                }
            }
            
            Button {
                id: closeButton
                text: "Cerrar"
                
                background: Rectangle {
                    implicitWidth: 100
                    implicitHeight: 32
                    color: parent.hovered ? Theme.lightGray : Theme.mainColor
                    radius: 4
                }
                
                contentItem: Text {
                    text: closeButton.text
                    font: Theme.tipFont || Font.font
                    color: Theme.buttonTextColor || "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    cultivoDeclaradoDialog.close()
                }
            }
        }
    }
    
    // Create the necessary components when the dialog is created
    Component.onCompleted: {
        // Create a clipboard object for the copy button
        var clipboardComponent = Qt.createQmlObject(
            'import QtQuick; QtObject { function setText(text) { } }',
            cultivoDeclaradoDialog,
            "DynamicClipboard"
        );
        cultivoDeclaradoDialog.clipboard = clipboardComponent;
    }
    
    // Clean up when destroyed
    Component.onDestruction: {
        cleanup()
    }
} 