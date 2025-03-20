import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml
import Theme

Dialog {
    id: sigpacDialog
    title: qsTr("Información de Parcela SIGPAC")
    
    // Properties to store the current map position
    property double currentX: 0
    property double currentY: 0
    property int currentSrid: 4258 // Default to ETRS89 (EPSG:4258) since it works better with the SIGPAC service
    
    // Reference to the SIGPAC service
    property var sigpacService: null
    
    // Property to store the results
    property var sigpacResults: null
    property bool isLoading: false
    property string errorMessage: ""
    property bool isLoadingAdditionalData: false
    
    width: Math.min(parent.width * 0.95, 600)
    height: Math.min(parent.height * 0.95, 800)
    
    // Center the dialog in the parent
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Background color based on theme
    background: Rectangle {
        color: Theme.mainBackgroundColor
        border.color: Theme.controlBorderColor
        border.width: 1
        radius: 4
    }
    
    // Custom title area with subtitle and link
    header: ColumnLayout {
        width: parent.width
        spacing: 2
        
        Label {
            text: qsTr("Información de Parcela/Recinto SIGPAC")
            font: Theme.strongTipFont
            color: Theme.mainTextColor
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.topMargin: 8
        }
        
        Text {
            text: "<a href='https://www.fega.gob.es/es'>Consultas servidores FEGA</a>"
            font {
                family: Theme.tinyFont.family
                pixelSize: Theme.tinyFont.pixelSize
                weight: Theme.tinyFont.weight
            }
            color: Theme.secondaryTextColor
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            
            onLinkActivated: function(link) {
                Qt.openUrlExternally(link)
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
    
    // Create the SIGPAC service when the dialog is created
    Component.onCompleted: {
        if (typeof currentSrid === 'undefined' || currentSrid === null) {
            console.log("Initializing currentSrid to default value in Component.onCompleted");
            currentSrid = 4258;
        }
        
        try {
            // Create the SigpacService component
            var component = Qt.createComponent("SigpacService.qml");
            
            if (component.status === Component.Ready) {
                sigpacService = component.createObject(sigpacDialog);
                
                // Connect to the signals
                sigpacService.dataLoaded.connect(function(data) {
                    isLoading = false;
                    sigpacResults = data;
                    errorMessage = "";
                });
                
                sigpacService.errorOccurred.connect(function(error) {
                    isLoading = false;
                    sigpacResults = null;
                    errorMessage = error;
                });
                
                sigpacService.additionalDataLoadingChanged.connect(function(isLoading) {
                    isLoadingAdditionalData = isLoading;
                });
            } else if (component.status === Component.Error) {
                console.error("Error creating SigpacService:", component.errorString());
                errorMessage = "Error al crear SigpacService: " + component.errorString();
            }
        } catch (e) {
            console.error("Exception creating SigpacService:", e);
            errorMessage = "Excepción al crear SigpacService: " + e;
        }
    }
    
    // Function to query SIGPAC data for the current map position
    function queryCurrentPosition() {
        if (!sigpacService) {
            errorMessage = "Servicio SIGPAC no disponible";
            return;
        }
        
        isLoading = true;
        sigpacResults = null;
        errorMessage = "";
        
        // Ensure currentSrid has a valid value
        if (typeof currentSrid === 'undefined' || currentSrid === null) {
            console.log("currentSrid was undefined, setting default value 4258");
            currentSrid = 4258; // Default to ETRS89
        }
        
        // Query the SIGPAC service
        sigpacService.queryByCoordinates(currentSrid, currentX, currentY, "json");
    }
    
    // Function to set coordinates and query SIGPAC data
    function setCoordinates(x, y) {
        currentX = x;
        currentY = y;
        
        // Ensure currentSrid has a valid value before attempting to override
        if (typeof currentSrid === 'undefined' || currentSrid === null) {
            currentSrid = 4258; // Default to ETRS89
        }
        
        // Try to get the SRID from the map settings if available
        try {
            if (typeof mapCanvas !== 'undefined' && mapCanvas.mapSettings && 
                mapCanvas.mapSettings.destinationCrs && 
                typeof mapCanvas.mapSettings.destinationCrs.postgisSrid === 'number') {
                currentSrid = mapCanvas.mapSettings.destinationCrs.postgisSrid;
            }
        } catch (e) {
            console.log("No se pudo obtener SRID de la configuración del mapa, usando el predeterminado:", e);
            // Keep using the default SRID (4258)
        }
        
        // Query SIGPAC data
        queryCurrentPosition();
    }
    
    // Function to query SIGPAC data for custom coordinates
    function queryCustomCoordinates(srid, x, y) {
        if (!sigpacService) {
            errorMessage = "Servicio SIGPAC no disponible";
            return;
        }
        
        isLoading = true;
        sigpacResults = null;
        errorMessage = "";
        
        // Query the SIGPAC service
        sigpacService.queryByCoordinates(srid, x, y, "json");
    }
    
    // Function to query SIGPAC data by SIGPAC code
    function queryBySigpacCode(provincia, municipio, agregado, zona, poligono, parcela, recinto) {
        if (!sigpacService) {
            errorMessage = "Servicio SIGPAC no disponible";
            return;
        }
        
        isLoading = true;
        sigpacResults = null;
        errorMessage = "";
        
        // Query the SIGPAC service
        sigpacService.queryBySigpacCode(provincia, municipio, agregado, zona, poligono, parcela, recinto, "json");
    }
    
    // Dialog content
    ScrollView {
        id: mainScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        
        ColumnLayout {
            width: mainScrollView.width
            anchors.margins: 6
            spacing: 3
            
            TabBar {
                id: tabBar
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: Theme.controlBackgroundColor
                    radius: 4
                }
                
                TabButton {
                    text: qsTr("Actual")
                    font: Theme.tipFont
                    
                    background: Rectangle {
                        color: tabBar.currentIndex === 0 ? Theme.mainColor : "transparent"
                        opacity: tabBar.currentIndex === 0 ? 1.0 : 0.7
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: tabBar.currentIndex === 0 ? Theme.buttonTextColor : Theme.mainTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                TabButton {
                    text: qsTr("Personalizado")
                    font: Theme.tipFont
                    
                    background: Rectangle {
                        color: tabBar.currentIndex === 1 ? Theme.mainColor : "transparent"
                        opacity: tabBar.currentIndex === 1 ? 1.0 : 0.7
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: tabBar.currentIndex === 1 ? Theme.buttonTextColor : Theme.mainTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                TabButton {
                    text: qsTr("Código SIGPAC")
                    font: Theme.tipFont
                    
                    background: Rectangle {
                        color: tabBar.currentIndex === 2 ? Theme.mainColor : "transparent"
                        opacity: tabBar.currentIndex === 2 ? 1.0 : 0.7
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: tabBar.currentIndex === 2 ? Theme.buttonTextColor : Theme.mainTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
            
            StackLayout {
                Layout.fillWidth: true
                currentIndex: tabBar.currentIndex
                Layout.topMargin: 2
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 2
                        
                        Label {
                            text: qsTr("Posición Actual del Mapa:")
                            font: Theme.strongTipFont
                            color: Theme.mainTextColor
                        }
                        
                        Label {
                            text: qsTr("X: %1").arg(currentX.toFixed(6))
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                        }
                        
                        Label {
                            text: qsTr("Y: %1").arg(currentY.toFixed(6))
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                        }
                        
                        Label {
                            text: qsTr("SRID: %1").arg(currentSrid)
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                        }
                        
                        Label {
                            text: qsTr("Nota: SIGPAC por defecto con EPSG:4258 (ETRS89) 2cm vs EPSG:4326 (WGS84)")
                            font {
                                family: Theme.tinyFont.family
                                pixelSize: Theme.tinyFont.pixelSize
                                weight: Theme.tinyFont.weight
                                italic: true
                            }
                            color: Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        
                        Button {
                            text: qsTr("Consultar SIGPAC")
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 2
                            enabled: !isLoading && sigpacService !== null
                            
                            background: Rectangle {
                                color: parent.enabled ? Theme.mainColor : Theme.controlBackgroundDisabledColor
                                radius: 4
                                implicitHeight: 32
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font: Theme.tipFont
                                color: parent.enabled ? Theme.buttonTextColor : Theme.mainTextDisabledColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: {
                                queryCurrentPosition();
                            }
                        }
                    }
                }
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 2
                        
                        Label {
                            text: qsTr("Introducir Coordenadas Personalizadas:")
                            font: Theme.strongTipFont
                            color: Theme.mainTextColor
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("SRID:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 60
                            }
                            
                            ComboBox {
                                id: sridComboBox
                                Layout.fillWidth: true
                                model: [
                                    { text: "EPSG:4258 (ETRS89)", value: 4258 },
                                    { text: "EPSG:4326 (WGS84)", value: 4326 },
                                    { text: "EPSG:25828 (UTM 28N)", value: 25828 },
                                    { text: "EPSG:25829 (UTM 29N)", value: 25829 },
                                    { text: "EPSG:25830 (UTM 30N)", value: 25830 },
                                    { text: "EPSG:25831 (UTM 31N)", value: 25831 }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                currentIndex: 0
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        Label {
                            text: qsTr("Nota: SIGPAC por defecto con EPSG:4258 (ETRS89) o EPSG:4326 (WGS84)")
                            font {
                                family: Theme.tinyFont.family
                                pixelSize: Theme.tinyFont.pixelSize
                                weight: Theme.tinyFont.weight
                                italic: true
                            }
                            color: Theme.secondaryTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("X:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 60
                            }
                            
                            TextField {
                                id: xTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Introduce coordenada X")
                                text: currentX.toFixed(6)
                                validator: DoubleValidator {}
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Y:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 60
                            }
                            
                            TextField {
                                id: yTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Introduce coordenada Y")
                                text: currentY.toFixed(6)
                                validator: DoubleValidator {}
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        Button {
                            text: qsTr("Consultar SIGPAC")
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 2
                            enabled: !isLoading && sigpacService !== null && xTextField.text !== "" && yTextField.text !== ""
                            
                            background: Rectangle {
                                color: parent.enabled ? Theme.mainColor : Theme.controlBackgroundDisabledColor
                                radius: 4
                                implicitHeight: 32
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font: Theme.tipFont
                                color: parent.enabled ? Theme.buttonTextColor : Theme.mainTextDisabledColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: {
                                queryCustomCoordinates(
                                    sridComboBox.model[sridComboBox.currentIndex].value,
                                    parseFloat(xTextField.text),
                                    parseFloat(yTextField.text)
                                );
                            }
                        }
                    }
                }
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 2
                        
                        Label {
                            text: qsTr("Introducir Código SIGPAC:")
                            font: Theme.strongTipFont
                            color: Theme.mainTextColor
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Provincia:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 80
                            }
                            
                            TextField {
                                id: provinciaTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Provincia")
                                validator: IntValidator { bottom: 1; top: 99 }
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Municipio:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 80
                            }
                            
                            TextField {
                                id: municipioTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Municipio")
                                validator: IntValidator { bottom: 1; top: 999 }
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Agregado:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 80
                            }
                            
                            TextField {
                                id: agregadoTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Agregado")
                                text: "0"
                                validator: IntValidator { bottom: 0; top: 99 }
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                            
                            Label {
                                text: qsTr("Zona:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 60
                            }
                            
                            TextField {
                                id: zonaTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Zona")
                                text: "0"
                                validator: IntValidator { bottom: 0; top: 99 }
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Polígono:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 80
                            }
                            
                            TextField {
                                id: poligonoTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Polígono")
                                validator: IntValidator { bottom: 1; top: 999 }
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                            
                            Label {
                                text: qsTr("Parcela:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 60
                            }
                            
                            TextField {
                                id: parcelaTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Parcela")
                                validator: IntValidator { bottom: 1; top: 99999 }
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Recinto:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 80
                            }
                            
                            TextField {
                                id: recintoTextField
                                Layout.fillWidth: true
                                placeholderText: qsTr("Recinto")
                                validator: IntValidator { bottom: 1; top: 999 }
                                font: Theme.tipFont
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                            }
                        }
                        
                        Button {
                            text: qsTr("Consultar SIGPAC")
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 2
                            enabled: !isLoading && sigpacService !== null && 
                                    provinciaTextField.text !== "" && 
                                    municipioTextField.text !== "" && 
                                    poligonoTextField.text !== "" && 
                                    parcelaTextField.text !== "" && 
                                    recintoTextField.text !== ""
                            
                            background: Rectangle {
                                color: parent.enabled ? Theme.mainColor : Theme.controlBackgroundDisabledColor
                                radius: 4
                                implicitHeight: 32
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font: Theme.tipFont
                                color: parent.enabled ? Theme.buttonTextColor : Theme.mainTextDisabledColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            onClicked: {
                                queryBySigpacCode(
                                    parseInt(provinciaTextField.text),
                                    parseInt(municipioTextField.text),
                                    parseInt(agregadoTextField.text),
                                    parseInt(zonaTextField.text),
                                    parseInt(poligonoTextField.text),
                                    parseInt(parcelaTextField.text),
                                    parseInt(recintoTextField.text)
                                );
                            }
                        }
                    }
                }
            }
            
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
            }
            
            BusyIndicator {
                visible: isLoading
                running: isLoading
                Layout.alignment: Qt.AlignHCenter
                
                contentItem: Item {
                    implicitWidth: 32
                    implicitHeight: 32
                    
                    Rectangle {
                        id: busyIndicator
                        width: parent.width
                        height: width
                        radius: width / 2
                        border.width: width / 6
                        border.color: Theme.mainColor
                        color: "transparent"
                        
                        RotationAnimation {
                            target: busyIndicator
                            running: isLoading
                            from: 0
                            to: 360
                            duration: 1200
                            loops: Animation.Infinite
                        }
                    }
                }
            }
            
            RowLayout {
                visible: !isLoading && isLoadingAdditionalData
                Layout.alignment: Qt.AlignHCenter
                spacing: 4
                
                BusyIndicator {
                    running: isLoadingAdditionalData
                    
                    contentItem: Item {
                        implicitWidth: 16
                        implicitHeight: 16
                        
                        Rectangle {
                            id: additionalDataBusyIndicator
                            width: parent.width
                            height: width
                            radius: width / 2
                            border.width: width / 6
                            border.color: Theme.secondaryColor
                            color: "transparent"
                            
                            RotationAnimation {
                                target: additionalDataBusyIndicator
                                running: isLoadingAdditionalData
                                from: 0
                                to: 360
                                duration: 1200
                                loops: Animation.Infinite
                            }
                        }
                    }
                }
                
                Label {
                    text: qsTr("Cargando datos ambientales...")
                    font: Theme.tinyFont
                    color: Theme.secondaryTextColor
                }
            }
            
            Label {
                visible: errorMessage !== ""
                text: errorMessage
                color: Theme.errorColor
                font: Theme.tipFont
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            GroupBox {
                title: qsTr("Resultados SIGPAC")
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 160
                Layout.topMargin: 0
                
                background: Rectangle {
                    color: Theme.controlBackgroundAlternateColor
                    border.color: Theme.controlBorderColor
                    border.width: 1
                    radius: 4
                }
                
                label: Label {
                    text: parent.title
                    color: Theme.mainTextColor
                    font: Theme.strongTipFont
                    x: parent.leftPadding
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 1
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                    
                    TextArea {
                        id: resultsTextArea
                        anchors.fill: parent
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        font: Theme.tipFont
                        color: Theme.mainTextColor ? Theme.mainTextColor : "black"
                        
                        background: Rectangle {
                            color: Theme.controlBackgroundColor ? Theme.controlBackgroundColor : "#f0f0f0"
                            border.color: Theme.controlBorderColor ? Theme.controlBorderColor : "#cccccc"
                            border.width: 1
                            radius: 4
                        }
                        
                        text: {
                            if (isLoading) {
                                return qsTr("Cargando...");
                            } else if (errorMessage !== "") {
                                return qsTr("Error: %1").arg(errorMessage);
                            } else if (!sigpacResults) {
                                return qsTr("Sin resultados. Haga clic en 'Consultar SIGPAC' para obtener información.");
                            } else if (Array.isArray(sigpacResults) && sigpacResults.length === 0) {
                                return qsTr("No se encontraron datos SIGPAC para esta ubicación.");
                            } else if (sigpacService) {
                                var result = sigpacService.formatSigpacData(sigpacResults);
                                if (isLoadingAdditionalData) {
                                    result += "\n\n" + qsTr("Cargando datos ambientales adicionales (Red Natura 2000, Fitosanitarios, Nitratos, Montanera, Pastos)...");
                                }
                                return result;
                            } else {
                                return qsTr("Servicio SIGPAC no disponible");
                            }
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 2
                spacing: 4
                
                Button {
                    text: qsTr("Copiar Resultados")
                    font: Theme.tipFont
                    visible: sigpacResults !== null && Array.isArray(sigpacResults) && sigpacResults.length > 0
                    
                    background: Rectangle {
                        color: Theme.mainColor
                        radius: 4
                        implicitHeight: 32
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: Theme.buttonTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        if (resultsTextArea.text) {
                            resultsTextArea.selectAll();
                            resultsTextArea.copy();
                            resultsTextArea.deselect();
                            console.log("Resultados SIGPAC copiados al portapapeles");
                        }
                    }
                }
                
                Button {
                    text: qsTr("Cerrar")
                    font: Theme.tipFont
                    
                    background: Rectangle {
                        color: Theme.mainColor
                        radius: 4
                        implicitHeight: 32
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: Theme.buttonTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: sigpacDialog.close()
                }
            }
        }
    }
} 