import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import Theme 1.0

Rectangle {
    id: sigpacCodesRoot
    color: Theme.mainBackgroundColor
    property var currentCategoryData: null
    property var allCodesData: ({})

    property var codeCategories: [
        {name: "Provincias", endpoint: "https://sigpac-hubcloud.es/codigossigpac/provincia.json", key: "provincia"},
        {name: "Municipios", endpoint: "https://sigpac-hubcloud.es/codigossigpac/municipio", key: "municipio", requiresParam: true, paramName: "Provincia"},
        {name: "Uso SIGPAC", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_uso_sigpac.json", key: "cod_uso_sigpac"},
        {name: "Aprovechamiento", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_aprovechamiento.json", key: "cod_aprovechamiento"},
        {name: "Incidencia", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_incidencia.json", key: "cod_incidencia"},
        {name: "Ayuda Directa", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_lineasad.json", key: "cod_lineasad"},
        {name: "Ayuda Directa PDR", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_lineasad_pdr.json", key: "cod_lineasad_pdr"},
        {name: "Producto", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_producto.json", key: "cod_producto"},
        {name: "Región 2023", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_region_2023.json", key: "cod_region_2023"},
        {name: "Elementos Paisaje Área", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_tipo_e_paisaje.json", key: "cod_tipo_e_paisaje"},
        {name: "Elementos Paisaje Punto", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_tipo_e_paisaje_punto.json", key: "cod_tipo_e_paisaje_punto"},
        {name: "Elementos Paisaje Línea", endpoint: "https://sigpac-hubcloud.es/codigossigpac/cod_tipo_e_paisaje_linea.json", key: "cod_tipo_e_paisaje_linea"}
    ]
    
    signal codesLoaded(var categoryKey, var codesData)
    
    Component.onCompleted: {
        loadCodes(codeCategories[0])
    }
    
    function loadCodes(category) {
        var endpoint = category.endpoint
        
        if (category.requiresParam && !category.paramValue) {
            console.log("Parameter required for category: " + category.name)
            return
        }
        
        if (category.requiresParam) {
            endpoint = endpoint + category.paramValue + ".json"
        }
        
        if (allCodesData[category.key]) {
            currentCategoryData = allCodesData[category.key]
            codesLoaded(category.key, currentCategoryData)
            return
        }
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var data = JSON.parse(xhr.responseText)
                    allCodesData[category.key] = data
                    currentCategoryData = data
                    codesLoaded(category.key, data)
                } else {
                    console.error("Error loading data:", xhr.status, xhr.statusText)
                }
                loadingIndicator.running = false
            }
        }
        
        loadingIndicator.running = true
        xhr.open("GET", endpoint)
        xhr.send()
    }
    
    function searchCodes(searchText) {
        if (!currentCategoryData || !currentCategoryData.codigos || !searchText) {
            return currentCategoryData ? currentCategoryData.codigos : []
        }
        
        searchText = searchText.toLowerCase()
        
        return currentCategoryData.codigos.filter(function(item) {
            // Handle both string and numeric codes by converting everything to string for comparison
            var codeString = item.codigo.toString().toLowerCase()
            var descString = item.descripcion.toLowerCase()
            return codeString.includes(searchText) || descString.includes(searchText)
        })
    }
    
    function getMunicipiosByProvincia(provinciaCode) {
        var category = codeCategories.find(function(cat) { 
            return cat.key === "municipio" 
        })
        
        if (category) {
            category.paramValue = provinciaCode
            loadCodes(category)
        }
    }
    
    function getCodeDescription(categoryKey, codeValue) {
        if (!allCodesData[categoryKey] || !allCodesData[categoryKey].codigos) {
            return null
        }
        
        // Convert codeValue to string for comparison to handle both string and numeric codes
        var codeString = codeValue.toString()
        
        var codeItem = allCodesData[categoryKey].codigos.find(function(item) {
            return item.codigo.toString() === codeString
        })
        
        return codeItem ? codeItem.descripcion : null
    }
    
    // Helper function for natural sort of alphanumeric strings
    function naturalCompare(a, b) {
        // Convert to strings if they aren't already
        var as = a.toString();
        var bs = b.toString();
        
        // Check if both strings are numeric
        var anum = !isNaN(parseInt(as));
        var bnum = !isNaN(parseInt(bs));
        
        // If both are numeric, compare as numbers
        if (anum && bnum) {
            return parseInt(as) - parseInt(bs);
        }
        
        // If only one is numeric, numbers come before strings
        if (anum) return -1;
        if (bnum) return 1;
        
        // Otherwise do a straight string comparison
        return as.localeCompare(bs);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: Theme.mainColor
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                
                Text {
                    Layout.fillWidth: true
                    text: "Consulta Online de Códigos SIGPAC"
                    font.pixelSize: 20
                    font.bold: true
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                
                Button {
                    text: "Cerrar"
                    implicitWidth: 80
                    implicitHeight: 40
                    onClicked: sigpacCodesPanel.close()
                    
                    background: Rectangle {
                        color: parent.pressed ? Qt.darker(Theme.mainColor, 1.2) : "transparent"
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
        
        Text {
            Layout.fillWidth: true
            Layout.margins: 10
            text: "Documento offline con toda la codificación en menú Información"
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 13
            color: Theme.secondaryTextColor
            wrapMode: Text.WordWrap
        }
        
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10
            
            ComboBox {
                id: categoryCombo
                Layout.fillWidth: true
                model: codeCategories
                textRole: "name"
                
                onActivated: {
                    var selectedCategory = codeCategories[currentIndex]
                    
                    if (selectedCategory.requiresParam && !selectedCategory.paramValue) {
                        if (selectedCategory.key === "municipio") {
                            provinciaDialog.open()
                        }
                    } else {
                        loadCodes(selectedCategory)
                    }
                }
            }
            
            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Buscar..."
                
                onTextChanged: {
                    codesListModel.clear()
                    var results = searchCodes(text)
                    for (var i = 0; i < results.length; i++) {
                        addItemToModel(results[i])
                    }
                }
            }
        }
        
        BusyIndicator {
            id: loadingIndicator
            running: false
            Layout.alignment: Qt.AlignHCenter
            visible: running
        }
        
        ListView {
            id: codesListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            model: ListModel {
                id: codesListModel
            }
            
            delegate: Rectangle {
                width: codesListView.width
                height: 90
                color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 20
                    
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 40
                        color: Theme.mainColor
                        radius: 5
                        
                        Text {
                            anchors.centerIn: parent
                            text: model.codigoStr
                            font.bold: true
                            color: "white"
                        }
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        text: model.descripcion
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 4
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        codeDetailsPopup.codeValue = model.codigoStr
                        codeDetailsPopup.codeDescription = model.descripcion
                        codeDetailsPopup.open()
                    }
                }
            }
            
            onCountChanged: {
                if (count === 0 && !loadingIndicator.running && currentCategoryData) {
                    noResultsText.visible = true
                } else {
                    noResultsText.visible = false
                }
            }
        }
        
        Text {
            id: noResultsText
            Layout.alignment: Qt.AlignHCenter
            text: "No se encontraron resultados"
            visible: false
            font.pixelSize: 16
            color: "gray"
        }
    }
    
    // Add items to model with consistent types and sort data first
    function addItemToModel(item) {
        codesListModel.append({
            "codigoStr": item.codigo.toString(),  // Always use string for display
            "codigo": item.codigo,                // Original value (can be number or string)
            "descripcion": item.descripcion       // Description is always string
        })
    }
    
    // Sort the list model by code naturally
    function sortModelByCode() {
        // Create a temporary array to hold the model data
        var tempArray = [];
        for (var i = 0; i < codesListModel.count; i++) {
            tempArray.push({
                codigoStr: codesListModel.get(i).codigoStr,
                codigo: codesListModel.get(i).codigo,
                descripcion: codesListModel.get(i).descripcion
            });
        }
        
        // Sort the array using natural sort
        tempArray.sort(function(a, b) {
            return naturalCompare(a.codigo, b.codigo);
        });
        
        // Clear and repopulate the model with the sorted data
        codesListModel.clear();
        for (var j = 0; j < tempArray.length; j++) {
            codesListModel.append(tempArray[j]);
        }
    }
    
    Dialog {
        id: provinciaDialog
        title: "Seleccionar Provincia"
        width: parent.width * 0.8
        height: parent.height * 0.8
        anchors.centerIn: parent
        modal: true
        
        ColumnLayout {
            anchors.fill: parent
            
            TextField {
                id: provinciaSearchField
                Layout.fillWidth: true
                placeholderText: "Buscar provincia..."
                
                onTextChanged: {
                    provinciaListModel.clear()
                    if (!allCodesData["provincia"]) return
                    
                    var searchText = text.toLowerCase()
                    var provincias = allCodesData["provincia"].codigos
                    
                    for (var i = 0; i < provincias.length; i++) {
                        var prov = provincias[i]
                        if (prov.codigo.toString().includes(searchText) || 
                            prov.descripcion.toLowerCase().includes(searchText)) {
                            provinciaListModel.append({
                                "codigoStr": prov.codigo.toString(),
                                "codigo": prov.codigo,
                                "descripcion": prov.descripcion
                            })
                        }
                    }
                    
                    // Sort provinces by code naturally
                    sortProvinciasByCode();
                }
            }
            
            ListView {
                id: provinciaListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                model: ListModel {
                    id: provinciaListModel
                }
                
                delegate: Rectangle {
                    width: provinciaListView.width
                    height: 60
                    color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: model.codigoStr + " - " + model.descripcion
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var municipioCategory = codeCategories.find(function(cat) { 
                                return cat.key === "municipio" 
                            })
                            
                            municipioCategory.paramValue = model.codigo
                            provinciaDialog.close()
                            loadCodes(municipioCategory)
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                
                Button {
                    text: "Cancelar"
                    onClicked: provinciaDialog.close()
                }
            }
        }
        
        // Sort provinces by code naturally
        function sortProvinciasByCode() {
            var tempArray = [];
            for (var i = 0; i < provinciaListModel.count; i++) {
                tempArray.push({
                    codigoStr: provinciaListModel.get(i).codigoStr,
                    codigo: provinciaListModel.get(i).codigo,
                    descripcion: provinciaListModel.get(i).descripcion
                });
            }
            
            tempArray.sort(function(a, b) {
                return naturalCompare(a.codigo, b.codigo);
            });
            
            provinciaListModel.clear();
            for (var j = 0; j < tempArray.length; j++) {
                provinciaListModel.append(tempArray[j]);
            }
        }
    }
    
    Popup {
        id: codeDetailsPopup
        width: parent.width * 0.8
        height: 250
        anchors.centerIn: parent
        modal: true
        
        property string codeValue: ""
        property string codeDescription: ""
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20
            
            Text {
                Layout.fillWidth: true
                text: "Detalle del código"
                font.pixelSize: 18
                font.bold: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Código:"
                    font.bold: true
                }
                
                Text {
                    text: codeDetailsPopup.codeValue
                    font.bold: true
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text {
                    text: "Descripción:"
                    font.bold: true
                    Layout.alignment: Qt.AlignTop
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    Text {
                        width: parent.width
                        text: codeDetailsPopup.codeDescription
                        wrapMode: Text.WordWrap
                    }
                }
            }
            
            Button {
                Layout.alignment: Qt.AlignRight
                text: "Cerrar"
                onClicked: codeDetailsPopup.close()
            }
        }
    }
    
    Connections {
        target: sigpacCodesRoot
        
        function onCodesLoaded(categoryKey, codesData) {
            codesListModel.clear()
            
            if (!codesData || !codesData.codigos) return
            
            var codigos = codesData.codigos
            for (var i = 0; i < codigos.length; i++) {
                addItemToModel(codigos[i])
            }
            
            // Sort after loading data
            sortModelByCode()
        }
    }
} 