import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.qfield
import Theme

/**
 * \ingroup qml
 * Sentinel Hub Configuration Screen
 */
Popup {
  id: sentinelConfigScreen
  
  // Properties
  property string instanceId: ""
  property string custom1LayerId: ""
  property string custom2LayerId: ""
  property var selectedLayers: []
  property var layerStyles: ({
    "TRUE_COLOR": "ON",
    "FALSE_COLOR": "ON",
    "NDVI": "ON",
    "CUSTOM1": "DEFAULT",
    "CUSTOM2": "DEFAULT"
  })
  property var predefinedLayers: [
    {name: "True color", id: "TRUE_COLOR"},
    {name: "B1 - Coastal aerosol", id: "B01"},
    {name: "B2 - Blue", id: "B02"},
    {name: "B3 - Green", id: "B03"},
    {name: "B4 - Red", id: "B04"},
    {name: "B5 - Vegetation Red Edge (705 nm)", id: "B05"},
    {name: "B6 - Vegetation Red Edge (740 nm)", id: "B06"},
    {name: "B7 - Vegetation Red Edge (783 nm)", id: "B07"},
    {name: "B8 - Near infrared", id: "B08"},
    {name: "B8A - Vegetation Red Edge (865 nm)", id: "B8A"},
    {name: "B9 - Water vapour", id: "B09"},
    {name: "B10 - SWIR - Cirrus", id: "B10"},
    {name: "B11 - SWIR (1610 nm)", id: "B11"},
    {name: "B12 - SWIR (2190 nm)", id: "B12"},
    {name: "Agriculture", id: "AGRICULTURE"},
    {name: "ARI1 (Anthocyanin Reflectance Index)", id: "ARI1"},
    {name: "ARI2 (Anthocyanin Reflectance Index)", id: "ARI2"},
    {name: "Atmospheric penetration", id: "ATMOSPHERIC_PENETRATION"},
    {name: "BAI (Burn Area Index)", id: "BAI"},
    {name: "Bathymetric", id: "BATHYMETRIC"},
    {name: "CHL-RED-EDGE (Chlorophyll Red-Edge)", id: "CHL_RED_EDGE"},
    {name: "CRI1 (Carotenoid Reflectance Index 1)", id: "CRI1"},
    {name: "CRI2 (Carotenoid Reflectance Index 2)", id: "CRI2"},
    {name: "EVI (Enhanced Vegetation Index)", id: "EVI"},
    {name: "EVI2 (Enhanced Vegetation Index 2)", id: "EVI2"},
    {name: "False color (urban)", id: "FALSE_COLOR_URBAN"},
    {name: "False color (vegetation)", id: "FALSE_COLOR"},
    {name: "Geology", id: "GEOLOGY"},
    {name: "GRVI1 (Green-red Vegetation Index)", id: "GRVI1"},
    {name: "LAI-SAVI (Leaf Area Index - Soil Adjusted Vegetation Index)", id: "LAI_SAVI"},
    {name: "Moisture Index", id: "MOISTURE_INDEX"},
    {name: "MSAVI2 (Second Modified Soil Adjusted Vegetation Index)", id: "MSAVI2"},
    {name: "NBR-RAW (Normalized Burn Ratio)", id: "NBR_RAW"},
    {name: "NDVI (Normalized Difference Vegetation Index)", id: "NDVI"},
    {name: "NDVI-GRAY (Normalized Difference Vegetation Index - Grayscale)", id: "NDVI_GRAY"},
    {name: "NDVI-GREEN (Normalized Difference Vegetation Index - Green)", id: "NDVI_GREEN_GRAY"},
    {name: "NDWI (Normalized Difference Water Index)", id: "NDWI"},
    {name: "PSRI (Plant Senescence Reflectance Index)", id: "PSRI"},
    {name: "PSRI-NIR (Plant Senescence Reflectance Index - Near Infra-red)", id: "PSRI_NIR"},
    {name: "RE-NDWI (Red Edge - Normalized Difference Water Index)", id: "RE_NDWI"},
    {name: "Red edge NDVI", id: "RED_EDGE_NDVI"},
    {name: "RGB (11,8,3)", id: "RGB_11_8_3"},
    {name: "RGB (4,3,1) - Bathymetric", id: "RGB_4_3_1"},
    {name: "RGB (8,11,12)", id: "RGB_8_11_12"},
    {name: "RGB (8,11,4)", id: "RGB_8_11_4"},
    {name: "RGB (8,5,4)", id: "RGB_8_5_4"},
    {name: "RGB (8,6,4)", id: "RGB_8_6_4"},
    {name: "SAVI (Soil Adjusted Vegetation Index)", id: "SAVI"},
    {name: "SWIR", id: "SWIR"}
  ]
  
  // Layout
  x: 0
  y: 0
  width: mainWindow.width
  height: mainWindow.height
  padding: 0
  
  parent: mainWindow.contentItem
  modal: true
  focus: true
  
  // Background
  background: Rectangle {
    color: Theme.mainBackgroundColor
  }
  
  // Content
  ColumnLayout {
    anchors.fill: parent
    spacing: 0
    
    // Header
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 56
      color: Theme.mainColor
      
      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        
        QfToolButton {
          Layout.preferredHeight: 48
          Layout.preferredWidth: 48
          
          iconSource: Theme.getThemeVectorIcon("ic_close_white_24dp")
          iconColor: "white"
          bgcolor: "transparent"
          
          onClicked: {
            sentinelConfigScreen.close()
          }
        }
        
        Label {
          Layout.fillWidth: true
          text: qsTr("Configuración de Sentinel Hub")
          font.pixelSize: 20
          font.bold: true
          color: "white"
        }
        
        QfToolButton {
          Layout.preferredHeight: 48
          Layout.preferredWidth: 48
          
          iconSource: Theme.getThemeVectorIcon("ic_check_white_24dp")
          iconColor: "white"
          bgcolor: "transparent"
          
          onClicked: {
            // Check if settings object exists
            if (typeof settings === 'undefined' || settings === null) {
              console.log("Settings object is null or undefined")
              mainWindow.displayToast(qsTr("Error: Settings object is not available"))
              return
            }
            
            // Save layer settings first
            saveLayerSettings()
            
            // Save WMS parameters
            settings.setValue("QField/Sentinel/CRS", crsCombo.currentText)
            settings.setValue("QField/Sentinel/Format", formatCombo.currentText)
            settings.setValue("QField/Sentinel/DPIMode", dpiModeField.text)
            settings.setValue("QField/Sentinel/TilePixelRatio", tilePixelRatioField.text)
            
            if (enableTimeRange.checked) {
              settings.setValue("QField/Sentinel/TimeEnabled", true)
              settings.setValue("QField/Sentinel/TimeStart", startDateField.text)
              settings.setValue("QField/Sentinel/TimeEnd", endDateField.text)
            } else {
              settings.setValue("QField/Sentinel/TimeEnabled", false)
            }
            
            // Save advanced parameters
            settings.setValue("QField/Sentinel/AdvancedParamsEnabled", showAdvancedParams.checked)
            if (showAdvancedParams.checked) {
              settings.setValue("QField/Sentinel/MAXCC", maxCCField.text)
              settings.setValue("QField/Sentinel/QUALITY", qualityField.text)
              settings.setValue("QField/Sentinel/WARNINGS", warningsCombo.currentText)
              settings.setValue("QField/Sentinel/PRIORITY", priorityCombo.currentText)
            }
            
            // Save BBOX limiting settings
            settings.setValue("QField/Sentinel/BboxLimitingEnabled", enableBboxLimiting.checked)
            if (enableBboxLimiting.checked) {
              settings.setValue("QField/Sentinel/BboxWidth", bboxWidthField.text)
              settings.setValue("QField/Sentinel/BboxHeight", bboxHeightField.text)
            }
            
            // Save rate limiting settings
            settings.setValue("QField/Sentinel/RateLimitingEnabled", enableRateLimiting.checked)
            if (enableRateLimiting.checked) {
              settings.setValue("QField/Sentinel/RateLimitDelay", rateLimitDelayField.text)
            }
            
            // Save custom script settings - commented out as they don't work
            /*
            settings.setValue("QField/Sentinel/CustomScriptEnabled", enableCustomScript.checked)
            if (enableCustomScript.checked) {
              settings.setValue("QField/Sentinel/ScriptUrl", scriptUrlField.text)
              settings.setValue("QField/Sentinel/CustomScript", customScriptField.text)
            }
            
            // Save custom layer script settings
            settings.setValue("QField/Sentinel/EvalScriptUrl", customEvalScriptUrlField.text)
            settings.setValue("QField/Sentinel/EvalScript", customEvalScriptField.text)
            */
            
            // Set a flag to force reload of layers
            settings.setValue("QField/Sentinel/SettingsChanged", true)
            
            mainWindow.displayToast(qsTr("Sentinel settings saved. Restart QField or reload your project for changes to take effect."))
            
            // Close the screen
            sentinelConfigScreen.close()
          }
        }
      }
    }
    
    // Tab Bar
    QfTabBar {
      id: tabBar
      Layout.fillWidth: true
      Layout.preferredHeight: defaultHeight
      model: [qsTr("Básico"), qsTr("Capas"), qsTr("Constructor de Consultas")]
    }
    
    // Tab Content
    SwipeView {
      id: swipeView
      Layout.fillWidth: true
      Layout.fillHeight: true
      currentIndex: tabBar.currentIndex
      clip: true
      
      onCurrentIndexChanged: {
        tabBar.currentIndex = currentIndex
      }
      
      // Basic Settings Tab
      Item {
        ScrollView {
          anchors.fill: parent
          contentWidth: basicSettingsColumn.width
          contentHeight: basicSettingsColumn.height
          clip: true
          
          ColumnLayout {
            id: basicSettingsColumn
            width: swipeView.width
            spacing: 20
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.topMargin: 20
              text: qsTr("ID de Instancia de Sentinel Hub")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            TextField {
              id: instanceIdField
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: sentinelConfigScreen.instanceId
              placeholderText: qsTr("Ingrese su ID de instancia de Sentinel Hub")
              font: Theme.defaultFont
              
              onTextChanged: {
                updatePreview()
              }
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("El ID de instancia es necesario para acceder a los servicios WMS de Sentinel Hub. Puede encontrarlo en su cuenta de Copernicus Data Space Ecosystem.")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("Más información sobre <a href='https://dataspace.copernicus.eu/'>Copernicus Data Space Ecosystem</a>")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              textFormat: Qt.RichText
              wrapMode: Text.WordWrap
              onLinkActivated: link => {
                Qt.openUrlExternally(link)
              }
            }
            
            Rectangle {
              Layout.fillWidth: true
              height: 1
              color: Theme.mainColor
              Layout.topMargin: 10
              Layout.bottomMargin: 10
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("Cómo obtener un ID de Instancia de Sentinel Hub:")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("1. Cree una cuenta en <a href='https://dataspace.copernicus.eu/'>dataspace.copernicus.eu</a>")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              textFormat: Qt.RichText
              wrapMode: Text.WordWrap
              onLinkActivated: link => {
                Qt.openUrlExternally(link)
              }
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("2. Cree una nueva configuración")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("3. Encuentre su ID de instancia en los detalles de configuración")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("El nivel gratuito incluye 30,000 unidades de procesamiento por mes")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            Item {
              Layout.fillHeight: true
            }
          }
        }
      }
      
      // Layers Tab
      Item {
        ScrollView {
          anchors.fill: parent
          contentWidth: parent.width
          clip: true
          
          ColumnLayout {
            id: layersColumn
            width: swipeView.width
            spacing: 50
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.topMargin: 40
              text: qsTr("Capas de Sentinel Disponibles")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.bottomMargin: 20
              text: qsTr("Active las capas para incluirlas en sus proyectos")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            // Layer Card Component
            Component {
              id: layerCardComponent
              
              Rectangle {
                property string layerName: ""
                property string layerDescription: ""
                property bool isChecked: false
                property string currentStyle: "ON"
                property bool hasCustomOptions: false
                property string customId: ""
                property string scriptUrl: ""
                property string scriptContent: ""
                property bool hasLayerDropdown: false
                property string selectedLayerId: ""
                
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: hasLayerDropdown ? 250 : (hasCustomOptions ? 350 : 150)
                Layout.bottomMargin: 40
                color: Theme.toolButtonBackgroundColor
                radius: 8
                
                ColumnLayout {
                  id: layerCardContent
                  anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 25
                  }
                  spacing: 25
                  
                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 30
                    
                    Switch {
                      id: layerSwitch
                      checked: isChecked
                      
                      onCheckedChanged: {
                        isChecked = checked
                        if (checked) {
                          // Add layer to selectedLayers when checked
                          if (!selectedLayers.includes(layerName)) {
                            selectedLayers.push(layerName)
                          }
                          // Set default style when adding a layer
                          if (!layerStyles[layerName]) {
                            layerStyles[layerName] = layerName.startsWith("CUSTOM") ? "DEFAULT" : "ON"
                            currentStyle = layerStyles[layerName]
                            if (layerName.startsWith("CUSTOM")) {
                              styleCombo.currentIndex = 0 // DEFAULT
                            } else {
                              styleCombo.currentIndex = 0 // ON
                            }
                          }
                        } else {
                          // Remove layer from selectedLayers when unchecked
                          selectedLayers = selectedLayers.filter(layer => layer !== layerName)
                        }
                        
                        // Save the toggle state immediately
                        if (typeof settings !== 'undefined' && settings !== null) {
                          saveLayerSettings()
                        }
                        
                        updatePreview()
                      }
                    }
                    
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: -25
                      
                      Label {
                        text: layerName
                        font.bold: true
                        color: Theme.mainTextColor
                      }
                      
                      Label {
                        text: layerDescription
                        font: Theme.tipFont
                        color: Theme.secondaryTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                      }
                      
                      // Layer dropdown for predefined layers - always in layout but visibility controlled
                      Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80 // Fixed height to prevent movement
                        clip: true
                        visible: hasLayerDropdown
                        
                        ColumnLayout {
                          id: layerDropdownColumn
                          anchors.fill: parent
                          opacity: layerSwitch.checked ? 1.0 : 0.0
                          enabled: layerSwitch.checked
                          spacing: -10
                          
                          ComboBox {
                            id: layerDropdown
                            Layout.fillWidth: true
                            enabled: layerSwitch.checked
                            model: []
                            textRole: "text"
                            
                            Component.onCompleted: {
                              // Populate the dropdown with predefined layers
                              let items = []
                              for (let i = 0; i < predefinedLayers.length; i++) {
                                items.push({
                                  text: predefinedLayers[i].name,
                                  value: predefinedLayers[i].id
                                })
                              }
                              model = items
                              
                              // Set initial selection based on selectedLayerId
                              for (let i = 0; i < items.length; i++) {
                                if (items[i].value === selectedLayerId) {
                                  currentIndex = i
                                  break
                                }
                              }
                            }
                            
                            onCurrentIndexChanged: {
                              if (currentIndex >= 0 && currentIndex < model.length) {
                                selectedLayerId = model[currentIndex].value
                                updatePreview()
                                
                                // Save the selected layer ID immediately
                                if (typeof settings !== 'undefined' && settings !== null) {
                                  if (layerName === "TRUE_COLOR") {
                                    settings.setValue("QField/Sentinel/TrueColorLayerId", selectedLayerId)
                                  } else if (layerName === "FALSE_COLOR") {
                                    settings.setValue("QField/Sentinel/FalseColorLayerId", selectedLayerId)
                                  } else if (layerName === "NDVI") {
                                    settings.setValue("QField/Sentinel/NdviLayerId", selectedLayerId)
                                  }
                                  settings.setValue("QField/Sentinel/SettingsUpdated", true)
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                    
                    ColumnLayout {
                      spacing: 5
                      Layout.preferredWidth: 120
                      Layout.alignment: Qt.AlignTop
                      
                      Label {
                        text: qsTr("Estilo")
                        font: Theme.tipFont
                        color: Theme.secondaryTextColor
                        Layout.alignment: Qt.AlignHCenter
                      }
                      
                      ComboBox {
                        id: styleCombo
                        model: layerName.startsWith("CUSTOM") ? ["DEFAULT", "ON", "OFF"] : ["ON", "OFF"]
                        currentIndex: layerName.startsWith("CUSTOM") ? 
                                      (currentStyle === "DEFAULT" ? 0 : (currentStyle === "ON" ? 1 : 2)) : 
                                      (currentStyle === "ON" ? 0 : 1)
                        enabled: layerSwitch.checked
                        Layout.preferredWidth: 120
                        
                        onCurrentTextChanged: {
                          currentStyle = currentText
                          layerStyles[layerName] = currentText
                          
                          // Save the style setting immediately
                          if (typeof settings !== 'undefined' && settings !== null) {
                            settings.setValue("QField/Sentinel/Styles/" + layerName, currentText)
                            settings.setValue("QField/Sentinel/SettingsUpdated", true)
                            saveLayerSettings()
                          }
                          
                          updatePreview()
                        }
                      }
                    }
                  }
                  
                  // Custom options container (only visible for Custom layers)
                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180 // Fixed height to prevent movement
                    clip: true
                    visible: hasCustomOptions
                    
                    ColumnLayout {
                      id: customOptionsLayout
                      width: parent.width
                      opacity: layerSwitch.checked ? 1.0 : 0.0
                      enabled: layerSwitch.checked
                      spacing: 10
                      
                      Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Theme.secondaryTextColor
                        opacity: 0.3
                        Layout.bottomMargin: 5
                      }
                      
                      // Custom Layer ID Section
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        
                        Label {
                          text: qsTr("ID de Capa Personalizada:")
                          font: Theme.defaultFont
                          color: Theme.mainColor
                        }
                        
                        TextField {
                          id: layerIdField
                          Layout.fillWidth: true
                          Layout.topMargin: 0
                          placeholderText: qsTr("Ingrese ID de capa (ej., AGRICULTURE)")
                          text: customId
                          enabled: layerSwitch.checked
                          
                          onTextChanged: {
                            customId = text
                            if (layerName === "CUSTOM1") {
                              sentinelConfigScreen.custom1LayerId = text
                            } else if (layerName === "CUSTOM2") {
                              sentinelConfigScreen.custom2LayerId = text
                            }
                            updatePreview()
                            
                            // Save the custom layer ID immediately
                            if (typeof settings !== 'undefined' && settings !== null) {
                              if (layerName === "CUSTOM1") {
                                settings.setValue("QField/Sentinel/Custom1LayerId", text)
                              } else if (layerName === "CUSTOM2") {
                                settings.setValue("QField/Sentinel/Custom2LayerId", text)
                              }
                              settings.setValue("QField/Sentinel/SettingsUpdated", true)
                            }
                          }
                        }
                        
                        Label {
                          visible: layerIdField.text.trim() === ""
                          text: qsTr("Por favor ingrese un ID para la capa personalizada")
                          font: Theme.tipFont
                          color: Theme.warningColor
                          wrapMode: Text.WordWrap
                        }
                      }
                      
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 15
                        Layout.topMargin: 20
                        visible: false // Hide script options
                      }
                    }
                  }
                }
                
                Component.onCompleted: {
                  // Initialize the switch state based on selectedLayers
                  layerSwitch.checked = selectedLayers.includes(layerName)
                  
                  // Initialize the style combo based on layerStyles
                  if (layerStyles[layerName]) {
                    currentStyle = layerStyles[layerName]
                    if (layerName.startsWith("CUSTOM")) {
                      styleCombo.currentIndex = currentStyle === "DEFAULT" ? 0 : (currentStyle === "ON" ? 1 : 2)
                    } else {
                      styleCombo.currentIndex = currentStyle === "ON" ? 0 : 1
                    }
                  }
                }
              }
            }
            
            // True Color Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "TRUE_COLOR"
                item.layerDescription = ""
                item.isChecked = selectedLayers.includes("TRUE_COLOR")
                item.currentStyle = layerStyles["TRUE_COLOR"] || "ON"
                item.hasLayerDropdown = true
                item.selectedLayerId = settings.value("QField/Sentinel/TrueColorLayerId", "TRUE_COLOR")
              }
            }
            
            // False Color Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "FALSE_COLOR"
                item.layerDescription = ""
                item.isChecked = selectedLayers.includes("FALSE_COLOR")
                item.currentStyle = layerStyles["FALSE_COLOR"] || "ON"
                item.hasLayerDropdown = true
                item.selectedLayerId = settings.value("QField/Sentinel/FalseColorLayerId", "FALSE_COLOR")
              }
            }
            
            // NDVI Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "NDVI"
                item.layerDescription = ""
                item.isChecked = selectedLayers.includes("NDVI")
                item.currentStyle = layerStyles["NDVI"] || "ON"
                item.hasLayerDropdown = true
                item.selectedLayerId = settings.value("QField/Sentinel/NdviLayerId", "NDVI")
              }
            }
            
            // Custom1 Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "CUSTOM1"
                item.layerDescription = qsTr("Capa personalizada con ID configurable")
                item.isChecked = selectedLayers.includes("CUSTOM1")
                item.currentStyle = layerStyles["CUSTOM1"] || "DEFAULT"
                item.hasCustomOptions = true
                item.customId = sentinelConfigScreen.custom1LayerId
              }
            }
            
            // Custom2 Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "CUSTOM2"
                item.layerDescription = qsTr("Capa personalizada con ID configurable")
                item.isChecked = selectedLayers.includes("CUSTOM2")
                item.currentStyle = layerStyles["CUSTOM2"] || "DEFAULT"
                item.hasCustomOptions = true
                item.customId = sentinelConfigScreen.custom2LayerId
              }
            }
            
            // Save All Button for Layers Tab
            Button {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.preferredHeight: 40
              Layout.topMargin: 200
              Layout.bottomMargin: 5
              
              text: qsTr("Guardar Configuración de Capas")
              font.bold: true
              
              onClicked: {
                // Make sure to get the latest values from the custom layer
                if (customLayerLoader && customLayerLoader.item) {
                  sentinelConfigScreen.customLayerId = customLayerLoader.item.customId
                  sentinelConfigScreen.evalScriptUrl = customLayerLoader.item.scriptUrl
                  sentinelConfigScreen.evalScript = customLayerLoader.item.scriptContent
                }
                
                saveLayerSettings()
                mainWindow.displayToast(qsTr("Configuración de capas guardada"))
              }
            }
            
            // Layer Style Options Help Section - moved below the custom fields
            Rectangle {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.topMargin: 40
              Layout.preferredHeight: helpContent.height + 20
              color: Qt.darker(Theme.mainBackgroundColor, 1.05)
              radius: 8
              
              ColumnLayout {
                id: helpContent
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  margins: 5
                }
                spacing: 4
                
                Label {
                  text: qsTr("Opciones de Estilo de Capa")
                  font.bold: true
                  color: Theme.mainColor
                }
                
                Label {
                  Layout.fillWidth: true
                  text: qsTr("Interruptor: Controla si la capa está incluida en su proyecto")
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                }
                
                Label {
                  Layout.fillWidth: true
                  text: qsTr("ON: La capa es visible con el estilo predeterminado")
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                }
                
                Label {
                  Layout.fillWidth: true
                  text: qsTr("OFF: La capa está incluida pero inicialmente oculta")
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                }
                
                Label {
                  Layout.fillWidth: true
                  text: qsTr("DEFAULT: Usa el estilo predeterminado de Sentinel Hub (solo capa personalizada)")
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                }
              }
            }
            
            Item {
              Layout.fillHeight: true
              Layout.minimumHeight: 40
            }
          }
        }
      }
      // Help section
            
      // Query Builder Tab
      Item {
        ScrollView {
          anchors.fill: parent
          contentWidth: queryBuilderColumn.width
          contentHeight: queryBuilderColumn.height
          clip: true
          
          ColumnLayout {
            id: queryBuilderColumn
            width: swipeView.width
            spacing: 20
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.topMargin: 20
              text: qsTr("Constructor de Consultas WMS")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("Configure parámetros adicionales de WMS:")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            // CRS Selection
            RowLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              
              Label {
                text: qsTr("CRS:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              ComboBox {
                id: crsCombo
                Layout.fillWidth: true
                model: ["EPSG:4326", "EPSG:3857", "EPSG:3035"]
                currentIndex: 0
                
                onCurrentTextChanged: {
                  updatePreview()
                }
              }
            }
            
            // Format Selection
            RowLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              
              Label {
                text: qsTr("Formato:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              ComboBox {
                id: formatCombo
                Layout.fillWidth: true
                model: ["image/png", "image/jpeg", "image/tiff"]
                currentIndex: 0
                
                onCurrentTextChanged: {
                  updatePreview()
                }
              }
            }
            
            // Time Range
            CheckBox {
              id: enableTimeRange
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("Habilitar rango de tiempo")
              checked: false
              
              onCheckedChanged: {
                updatePreview()
              }
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("El rango de tiempo permite filtrar imágenes por fecha. Sentinel Hub devolverá la imagen más reciente dentro del rango de fechas especificado que cumpla con sus criterios (por ejemplo, cobertura de nubes).")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
              visible: enableTimeRange.checked
            }
            
            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              columns: 2
              enabled: enableTimeRange.checked
              opacity: enableTimeRange.checked ? 1.0 : 0.5
              
              Label {
                text: qsTr("Fecha de inicio:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: startDateField
                Layout.fillWidth: true
                text: new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0]
                placeholderText: "AAAA-MM-DD"
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                text: qsTr("Fecha de fin:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: endDateField
                Layout.fillWidth: true
                text: new Date().toISOString().split('T')[0]
                placeholderText: "AAAA-MM-DD"
                
                onTextChanged: {
                  updatePreview()
                }
              }
            }
            
            // Advanced Parameters
            CheckBox {
              id: showAdvancedParams
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("Mostrar parámetros avanzados")
              checked: false
            }
            
            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              columns: 2
              visible: showAdvancedParams.checked
              
              Label {
                text: qsTr("Modo DPI:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: dpiModeField
                Layout.fillWidth: true
                text: "7"
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("El Modo DPI controla la resolución de las imágenes WMS. Valores más altos significan mayor resolución pero usan más créditos.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Relación de Píxeles de Tesela:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: tilePixelRatioField
                Layout.fillWidth: true
                text: "0"
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("La Relación de Píxeles de Tesela afecta la resolución de las teselas. Valores más altos usan más créditos.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Cobertura Máxima de Nubes (%):")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: maxCCField
                Layout.fillWidth: true
                text: "100"
                placeholderText: "0-100"
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Cobertura máxima permitida de nubes en porcentaje. Valores más bajos pueden resultar en menos imágenes disponibles.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Calidad (solo JPEG):")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: qualityField
                Layout.fillWidth: true
                text: "90"
                placeholderText: "0-100"
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                text: qsTr("Mostrar Advertencias:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              ComboBox {
                id: warningsCombo
                Layout.fillWidth: true
                model: ["SÍ", "NO"]
                currentIndex: 0
                
                onCurrentTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                text: qsTr("Prioridad:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              ComboBox {
                id: priorityCombo
                Layout.fillWidth: true
                model: ["másReciente", "menosReciente", "menosCC", "menorDiferenciaTiempo"]
                currentIndex: 0
                
                onCurrentTextChanged: {
                  updatePreview()
                }
              }
              
              // Credit Usage Limiting Options
              Label {
                Layout.columnSpan: 2
                Layout.topMargin: 10
                text: qsTr("Opciones de Limitación de Uso de Créditos")
                font.bold: true
                color: Theme.mainColor
              }
              
              Label {
                text: qsTr("Habilitar Limitación de BBOX:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              CheckBox {
                id: enableBboxLimiting
                checked: false
                
                onCheckedChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Limitar BBOX restringe el área solicitada, ahorrando créditos de procesamiento.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Ancho de BBOX (m):")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: enableBboxLimiting.checked
              }
              
              TextField {
                id: bboxWidthField
                Layout.fillWidth: true
                text: "10000"
                enabled: enableBboxLimiting.checked
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                text: qsTr("Alto de BBOX (m):")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: enableBboxLimiting.checked
              }
              
              TextField {
                id: bboxHeightField
                Layout.fillWidth: true
                text: "10000"
                enabled: enableBboxLimiting.checked
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                text: qsTr("Habilitar Limitación de Tasa:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              CheckBox {
                id: enableRateLimiting
                checked: false
                
                onCheckedChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("La limitación de tasa agrega un retraso entre solicitudes para evitar un uso excesivo de créditos.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Retraso Entre Solicitudes (ms):")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: enableRateLimiting.checked
              }
              
              TextField {
                id: rateLimitDelayField
                Layout.fillWidth: true
                text: "1000"
                enabled: enableRateLimiting.checked
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              // Custom Script Options
              Label {
                Layout.columnSpan: 2
                Layout.topMargin: 20
                Layout.bottomMargin: 10
                text: qsTr("Custom Script Options")
                font.bold: true
                font.pixelSize: 16
                color: Theme.mainColor
                visible: false
              }
              
              Label {
                text: qsTr("Enable Custom Script:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                visible: false
              }
              
              CheckBox {
                id: enableCustomScript
                checked: false
                visible: false
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Custom scripts allow advanced processing but may use more credits.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                visible: false
              }
              
              Label {
                text: qsTr("Script URL:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: enableCustomScript.checked
                visible: false
              }
              
              TextField {
                id: scriptUrlField
                Layout.fillWidth: true
                text: ""
                placeholderText: "https://example.com/script.js"
                enabled: enableCustomScript.checked
                visible: false
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("OR")
                font.bold: true
                color: Theme.mainTextColor
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                enabled: enableCustomScript.checked
                visible: false
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Custom Evaluation Script:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: enableCustomScript.checked
                visible: false
              }
              
              TextArea {
                id: customScriptField
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                enabled: enableCustomScript.checked
                placeholderText: "//VERSION=3\nfunction setup() {\n  return {\n    input: [\"B02\", \"B03\", \"B04\"],\n    output: { bands: 3 }\n  };\n}\n\nfunction evaluatePixel(sample) {\n  return [sample.B04, sample.B03, sample.B02];\n}"
                wrapMode: TextEdit.Wrap
                font.family: "monospace"
                font.pixelSize: 12
                topPadding: 10
                leftPadding: 10
                rightPadding: 10
                bottomPadding: 10
                background: Rectangle {
                  color: Qt.darker(Theme.mainBackgroundColor, 1.2)
                  border.color: Theme.secondaryTextColor
                  border.width: 1
                  radius: 4
                }
                visible: false
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Note: Custom scripts will be BASE64 encoded automatically. Either provide a Script URL OR a Custom Script, not both.")
                font: Theme.tipFont
                color: Theme.warningColor
                wrapMode: Text.WordWrap
                enabled: enableCustomScript.checked
                visible: false
              }
              
              Button {
                Layout.columnSpan: 2
                text: qsTr("Save Script to Library")
                enabled: enableCustomScript.checked && customScriptField.text.length > 0
                Layout.alignment: Qt.AlignRight
                visible: false
              }
              
              ComboBox {
                id: savedScriptsCombo
                Layout.columnSpan: 2
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                enabled: enableCustomScript.checked
                model: []
                visible: false
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Select a saved script from the dropdown above")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                visible: false
              }
              
              Button {
                Layout.columnSpan: 2
                text: qsTr("Delete Selected Script")
                enabled: enableCustomScript.checked && savedScriptsCombo.currentIndex > 0
                Layout.alignment: Qt.AlignRight
                visible: false
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("WMS vs WMTS")
                font.bold: true
                color: Theme.mainColor
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("WMS (Servicio de Mapas Web) proporciona imágenes generadas a pedido, ideal para NDVI y análisis de cultivos con parámetros flexibles.\n\nWMTS (Servicio de Teselas de Mapas Web) utiliza teselas pre-renderizadas, más rápido pero menos flexible para análisis personalizados. Para monitoreo de cultivos, generalmente se prefiere WMS.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.topMargin: 10
              visible: showAdvancedParams.checked
              text: qsTr("Nota: Los parámetros avanzados pueden afectar significativamente el uso de créditos de Sentinel Hub. Úselos con precaución.")
              font: Theme.tipFont
              color: Theme.warningColor
              wrapMode: Text.WordWrap
            }
            
            Item {
              Layout.fillHeight: true
            }
          }
        }
      }
    }
    
    // Preview Section
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 250
      Layout.leftMargin: 20
      Layout.rightMargin: 20
      Layout.bottomMargin: 5
      color: Qt.darker(Theme.mainBackgroundColor, 1.1)
      radius: 8
      
      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 1
        
        Label {
          text: qsTr("Vista Previa de URL WMS")
          font.bold: true
          color: Theme.mainTextColor
        }
        
        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.topMargin: 10
          
          TextArea {
            id: previewText
            readOnly: true
            wrapMode: TextEdit.Wrap
            font.family: "monospace"
            font.pixelSize: 16
            color: Theme.mainTextColor
            width: parent.width
            height: parent.height
            topPadding: 5
            leftPadding: 20
            rightPadding: 20
            bottomPadding: 20
            background: Rectangle {
              color: Qt.darker(Theme.mainBackgroundColor, 1.2)
              border.color: Theme.secondaryTextColor
              border.width: 1
              radius: 6
            }
          }
        }
        
        Button {
          text: qsTr("Copiar al Portapapeles")
          Layout.alignment: Qt.AlignRight
          Layout.preferredHeight: 30
          Layout.preferredWidth: 180
          
          onClicked: {
            // Check if clipboard is available
            if (typeof mainWindow.clipboard !== 'undefined' && mainWindow.clipboard) {
              mainWindow.clipboard.setText(previewText.text)
              mainWindow.displayToast(qsTr("URL copiada al portapapeles"))
            } else {
              // Fallback if clipboard is not available
              console.log("Clipboard not available, URL: " + previewText.text)
              mainWindow.displayToast(qsTr("Portapapeles no disponible. Ver consola para URL."))
            }
          }
        }
      }
    }
  }
  
  // Save Script Dialog
  Dialog {
    id: saveScriptDialog
    title: qsTr("Guardar Script")
    standardButtons: Dialog.Save | Dialog.Cancel
    modal: true
    
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width - 50, 400)
    
    ColumnLayout {
      width: parent.width
      
      Label {
        text: qsTr("Nombre del Script:")
        font: Theme.defaultFont
      }
      
      TextField {
        id: scriptNameField
        Layout.fillWidth: true
        placeholderText: qsTr("Ingrese un nombre para su script")
      }
    }
    
    onAccepted: {
      if (scriptNameField.text.trim() === "") {
        mainWindow.displayToast(qsTr("Por favor ingrese un nombre para su script"))
        return
      }
      
      // Check if settings object exists
      if (typeof settings === 'undefined' || settings === null) {
        console.log("Settings object is null or undefined")
        mainWindow.displayToast(qsTr("Error: El objeto de configuración no está disponible"))
        return
      }
      
      // Save the script
      let scriptName = scriptNameField.text.trim()
      settings.setValue("QField/Sentinel/SavedScripts/" + scriptName, customScriptField.text)
      
      // Update the scripts list by adding the new script name to the list
      let scriptNames = settings.value("QField/Sentinel/SavedScriptsList", "").toString()
      let scriptNamesList = scriptNames ? scriptNames.split(",") : []
      
      // Check if the script name already exists
      if (!scriptNamesList.includes(scriptName)) {
        scriptNamesList.push(scriptName)
        settings.setValue("QField/Sentinel/SavedScriptsList", scriptNamesList.join(","))
      }
      
      // Update the scripts list
      loadSavedScripts()
      
      // Select the newly saved script
      let index = savedScriptsCombo.find(scriptName)
      if (index !== -1) {
        savedScriptsCombo.currentIndex = index
      }
      
      mainWindow.displayToast(qsTr("Script guardado: ") + scriptName)
      scriptNameField.text = ""
    }
  }
  
  // Functions
  function updatePreview() {
    // Get the instance ID from the field
    let instanceId = instanceIdField ? instanceIdField.text : ""
    
    if (!instanceId) {
      previewText.text = qsTr("Por favor ingrese un ID de instancia de Sentinel Hub")
      return
    }
    
    // Get the selected layer and its ID
    let selectedLayer = selectedLayers.length > 0 ? selectedLayers[0] : ""
    if (!selectedLayer) {
      previewText.text = qsTr("Por favor seleccione al menos una capa")
      return
    }
    
    let layerId = ""
    let style = ""
    
    // Determine the layer ID and style based on the selected layer
    if (selectedLayer === "TRUE_COLOR") {
      layerId = settings.value("QField/Sentinel/TrueColorLayerId", "TRUE_COLOR")
      style = layerStyles["TRUE_COLOR"] || "ON"
    } else if (selectedLayer === "FALSE_COLOR") {
      layerId = settings.value("QField/Sentinel/FalseColorLayerId", "FALSE_COLOR")
      style = layerStyles["FALSE_COLOR"] || "ON"
    } else if (selectedLayer === "NDVI") {
      layerId = settings.value("QField/Sentinel/NdviLayerId", "NDVI")
      style = layerStyles["NDVI"] || "ON"
    } else if (selectedLayer === "CUSTOM1") {
      layerId = custom1LayerId
      style = layerStyles["CUSTOM1"] || "DEFAULT"
      
      if (!layerId) {
        previewText.text = qsTr("Por favor ingrese un ID de capa personalizada para Custom1")
        return
      }
    } else if (selectedLayer === "CUSTOM2") {
      layerId = custom2LayerId
      style = layerStyles["CUSTOM2"] || "DEFAULT"
      
      if (!layerId) {
        previewText.text = qsTr("Por favor ingrese un ID de capa personalizada para Custom2")
        return
      }
    }
    
    // Build the WMS URL for the selected layer
    let params = [
      "contextualWMSLegend=0",
      "crs=" + crsCombo.currentText,
      "dpiMode=" + dpiModeField.text,
      "featureCount=5",
      "format=" + formatCombo.currentText,
      "layers=" + layerId,
      "styles=" + style
    ]
    
    // Add tile pixel ratio if not default
    if (dpiModeField.text !== "0") {
      params.push("tilePixelRatio=" + tilePixelRatioField.text)
    }
    
    // Add time parameter if enabled
    if (enableTimeRange.checked) {
      params.push("time=" + startDateField.text + "/" + endDateField.text)
    }
    
    // Add BBOX limiting if enabled
    if (enableBboxLimiting.checked && bboxWidthField.text && bboxHeightField.text) {
      // This is a simplified example - in a real implementation, you would calculate the BBOX
      // based on the current map center and the specified width/height
      let width = parseFloat(bboxWidthField.text)
      let height = parseFloat(bboxHeightField.text)
      
      // For demonstration purposes, we'll use a dummy BBOX centered at 0,0
      let halfWidth = width / 2
      let halfHeight = height / 2
      let bbox = [-halfWidth, -halfHeight, halfWidth, halfHeight].join(",")
      params.push("BBOX=" + bbox)
    }
    
    // Add advanced parameters if enabled
    if (showAdvancedParams.checked) {
      // Add MAXCC parameter
      if (maxCCField.text !== "100") {
        params.push("MAXCC=" + maxCCField.text)
      }
      
      // Add QUALITY parameter for JPEG
      if (formatCombo.currentText === "image/jpeg" && qualityField.text !== "90") {
        params.push("QUALITY=" + qualityField.text)
      }
      
      // Add WARNINGS parameter
      if (warningsCombo.currentText !== "SÍ") {
        params.push("WARNINGS=" + warningsCombo.currentText)
      }
      
      // Add PRIORITY parameter
      if (priorityCombo.currentText !== "másReciente") {
        params.push("PRIORITY=" + priorityCombo.currentText)
      }
    }
    
    // Add the URL
    params.push("url=https://sh.dataspace.copernicus.eu/ogc/wms/" + instanceId)
    
    // Construct the final URL
    let wmsUrl = params.join("&")
    
    // Add note about rate limiting if enabled
    if (enableRateLimiting.checked) {
      let delay = rateLimitDelayField.text || "1000"
      previewText.text = wmsUrl + "\n\n" + qsTr("Nota: La limitación de tasa está habilitada con un retraso de ") + delay + qsTr(" ms entre solicitudes.")
    } else {
      previewText.text = wmsUrl
    }
  }
  
  function loadSavedScripts() {
    // Check if settings object exists
    if (typeof settings === 'undefined' || settings === null) {
      console.log("Settings object is null or undefined")
      return
    }
    
    // Create model with a "Select a script..." option first
    let model = [qsTr("Seleccionar un script...")]
    
    // Try to get scripts from settings using value() with empty default
    // This is a workaround since childKeys() is not available
    let scriptNames = settings.value("QField/Sentinel/SavedScriptsList", "").toString()
    if (scriptNames) {
      let scriptNamesList = scriptNames.split(",")
      for (let i = 0; i < scriptNamesList.length; i++) {
        if (scriptNamesList[i].trim()) {
          model.push(scriptNamesList[i])
        }
      }
    }
    
    // Update the combo box
    savedScriptsCombo.model = model
    savedScriptsCombo.currentIndex = 0
  }
  
  // Initialize
  Component.onCompleted: {
    // Check if settings object exists
    if (typeof settings === 'undefined' || settings === null) {
      console.log("Settings object is null or undefined")
      return
    }
    
    // Load saved settings
    let enabledLayersStr = settings.value("QField/Sentinel/EnabledLayers", "")
    let enabledLayersList = enabledLayersStr ? enabledLayersStr.split(",") : []
    
    // If no layers are enabled, select the default layers
    if (enabledLayersList.length === 0 || enabledLayersStr === "") {
      enabledLayersList = ["TRUE_COLOR", "FALSE_COLOR", "NDVI"]
      // Save these default selections
      settings.setValue("QField/Sentinel/EnabledLayers", enabledLayersList.join(","))
    }
    
    // Initialize selectedLayers with the saved layers
    selectedLayers = []
    for (let i = 0; i < enabledLayersList.length; i++) {
      if (enabledLayersList[i].trim() !== "") {
        selectedLayers.push(enabledLayersList[i])
        
        // Set default style to "ON" for all layers except CUSTOM which is "DEFAULT"
        let defaultStyle = enabledLayersList[i].startsWith("CUSTOM") ? "DEFAULT" : "ON"
        layerStyles[enabledLayersList[i]] = settings.value("QField/Sentinel/Styles/" + enabledLayersList[i], defaultStyle)
        
        // Ensure we don't have empty or null styles
        if (!layerStyles[enabledLayersList[i]] || layerStyles[enabledLayersList[i]] === "") {
          layerStyles[enabledLayersList[i]] = defaultStyle
        }
        
        // Log the loaded style for debugging
        console.log("Loaded style for " + enabledLayersList[i] + ": " + layerStyles[enabledLayersList[i]])
      }
    }
    
    // Load custom layer IDs
    custom1LayerId = settings.value("QField/Sentinel/Custom1LayerId", "")
    custom2LayerId = settings.value("QField/Sentinel/Custom2LayerId", "")
    
    // Set default layer IDs if not already set
    if (!settings.value("QField/Sentinel/TrueColorLayerId", "")) {
      settings.setValue("QField/Sentinel/TrueColorLayerId", "TRUE_COLOR")
    }
    
    if (!settings.value("QField/Sentinel/FalseColorLayerId", "")) {
      settings.setValue("QField/Sentinel/FalseColorLayerId", "FALSE_COLOR")
    }
    
    if (!settings.value("QField/Sentinel/NdviLayerId", "")) {
      settings.setValue("QField/Sentinel/NdviLayerId", "NDVI")
    }
    
    // Load WMS parameters
    crsCombo.currentIndex = crsCombo.find(settings.value("QField/Sentinel/CRS", "EPSG:4326"))
    formatCombo.currentIndex = formatCombo.find(settings.value("QField/Sentinel/Format", "image/png"))
    dpiModeField.text = settings.value("QField/Sentinel/DPIMode", "7")
    tilePixelRatioField.text = settings.value("QField/Sentinel/TilePixelRatio", "0")
    
    // Load time settings
    enableTimeRange.checked = settings.valueBool("QField/Sentinel/TimeEnabled", false)
    if (enableTimeRange.checked) {
      startDateField.text = settings.value("QField/Sentinel/TimeStart", startDateField.text)
      endDateField.text = settings.value("QField/Sentinel/TimeEnd", endDateField.text)
    }
    
    // Load advanced parameters
    showAdvancedParams.checked = settings.valueBool("QField/Sentinel/AdvancedParamsEnabled", false)
    maxCCField.text = settings.value("QField/Sentinel/MAXCC", "100")
    qualityField.text = settings.value("QField/Sentinel/QUALITY", "90")
    warningsCombo.currentIndex = warningsCombo.find(settings.value("QField/Sentinel/WARNINGS", "SÍ"))
    priorityCombo.currentIndex = priorityCombo.find(settings.value("QField/Sentinel/PRIORITY", "másReciente"))
    
    // Load BBOX limiting settings
    enableBboxLimiting.checked = settings.valueBool("QField/Sentinel/BboxLimitingEnabled", false)
    if (enableBboxLimiting.checked) {
      bboxWidthField.text = settings.value("QField/Sentinel/BboxWidth", "10000")
      bboxHeightField.text = settings.value("QField/Sentinel/BboxHeight", "10000")
    }
    
    // Load rate limiting settings
    enableRateLimiting.checked = settings.valueBool("QField/Sentinel/RateLimitingEnabled", false)
    if (enableRateLimiting.checked) {
      rateLimitDelayField.text = settings.value("QField/Sentinel/RateLimitDelay", "1000")
    }
    
    // Load custom script settings
    enableCustomScript.checked = settings.valueBool("QField/Sentinel/CustomScriptEnabled", false)
    if (enableCustomScript.checked) {
      scriptUrlField.text = settings.value("QField/Sentinel/ScriptUrl", "")
      customScriptField.text = settings.value("QField/Sentinel/CustomScript", "")
    }
    
    // Load saved scripts
    loadSavedScripts()
    
    updatePreview()
  }
  
  // Add a function to save layer settings
  function saveLayerSettings() {
    // Check if settings object exists
    if (typeof settings === 'undefined' || settings === null) {
      console.log("Settings object is null or undefined")
      mainWindow.displayToast(qsTr("Error: Settings object is not available"))
      return
    }
    
    // Save instance ID
    if (instanceIdField && instanceIdField.text) {
      settings.setValue("QField/Sentinel/InstanceId", instanceIdField.text)
    }
    
    // Save custom layer settings
    settings.setValue("QField/Sentinel/Custom1LayerId", custom1LayerId)
    settings.setValue("QField/Sentinel/Custom2LayerId", custom2LayerId)
    
    // Save layer configuration - only save layers that are actually enabled
    // Convert to string to avoid QJSValue error
    settings.setValue("QField/Sentinel/EnabledLayers", selectedLayers.join(","))
    
    // Save all layer styles - but only for valid layers
    const validLayers = ["TRUE_COLOR", "FALSE_COLOR", "NDVI", "CUSTOM1", "CUSTOM2"]
    
    // Debug: Log all keys in layerStyles to find the empty key
    console.log("All keys in layerStyles:")
    for (let layer in layerStyles) {
      console.log("Key: '" + layer + "', Value: '" + layerStyles[layer] + "'")
    }
    
    // Clean up layerStyles to remove any invalid entries
    for (let layer in layerStyles) {
      if (!validLayers.includes(layer) || layer === "") {
        console.log("Removing invalid layer style key: '" + layer + "'")
        delete layerStyles[layer]
      }
    }
    
    // Save only valid layer styles
    for (let i = 0; i < validLayers.length; i++) {
      const layer = validLayers[i]
      if (layerStyles[layer]) {
        settings.setValue("QField/Sentinel/Styles/" + layer, layerStyles[layer])
      } else {
        // Set default style if missing
        const defaultStyle = layer.startsWith("CUSTOM") ? "DEFAULT" : "ON"
        settings.setValue("QField/Sentinel/Styles/" + layer, defaultStyle)
        layerStyles[layer] = defaultStyle
      }
    }
    
    // Also save a flag to indicate that settings have been updated
    settings.setValue("QField/Sentinel/SettingsUpdated", true)
    
    // Save a flag to force reload of layers
    settings.setValue("QField/Sentinel/SettingsChanged", true)
    
    // Enable or disable Sentinel layers based on whether any layers are selected
    settings.setValue("QField/Sentinel/EnableLayers", selectedLayers.length > 0)
    
    // Log the settings for debugging
    console.log("Saved Sentinel settings:")
    console.log("EnabledLayers: " + selectedLayers.join(","))
    for (let layer in layerStyles) {
      console.log("Style for " + layer + ": " + layerStyles[layer])
    }
    
    mainWindow.displayToast(qsTr("Configuración de Sentinel guardada. Reinicie QField o recargue su proyecto para que los cambios surtan efecto."))
  }
} 