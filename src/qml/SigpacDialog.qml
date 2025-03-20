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
    
    // Properties for SIGPAC codes
    property var provincesData: null
    property var municipalitiesData: null
    property var polygonsData: null
    property var plotsData: null
    property bool isLoadingProvinces: false
    property bool isLoadingMunicipalities: false
    property bool isLoadingPolygons: false
    property bool isLoadingPlots: false
    
    width: Math.min(parent.width * 0.95, 600)
    height: Math.min(parent.height * 0.95, 700)
    
    // Center the dialog in the parent
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 6  // Add padding to ensure content doesn't touch edges
    
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
        
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            
            Item { // Spacer
                Layout.preferredWidth: 32
            }
            
            Label {
                text: qsTr("Información de Parcela/Recinto SIGPAC")
                font: Theme.strongTipFont
                color: Theme.mainTextColor
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
            
            Button {
                id: closeButton
                implicitWidth: 32
                implicitHeight: 32
                flat: true
                
                contentItem: Text {
                    text: "✕"
                    font.pixelSize: Theme.tipFont.pixelSize * 1.2
                    font.bold: true
                    color: Theme.mainTextColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: closeButton.hovered ? Theme.controlBackgroundColor : "transparent"
                    radius: 4
                }
                
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Cerrar")
                
                onClicked: sigpacDialog.close()
            }
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
                
                // Load provinces data for the dropdown menu
                loadProvinces();
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
    
    // Function to load provinces data
    function loadProvinces() {
        if (provincesData !== null) {
            return; // Already loaded
        }
        
        isLoadingProvinces = true;
        errorMessage = ""; // Clear previous errors
        
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoadingProvinces = false;
                
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        provincesData = data;
                        console.log("Provinces data loaded: " + data.codigos.length + " provinces");
                    } catch (e) {
                        console.error("Error parsing provinces data:", e);
                        errorMessage = "Error al cargar provincias: " + e;
                    }
                } else {
                    console.error("Error loading provinces. Status:", xhr.status);
                    errorMessage = "Error al cargar provincias: " + xhr.status;
                }
            }
        };
        
        var url = "https://sigpac-hubcloud.es/codigossigpac/provincia.json";
        console.log("Loading provinces from URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending provinces request:", e);
            errorMessage = "Error al enviar la solicitud de provincias: " + e;
            isLoadingProvinces = false;
        }
    }
    
    // Function to load municipalities data for a specific province
    function loadMunicipalities(provinciaCode) {
        isLoadingMunicipalities = true;
        municipalitiesData = null; // Reset previous data
        polygonsData = null; // Reset polygons data when province changes
        plotsData = null; // Reset plots data when province changes
        errorMessage = ""; // Clear previous errors
        
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoadingMunicipalities = false;
                
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        municipalitiesData = data;
                        if (data.codigos && data.codigos.length > 0) {
                            console.log("Municipalities data loaded: " + data.codigos.length + " municipalities");
                        } else {
                            console.log("No municipalities found for province code: " + provinciaCode);
                            errorMessage = "No se encontraron municipios para la provincia seleccionada";
                        }
                    } catch (e) {
                        console.error("Error parsing municipalities data:", e);
                        errorMessage = "Error al analizar los datos de municipios: " + e;
                    }
                } else {
                    console.error("Error loading municipalities. Status:", xhr.status);
                    errorMessage = "Error al cargar municipios (código " + xhr.status + "). Verifique la conexión a Internet.";
                }
            }
        };
        
        var url = "https://sigpac-hubcloud.es/codigossigpac/municipio" + provinciaCode + ".json";
        console.log("Loading municipalities from URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending municipalities request:", e);
            errorMessage = "Error al enviar la solicitud de municipios: " + e;
            isLoadingMunicipalities = false;
        }
    }
    
    // Function to load polygons data for a specific municipality
    function loadPolygons(provinciaCode, municipioCode) {
        isLoadingPolygons = true;
        polygonsData = null; // Reset previous data
        plotsData = null; // Reset plots data when municipality changes
        errorMessage = ""; // Clear previous errors
        
        // Create a fake/simulated list of polygons for the selected municipality
        // In a real implementation, you would fetch this data from an actual SIGPAC API endpoint
        var timer = Qt.createQmlObject("import QtQuick; Timer {}", sigpacDialog);
        timer.interval = 500; // Simulate network delay
        timer.repeat = false;
        timer.triggered.connect(function() {
            isLoadingPolygons = false;
            
            // Generate 10-30 polygons (random number for simulation)
            var numPolygons = Math.floor(Math.random() * 20) + 10;
            var polygons = { codigos: [] };
            
            for (var i = 1; i <= numPolygons; i++) {
                polygons.codigos.push({
                    codigo: i,
                    descripcion: "Polígono " + i
                });
            }
            
            polygonsData = polygons;
            console.log("Polygons data loaded: " + polygons.codigos.length + " polygons for municipality " + municipioCode);
            
            timer.destroy();
        });
        
        console.log("Loading polygons for province " + provinciaCode + " and municipality " + municipioCode);
        timer.start();
    }
    
    // Function to load plots data for a specific polygon
    function loadPlots(provinciaCode, municipioCode, polygonoCode) {
        isLoadingPlots = true;
        plotsData = null; // Reset previous data
        errorMessage = ""; // Clear previous errors
        
        // Create a fake/simulated list of plots for the selected polygon
        // In a real implementation, you would fetch this data from an actual SIGPAC API endpoint
        var timer = Qt.createQmlObject("import QtQuick; Timer {}", sigpacDialog);
        timer.interval = 500; // Simulate network delay
        timer.repeat = false;
        timer.triggered.connect(function() {
            isLoadingPlots = false;
            
            // Generate 5-50 plots (random number for simulation)
            var numPlots = Math.floor(Math.random() * 45) + 5;
            var plots = { codigos: [] };
            
            for (var i = 1; i <= numPlots; i++) {
                plots.codigos.push({
                    codigo: i,
                    descripcion: "Parcela " + i
                });
            }
            
            plotsData = plots;
            console.log("Plots data loaded: " + plots.codigos.length + " plots for polygon " + polygonoCode);
            
            timer.destroy();
        });
        
        console.log("Loading plots for province " + provinciaCode + ", municipality " + municipioCode + ", polygon " + polygonoCode);
        timer.start();
    }
    
    // Dialog content
    ScrollView {
        id: mainScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true  // Prevent content from overflowing
        
        ColumnLayout {
            width: mainScrollView.width
            anchors.margins: 6
            spacing: 2
            
            TabBar {
                id: tabBar
                Layout.fillWidth: true
                Layout.preferredHeight: 36  // Reduce height
                
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
                    Layout.preferredHeight: 240
                    
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
                            
                            ComboBox {
                                id: provinciaComboBox
                                Layout.fillWidth: true
                                model: provincesData ? provincesData.codigos : []
                                textRole: "descripcion"
                                valueRole: "codigo"
                                enabled: !isLoadingProvinces && provincesData !== null
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                                
                                delegate: ItemDelegate {
                                    width: provinciaComboBox.width
                                    contentItem: Text {
                                        text: modelData.codigo + " - " + modelData.descripcion
                                        font: Theme.tipFont
                                        color: Theme.mainTextColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: provinciaComboBox.highlightedIndex === index
                                }
                                
                                contentItem: Text {
                                    leftPadding: 10
                                    rightPadding: provinciaComboBox.indicator.width + provinciaComboBox.spacing
                                    text: provinciaComboBox.currentIndex === -1 ? 
                                         (isLoadingProvinces ? qsTr("Cargando...") : qsTr("Seleccionar provincia")) : 
                                         provinciaComboBox.displayText
                                    font: Theme.tipFont
                                    color: Theme.mainTextColor
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onActivated: {
                                    var provinceCode = provincesData.codigos[currentIndex].codigo;
                                    loadMunicipalities(provinceCode);
                                    // Reset municipality selection when province changes
                                    municipioComboBox.currentIndex = -1;
                                    
                                    console.log("Selected province: " + 
                                         provincesData.codigos[currentIndex].codigo + " - " + 
                                         provincesData.codigos[currentIndex].descripcion);
                                }
                            }
                            
                            BusyIndicator {
                                visible: isLoadingProvinces
                                running: isLoadingProvinces
                                implicitWidth: 24
                                implicitHeight: 24
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
                            
                            ComboBox {
                                id: municipioComboBox
                                Layout.fillWidth: true
                                model: municipalitiesData ? municipalitiesData.codigos : []
                                textRole: "descripcion"
                                valueRole: "codigo"
                                enabled: !isLoadingMunicipalities && municipalitiesData !== null
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                                
                                delegate: ItemDelegate {
                                    width: municipioComboBox.width
                                    contentItem: Text {
                                        text: modelData.codigo + " - " + modelData.descripcion
                                        font: Theme.tipFont
                                        color: Theme.mainTextColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: municipioComboBox.highlightedIndex === index
                                }
                                
                                contentItem: Text {
                                    leftPadding: 10
                                    rightPadding: municipioComboBox.indicator.width + municipioComboBox.spacing
                                    text: municipioComboBox.currentIndex === -1 ? 
                                         (isLoadingMunicipalities ? qsTr("Cargando...") : qsTr("Seleccionar municipio")) : 
                                         municipioComboBox.displayText
                                    font: Theme.tipFont
                                    color: Theme.mainTextColor
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onActivated: {
                                    // When a municipality is selected, load the polygons for this municipality
                                    if (currentIndex >= 0 && provinciaComboBox.currentIndex >= 0) {
                                        var provinceCode = provincesData.codigos[provinciaComboBox.currentIndex].codigo;
                                        var municipioCode = municipalitiesData.codigos[currentIndex].codigo;
                                        loadPolygons(provinceCode, municipioCode);
                                        
                                        // Reset polygon and plot selections
                                        poligonoComboBox.currentIndex = -1;
                                        parcelaComboBox.currentIndex = -1;
                                        
                                        console.log("Selected municipality: " + 
                                            municipioCode + " - " + 
                                            municipalitiesData.codigos[currentIndex].descripcion);
                                    }
                                }
                            }
                            
                            BusyIndicator {
                                visible: isLoadingMunicipalities
                                running: isLoadingMunicipalities
                                implicitWidth: 24
                                implicitHeight: 24
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
                            
                            ComboBox {
                                id: poligonoComboBox
                                Layout.fillWidth: true
                                model: polygonsData ? polygonsData.codigos : []
                                textRole: "descripcion"
                                valueRole: "codigo"
                                enabled: !isLoadingPolygons && polygonsData !== null
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                                
                                delegate: ItemDelegate {
                                    width: poligonoComboBox.width
                                    contentItem: Text {
                                        text: modelData.codigo + " - " + modelData.descripcion
                                        font: Theme.tipFont
                                        color: Theme.mainTextColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: poligonoComboBox.highlightedIndex === index
                                }
                                
                                contentItem: Text {
                                    leftPadding: 10
                                    rightPadding: poligonoComboBox.indicator.width + poligonoComboBox.spacing
                                    text: poligonoComboBox.currentIndex === -1 ? 
                                         (isLoadingPolygons ? qsTr("Cargando...") : qsTr("Seleccionar polígono")) : 
                                         poligonoComboBox.displayText
                                    font: Theme.tipFont
                                    color: Theme.mainTextColor
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onActivated: {
                                    // When a polygon is selected, load the plots for this polygon
                                    if (currentIndex >= 0 && municipioComboBox.currentIndex >= 0 && provinciaComboBox.currentIndex >= 0) {
                                        var provinceCode = provincesData.codigos[provinciaComboBox.currentIndex].codigo;
                                        var municipioCode = municipalitiesData.codigos[municipioComboBox.currentIndex].codigo;
                                        var polygonoCode = polygonsData.codigos[currentIndex].codigo;
                                        loadPlots(provinceCode, municipioCode, polygonoCode);
                                        
                                        // Reset plot selection
                                        parcelaComboBox.currentIndex = -1;
                                        
                                        console.log("Selected polygon: " + polygonoCode);
                                    }
                                }
                            }
                            
                            BusyIndicator {
                                visible: isLoadingPolygons
                                running: isLoadingPolygons
                                implicitWidth: 24
                                implicitHeight: 24
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                text: qsTr("Parcela:")
                                font: Theme.tipFont
                                color: Theme.mainTextColor
                                Layout.preferredWidth: 60
                            }
                            
                            ComboBox {
                                id: parcelaComboBox
                                Layout.fillWidth: true
                                model: plotsData ? plotsData.codigos : []
                                textRole: "descripcion"
                                valueRole: "codigo"
                                enabled: !isLoadingPlots && plotsData !== null
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                                
                                delegate: ItemDelegate {
                                    width: parcelaComboBox.width
                                    contentItem: Text {
                                        text: modelData.codigo + " - " + modelData.descripcion
                                        font: Theme.tipFont
                                        color: Theme.mainTextColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: parcelaComboBox.highlightedIndex === index
                                }
                                
                                contentItem: Text {
                                    leftPadding: 10
                                    rightPadding: parcelaComboBox.indicator.width + parcelaComboBox.spacing
                                    text: parcelaComboBox.currentIndex === -1 ? 
                                         (isLoadingPlots ? qsTr("Cargando...") : qsTr("Seleccionar parcela")) : 
                                         parcelaComboBox.displayText
                                    font: Theme.tipFont
                                    color: Theme.mainTextColor
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                
                                onActivated: {
                                    if (currentIndex >= 0) {
                                        console.log("Selected plot: " + plotsData.codigos[currentIndex].codigo);
                                        loadRecintos(plotsData.codigos[currentIndex].codigo);
                                    }
                                }
                            }
                            
                            BusyIndicator {
                                visible: isLoadingPlots
                                running: isLoadingPlots
                                implicitWidth: 24
                                implicitHeight: 24
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
                            
                            ComboBox {
                                id: recintoComboBox
                                Layout.fillWidth: true
                                // Initially empty model - will be populated when a plot is selected
                                model: []
                                textRole: "display"
                                valueRole: "value"
                                property bool isLoadingRecintos: false
                                enabled: !isLoadingRecintos && parcelaComboBox.currentIndex !== -1
                                
                                background: Rectangle {
                                    color: Theme.controlBackgroundColor
                                    border.color: Theme.controlBorderColor
                                    border.width: 1
                                    radius: 4
                                }
                                
                                delegate: ItemDelegate {
                                    width: recintoComboBox.width
                                    contentItem: Text {
                                        text: modelData.display
                                        font: Theme.tipFont
                                        color: Theme.mainTextColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    highlighted: recintoComboBox.highlightedIndex === index
                                }
                                
                                contentItem: Text {
                                    leftPadding: 10
                                    rightPadding: recintoComboBox.indicator.width + recintoComboBox.spacing
                                    text: recintoComboBox.currentIndex === -1 ? 
                                         (recintoComboBox.isLoadingRecintos ? qsTr("Cargando...") : qsTr("Seleccionar recinto")) : 
                                         recintoComboBox.displayText
                                    font: Theme.tipFont
                                    color: Theme.mainTextColor
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                            
                            BusyIndicator {
                                visible: recintoComboBox.isLoadingRecintos
                                running: recintoComboBox.isLoadingRecintos
                                implicitWidth: 24
                                implicitHeight: 24
                            }
                        }
                        
                        Button {
                            text: qsTr("Consultar SIGPAC")
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 2
                            enabled: !isLoading && sigpacService !== null && 
                                    provinciaComboBox.currentIndex !== -1 && 
                                    municipioComboBox.currentIndex !== -1 && 
                                    poligonoComboBox.currentIndex !== -1 && 
                                    parcelaComboBox.currentIndex !== -1 && 
                                    recintoComboBox.currentIndex !== -1 &&
                                    recintoComboBox.model.length > 0 &&
                                    recintoComboBox.currentValue !== -1 // Disable if the "No existe ningún recinto" option is selected
                            
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
                                    parseInt(provincesData.codigos[provinciaComboBox.currentIndex].codigo),
                                    parseInt(municipioComboBox.model[municipioComboBox.currentIndex].codigo),
                                    parseInt(agregadoTextField.text),
                                    parseInt(zonaTextField.text),
                                    parseInt(poligonoComboBox.model[poligonoComboBox.currentIndex].codigo),
                                    parseInt(parcelaComboBox.model[parcelaComboBox.currentIndex].codigo),
                                    parseInt(recintoComboBox.model[recintoComboBox.currentIndex].value)
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
                    text: qsTr("Cargando datos ambientales ( haz zoom cercano para más rapidez)")
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
                Layout.minimumHeight: 120  // Reduce minimum height to allow more space for buttons
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
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    
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
                                return qsTr("NO HAY DATOS: %1").arg(errorMessage);
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
                Layout.bottomMargin: 4
                Layout.rightMargin: 4
                Layout.fillWidth: true
                spacing: 4
                
                Item {
                    Layout.fillWidth: true
                }
                
                Button {
                    text: qsTr("Copiar Resultados")
                    font: Theme.tipFont
                    visible: sigpacResults !== null && Array.isArray(sigpacResults) && sigpacResults.length > 0
                    implicitWidth: Math.max(120, contentItem.implicitWidth + 20)
                    
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
                    implicitWidth: Math.max(80, contentItem.implicitWidth + 20)
                    
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

    // Function to load recintos for a selected plot
    function loadRecintos(plotId) {
        recintoComboBox.isLoadingRecintos = true;
        recintoComboBox.model = [];
        
        if (provinciaComboBox.currentIndex >= 0 && 
            municipioComboBox.currentIndex >= 0 && 
            poligonoComboBox.currentIndex >= 0 && 
            parcelaComboBox.currentIndex >= 0) {
            
            var provinciaCode = provincesData.codigos[provinciaComboBox.currentIndex].codigo;
            var municipioCode = municipalitiesData.codigos[municipioComboBox.currentIndex].codigo;
            var poligonoCode = polygonsData.codigos[poligonoComboBox.currentIndex].codigo;
            var agregadoCode = agregadoTextField.text || "0";
            var zonaCode = zonaTextField.text || "0";
            
            // Start by checking recinto 1 and then iteratively check others
            checkRecintoExists(provinciaCode, municipioCode, agregadoCode, zonaCode, poligonoCode, plotId, 1);
        } else {
            recintoComboBox.isLoadingRecintos = false;
            console.log("Cannot check recintos: missing selection data");
        }
    }
    
    // Function to check if a recinto exists by querying the API
    function checkRecintoExists(provinciaCode, municipioCode, agregadoCode, zonaCode, poligonoCode, parcelaCode, recintoCode, foundRecintos = []) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var results = JSON.parse(xhr.responseText);
                        if (results && Array.isArray(results) && results.length > 0) {
                            // This recinto exists, add it to the list
                            foundRecintos.push({
                                display: "Recinto " + recintoCode + (results[0].uso_sigpac ? " - " + results[0].uso_sigpac : ""),
                                value: recintoCode
                            });
                            
                            // Check if next recinto exists (up to a reasonable limit, e.g., 10)
                            if (recintoCode < 10) {
                                checkRecintoExists(provinciaCode, municipioCode, agregadoCode, zonaCode, poligonoCode, parcelaCode, recintoCode + 1, foundRecintos);
                            } else {
                                // Done checking, update the model
                                updateRecintoModel(foundRecintos);
                            }
                        } else {
                            // This recinto doesn't exist, we've found all recintos for this plot
                            updateRecintoModel(foundRecintos);
                        }
                    } catch (e) {
                        console.error("Error parsing recinto data:", e);
                        updateRecintoModel(foundRecintos);
                    }
                } else {
                    console.error("Error checking recinto. Status:", xhr.status);
                    updateRecintoModel(foundRecintos);
                }
            }
        };
        
        var url = "https://sigpac-hubcloud.es/servicioconsultassigpac/query/recinfo/" + 
                provinciaCode + "/" + 
                municipioCode + "/" + 
                agregadoCode + "/" + 
                zonaCode + "/" + 
                poligonoCode + "/" + 
                parcelaCode + "/" + 
                recintoCode + ".json";
                
        console.log("Checking recinto existence: " + url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending recinto existence request:", e);
            updateRecintoModel(foundRecintos);
        }
    }
    
    // Function to update the recinto model with found recintos
    function updateRecintoModel(recintos) {
        if (recintos.length > 0) {
            recintoComboBox.model = recintos;
            console.log("Found " + recintos.length + " recintos");
        } else {
            // If no recintos were found, add a placeholder item indicating this
            recintoComboBox.model = [{
                display: "No existe ningún recinto",
                value: -1 // Use -1 to indicate no valid recinto
            }];
            console.log("No recintos found for the selected plot");
        }
        recintoComboBox.isLoadingRecintos = false;
    }
} 