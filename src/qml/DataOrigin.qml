import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.qgis 1.0
import org.qfield 1.0
import Theme 1.0

/**
 * \ingroup qml
 */
Item {
    id: dataOriginPanel

    visible: false
    focus: visible

    Rectangle {
        color: "black"
        opacity: 0.9
        anchors.fill: parent
    }

    ColumnLayout {
        id: dataOriginContainer
        spacing: 6
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: 20 + mainWindow.sceneTopMargin
        anchors.bottomMargin: 20 + mainWindow.sceneBottomMargin

        Row {
            Layout.fillWidth: true
            height: 50
            
            Text {
                text: qsTr("Origen de los datos")
                color: "white"
                font.pixelSize: 24
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Item {
                width: parent.width - closeButton.width - parent.children[0].width
                height: 1
            }
            
            QfToolButton {
                id: closeButton
                round: true
                bgcolor: Theme.darkGray
                iconSource: Theme.getThemeIcon("ic_close_white_24dp")
                anchors.verticalCenter: parent.verticalCenter
                
                onClicked: dataOriginPanel.visible = false
            }
        }

        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: contentItem.width
            clip: true
            
            ScrollBar.vertical: QfScrollBar {
                policy: ScrollBar.AlwaysOn
                visible: scrollView.contentHeight > scrollView.height
                active: visible
            }
            
            Flickable {
                id: flickable
                anchors.fill: parent
                contentWidth: dataOriginContent.width
                contentHeight: dataOriginContent.height
                boundsBehavior: Flickable.StopAtBounds
                
                Column {
                    id: dataOriginContent
                    width: scrollView.width - 25 // Make room for scrollbar
                    spacing: 15
                    
                    // Open Data Usage Header
                    Rectangle {
                        width: parent.width
                        color: "#004a7f"
                        radius: 5
                        height: openDataColumn.height + 20
                        
                        Column {
                            id: openDataColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Uso de datos abiertos a disposición de la ciudadanía")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Agradecimientos a las instituciones que proporcionan datos de alto valor con acceso libre.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
            
                    Label {
                        width: parent.width
                        text: qsTr("SIGPACGO utiliza datos procedentes de las siguientes fuentes oficiales:")
                        color: "white"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 18
                    }
                    
                    // SIGPAC Data Source Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: sigpacColumn.height + 20
                        
                        Column {
                            id: sigpacColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("SIGPAC - Sistema de Información Geográfica de Parcelas Agrícolas")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Los datos geográficos de parcelas provienen del SIGPAC, gestionado por el Fondo Español de Garantía Agraria (FEGA) y las Comunidades Autónomas.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuente: <a href='https://sigpac.mapama.gob.es/'>SIGPAC Nacional</a> y <a href='https://ws128.juntadeandalucia.es/agriculturaypesca/sigpac/'>SIGPAC Junta Andalucía</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Uso oficial: La información contenida en el SIGPAC carece de carácter legal y no puede utilizarse con fines catastrales.")
                                color: "#cccccc"
                                wrapMode: Text.WordWrap
                                font.italic: true
                            }
                        }
                    }
                    
                    // Catastro Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: catastroColumn.height + 20
                        
                        Column {
                            id: catastroColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Catastro de España")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Información catastral proporcionada por la Dirección General del Catastro, Ministerio de Hacienda.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuente: <a href='https://www.sedecatastro.gob.es/'>Sede Electrónica del Catastro</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                        }
                    }
                    
                    // Ministerio de Agricultura Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: agricultureColumn.height + 20
                        
                        Column {
                            id: agricultureColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Capas WMS del Ministerio de Agricultura")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Servicios de mapas web (WMS) proporcionados por el Ministerio de Agricultura, Pesca y Alimentación.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuente: <a href='https://www.mapa.gob.es/es/cartografia-y-sig/'>Portal de Cartografía y SIG</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                        }
                    }
                    
                    // Ministerio Transición Ecológica Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: ecologicaColumn.height + 20
                        
                        Column {
                            id: ecologicaColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Ministerio para la Transición Ecológica y el Reto Demográfico")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Datos ambientales y geográficos proporcionados por el Ministerio para la Transición Ecológica.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuente: <a href='https://www.miteco.gob.es/es/cartografia-y-sig/'>Portal SIG del MITECO</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                        }
                    }
                    
                    // IGN Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: ignColumn.height + 20
                        
                        Column {
                            id: ignColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Instituto Geográfico Nacional")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Cartografía básica y datos topográficos proporcionados por el IGN.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuente: <a href='https://www.ign.es/'>Instituto Geográfico Nacional</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                        }
                    }
                    
                    // IECA Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: iecaColumn.height + 20
                        
                        Column {
                            id: iecaColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Instituto de Estadística y Cartografía de Andalucía")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Datos estadísticos y cartográficos específicos de la región de Andalucía.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuente: <a href='https://www.juntadeandalucia.es/institutodeestadisticaycartografia/'>IECA</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                        }
                    }
                    
                    // Weather Data Source Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: weatherColumn.height + 20
                        
                        Column {
                            id: weatherColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Datos meteorológicos")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Los datos meteorológicos provienen de la Red de Información Agroclimática (RIA) de la Junta de Andalucía y del servicio Open-Meteo.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuentes: <a href='https://www.juntadeandalucia.es/agriculturaypesca/ifapa/riaweb/'>RIA - IFAPA</a> y <a href='https://open-meteo.com/'>Open-Meteo</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Estos datos se utilizan únicamente con fines informativos y no son determinantes para tomar decisiones oficiales.")
                                color: "#cccccc"
                                wrapMode: Text.WordWrap
                                font.italic: true
                            }
                        }
                    }
                    
                    // Sentinel Data Source Section
                    Rectangle {
                        width: parent.width
                        color: "#333333"
                        radius: 5
                        height: sentinelColumn.height + 20
                        
                        Column {
                            id: sentinelColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Imágenes satelitales")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Las imágenes satelitales proceden del programa Copernicus de la Unión Europea, principalmente a través de los satélites Sentinel.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("Fuente: <a href='https://www.copernicus.eu/es'>Programa Copernicus</a> / <a href='https://www.sentinel-hub.com/'>Sentinel Hub</a>")
                                color: "#80c0ff"
                                wrapMode: Text.WordWrap
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("© Copernicus data / Sentinel Hub")
                                color: "#cccccc"
                                wrapMode: Text.WordWrap
                                font.italic: true
                            }
                        }
                    }
                    
                    // Legal Disclaimer
                    Rectangle {
                        width: parent.width
                        color: Theme.errorColor
                        opacity: 0.8
                        radius: 5
                        height: disclaimerColumn.height + 20
                        
                        Column {
                            id: disclaimerColumn
                            width: parent.width - 20
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                width: parent.width
                                text: qsTr("Aviso legal")
                                font.bold: true
                                font.pixelSize: 18
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                            
                            Label {
                                width: parent.width
                                text: qsTr("SIGPACGO es una herramienta de apoyo para la gestión agrícola. La información proporcionada no tiene carácter oficial y no puede utilizarse para trámites administrativos. El usuario debe verificar siempre la información con las fuentes oficiales antes de tomar decisiones administrativas o legales.")
                                color: "white"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                    
                    // Spacer at the bottom to ensure content can be scrolled fully
                    Item {
                        width: parent.width
                        height: 20
                    }
                }
            }
        }
    }
} 