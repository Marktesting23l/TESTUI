import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml
import Theme

Dialog {
    id: sigpacDialog
    title: qsTr("SIGPAC Parcel Information")
    
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
    
    // Create the SIGPAC service when the dialog is created
    Component.onCompleted: {
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
                errorMessage = "Error creating SigpacService: " + component.errorString();
            }
        } catch (e) {
            console.error("Exception creating SigpacService:", e);
            errorMessage = "Exception creating SigpacService: " + e;
        }
    }
    
    // Function to query SIGPAC data for the current map position
    function queryCurrentPosition() {
        if (!sigpacService) {
            errorMessage = "SIGPAC service not available";
            return;
        }
        
        isLoading = true;
        sigpacResults = null;
        errorMessage = "";
        
        // Query the SIGPAC service
        sigpacService.queryByCoordinates(currentSrid, currentX, currentY, "json");
    }
    
    // Function to set coordinates and query SIGPAC data
    function setCoordinates(x, y) {
        currentX = x;
        currentY = y;
        
        // Try to get the SRID from the map settings if available
        try {
            if (typeof mapCanvas !== 'undefined' && mapCanvas.mapSettings && 
                mapCanvas.mapSettings.destinationCrs && 
                typeof mapCanvas.mapSettings.destinationCrs.postgisSrid === 'number') {
                currentSrid = mapCanvas.mapSettings.destinationCrs.postgisSrid;
            }
        } catch (e) {
            console.log("Could not get SRID from map settings, using default:", e);
            // Keep using the default SRID (4258)
        }
        
        // Query SIGPAC data
        queryCurrentPosition();
    }
    
    // Function to query SIGPAC data for custom coordinates
    function queryCustomCoordinates(srid, x, y) {
        if (!sigpacService) {
            errorMessage = "SIGPAC service not available";
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
            errorMessage = "SIGPAC service not available";
            return;
        }
        
        isLoading = true;
        sigpacResults = null;
        errorMessage = "";
        
        // Query the SIGPAC service
        sigpacService.queryBySigpacCode(provincia, municipio, agregado, zona, poligono, parcela, recinto, "json");
    }
    
    // Dialog content
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8 // Reduced margins for mobile
        spacing: 6 // Reduced spacing for mobile
        
        // Tabs for different query methods
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            background: Rectangle {
                color: Theme.controlBackgroundColor
                radius: 4
            }
            
            TabButton {
                text: qsTr("Current")
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
                text: qsTr("Custom")
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
                text: qsTr("SIGPAC Code")
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
        
        // Tab content
        StackLayout {
            Layout.fillWidth: true
            currentIndex: tabBar.currentIndex
            
            // Current Position tab
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6 // Reduced spacing
                    
                    Label {
                        text: qsTr("Current Map Position:")
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
                        text: qsTr("Note: SIGPAC works with EPSG:4258 (ETRS89) or EPSG:4326 (WGS84)")
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
                        text: qsTr("Query SIGPAC")
                        Layout.alignment: Qt.AlignHCenter
                        enabled: !isLoading && sigpacService !== null
                        
                        background: Rectangle {
                            color: parent.enabled ? Theme.mainColor : Theme.controlBackgroundDisabledColor
                            radius: 4
                            implicitHeight: 36 // Smaller height for mobile
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
            
            // Custom Coordinates tab
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6 // Reduced spacing
                    
                    Label {
                        text: qsTr("Enter Custom Coordinates:")
                        font: Theme.strongTipFont
                        color: Theme.mainTextColor
                    }
                    
                    // SRID selection
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("SRID:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 60 // Smaller width
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
                        text: qsTr("Note: SIGPAC works with EPSG:4258 (ETRS89) or EPSG:4326 (WGS84)")
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
                    
                    // X coordinate
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("X:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 60 // Smaller width
                        }
                        
                        TextField {
                            id: xTextField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Enter X coordinate")
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
                    
                    // Y coordinate
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("Y:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 60 // Smaller width
                        }
                        
                        TextField {
                            id: yTextField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Enter Y coordinate")
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
                        text: qsTr("Query SIGPAC")
                        Layout.alignment: Qt.AlignHCenter
                        enabled: !isLoading && sigpacService !== null && xTextField.text !== "" && yTextField.text !== ""
                        
                        background: Rectangle {
                            color: parent.enabled ? Theme.mainColor : Theme.controlBackgroundDisabledColor
                            radius: 4
                            implicitHeight: 36 // Smaller height for mobile
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
            
            // SIGPAC Code tab
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6 // Reduced spacing
                    
                    Label {
                        text: qsTr("Enter SIGPAC Code:")
                        font: Theme.strongTipFont
                        color: Theme.mainTextColor
                    }
                    
                    // Province
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("Provincia:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 80 // Smaller width
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
                    
                    // Municipality
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("Municipio:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 80 // Smaller width
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
                    
                    // Agregado, Zona
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("Agregado:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 80 // Smaller width
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
                            Layout.preferredWidth: 60 // Smaller width
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
                    
                    // Polígono, Parcela
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("Polígono:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 80 // Smaller width
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
                            Layout.preferredWidth: 60 // Smaller width
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
                    
                    // Recinto
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 // Reduced spacing
                        
                        Label {
                            text: qsTr("Recinto:")
                            font: Theme.tipFont
                            color: Theme.mainTextColor
                            Layout.preferredWidth: 80 // Smaller width
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
                        text: qsTr("Query SIGPAC")
                        Layout.alignment: Qt.AlignHCenter
                        enabled: !isLoading && sigpacService !== null && 
                                provinciaTextField.text !== "" && 
                                municipioTextField.text !== "" && 
                                poligonoTextField.text !== "" && 
                                parcelaTextField.text !== "" && 
                                recintoTextField.text !== ""
                        
                        background: Rectangle {
                            color: parent.enabled ? Theme.mainColor : Theme.controlBackgroundDisabledColor
                            radius: 4
                            implicitHeight: 36 // Smaller height for mobile
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
        
        // Loading indicator
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
        
        // Additional data loading indicator
        RowLayout {
            visible: !isLoading && isLoadingAdditionalData
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            
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
                text: qsTr("Loading environmental data...")
                font: Theme.tinyFont
                color: Theme.secondaryTextColor
            }
        }
        
        // Error message
        Label {
            visible: errorMessage !== ""
            text: errorMessage
            color: Theme.errorColor
            font: Theme.tipFont
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Results area
        GroupBox {
            title: qsTr("SIGPAC Results")
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200 // Ensure there's enough space for the results
            
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
                anchors.margins: 4
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                width: parent.width - 8 // parent width minus margins
                implicitWidth: width
                
                TextArea {
                    id: resultsTextArea
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    font: Theme.tipFont
                    color: Theme.mainTextColor ? Theme.mainTextColor : "black" // Ensure color is never undefined
                    
                    background: Rectangle {
                        color: Theme.controlBackgroundColor ? Theme.controlBackgroundColor : "#f0f0f0" // Ensure color is never undefined
                        border.color: Theme.controlBorderColor ? Theme.controlBorderColor : "#cccccc" // Ensure color is never undefined
                        border.width: 1
                        radius: 4
                    }
                    
                    text: {
                        if (isLoading) {
                            return qsTr("Loading...");
                        } else if (errorMessage !== "") {
                            return qsTr("Error: %1").arg(errorMessage);
                        } else if (!sigpacResults) {
                            return qsTr("No results. Click 'Query SIGPAC' to get information.");
                        } else if (Array.isArray(sigpacResults) && sigpacResults.length === 0) {
                            return qsTr("No SIGPAC data found for this location.");
                        } else if (sigpacService) {
                            var result = sigpacService.formatSigpacData(sigpacResults);
                            if (isLoadingAdditionalData) {
                                result += "\n\n" + qsTr("Loading additional environmental data (Red Natura 2000, Fitosanitarios, Nitratos, Montanera, Pastos)...");
                            }
                            return result;
                        } else {
                            return qsTr("SIGPAC service not available");
                        }
                    }
                }
            }
        }
        
        // Buttons
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 6 // Reduced spacing
            
            Button {
                text: qsTr("Copy Results")
                font: Theme.tipFont
                visible: sigpacResults !== null && Array.isArray(sigpacResults) && sigpacResults.length > 0
                
                background: Rectangle {
                    color: Theme.mainColor
                    radius: 4
                    implicitHeight: 36 // Smaller height for mobile
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
                        // Show a brief toast or message that copying was successful
                        console.log("SIGPAC results copied to clipboard");
                    }
                }
            }
            
            Button {
                text: qsTr("Close")
                font: Theme.tipFont
                
                background: Rectangle {
                    color: Theme.mainColor
                    radius: 4
                    implicitHeight: 36 // Smaller height for mobile
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