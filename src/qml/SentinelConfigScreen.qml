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
  property string customLayerId: ""
  property string evalScriptUrl: ""
  property string evalScript: ""
  property var selectedLayers: ["TRUE_COLOR", "FALSE_COLOR", "NDVI", "CUSTOM"]
  property var layerStyles: {
    "TRUE_COLOR": "DEFAULT",
    "FALSE_COLOR": "DEFAULT",
    "NDVI": "VIZ",
    "CUSTOM": "DEFAULT"
  }
  
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
          text: qsTr("Sentinel Hub Configuration")
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
            
            // Save custom script settings
            settings.setValue("QField/Sentinel/CustomScriptEnabled", enableCustomScript.checked)
            if (enableCustomScript.checked) {
              settings.setValue("QField/Sentinel/ScriptUrl", scriptUrlField.text)
              settings.setValue("QField/Sentinel/CustomScript", customScriptField.text)
            }
            
            // Save custom layer script settings
            settings.setValue("QField/Sentinel/EvalScriptUrl", customEvalScriptUrlField.text)
            settings.setValue("QField/Sentinel/EvalScript", customEvalScriptField.text)
            
            mainWindow.displayToast(qsTr("Sentinel settings saved. Restart QField or reload your project for changes to take effect."))
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
      model: [qsTr("Basic"), qsTr("Layers"), qsTr("Query Builder")]
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
              text: qsTr("Sentinel Hub Instance ID")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            TextField {
              id: instanceIdField
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: sentinelConfigScreen.instanceId
              placeholderText: qsTr("Enter your Sentinel Hub instance ID")
              font: Theme.defaultFont
              
              onTextChanged: {
                updatePreview()
              }
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("The instance ID is required to access Sentinel Hub WMS services. You can find it in your Sentinel Hub account.")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("Learn more about <a href='https://www.sentinel-hub.com/'>Sentinel Hub</a>")
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
              text: qsTr("How to get a Sentinel Hub Instance ID:")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("1. Create an account at <a href='https://www.sentinel-hub.com/'>sentinel-hub.com</a>")
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
              text: qsTr("2. Create a new configuration")
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
            
            Label {
              Layout.fillWidth: true
              text: qsTr("3. Find your instance ID in the configuration details")
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
              text: qsTr("Available Sentinel Layers")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.bottomMargin: 20
              text: qsTr("Toggle layers to include in your projects")
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
                
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: layerCardContent.height + 60
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
                        if (checked && !selectedLayers.includes(layerName)) {
                          selectedLayers.push(layerName)
                        } else if (!checked && selectedLayers.includes(layerName)) {
                          selectedLayers = selectedLayers.filter(layer => layer !== layerName)
                        }
                        updatePreview()
                      }
                    }
                    
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      
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
                    }
                    
                    ComboBox {
                      id: styleCombo
                      model: layerName === "CUSTOM" ? ["DEFAULT", "ON", "OFF"] : ["ON", "OFF"]
                      currentIndex: layerName === "CUSTOM" ? 
                                    (currentStyle === "DEFAULT" ? 0 : (currentStyle === "ON" ? 1 : 2)) : 
                                    (currentStyle === "ON" ? 0 : 1)
                      enabled: layerSwitch.checked
                      Layout.preferredWidth: 120
                      
                      onCurrentTextChanged: {
                        currentStyle = currentText
                        layerStyles[layerName] = currentText
                        updatePreview()
                      }
                    }
                  }
                  
                  // Custom options container (only visible for Custom layer)
                  ColumnLayout {
                    id: customOptionsContainer
                    Layout.fillWidth: true
                    Layout.topMargin: 25
                    spacing: 25
                    visible: hasCustomOptions && layerSwitch.checked
                    
                    Rectangle {
                      Layout.fillWidth: true
                      height: 2
                      color: Theme.secondaryTextColor
                      opacity: 0.3
                      Layout.bottomMargin: 10
                    }
                    
                    // Custom Layer ID Section
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 15
                      
                      Label {
                        text: qsTr("Custom Layer ID:")
                        font: Theme.defaultFont
                        color: Theme.mainColor
                      }
                      
                      TextField {
                        id: layerIdField
                        Layout.fillWidth: true
                        Layout.topMargin: 5
                        placeholderText: qsTr("Enter layer ID (e.g., AGRICULTURE)")
                        text: customId
                        
                        onTextChanged: {
                          customId = text
                          if (layerName === "CUSTOM") {
                            sentinelConfigScreen.customLayerId = text
                          }
                          updatePreview()
                        }
                      }
                      
                      Label {
                        visible: layerIdField.text.trim() === ""
                        text: qsTr("Please enter a layer ID for the custom layer")
                        font: Theme.tipFont
                        color: Theme.warningColor
                        wrapMode: Text.WordWrap
                      }
                    }
                    
                    // Script URL Section
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 15
                      Layout.topMargin: 20
                      
                      Label {
                        text: qsTr("Script URL:")
                        font: Theme.defaultFont
                        color: Theme.mainColor
                      }
                      
                      TextField {
                        id: scriptUrlField
                        Layout.fillWidth: true
                        Layout.topMargin: 5
                        placeholderText: qsTr("https://example.com/script.js")
                        text: scriptUrl
                        
                        onTextChanged: {
                          scriptUrl = text
                          if (layerName === "CUSTOM") {
                            sentinelConfigScreen.evalScriptUrl = text
                          }
                          updatePreview()
                        }
                      }
                      
                      Label {
                        text: qsTr("The script URL should point to a JavaScript file hosted on an HTTPS server.")
                        font: Theme.tipFont
                        color: Theme.secondaryTextColor
                        wrapMode: Text.WordWrap
                      }
                    }
                    
                    // OR Separator
                    Label {
                      text: qsTr("OR")
                      font.bold: true
                      color: Theme.mainColor
                      horizontalAlignment: Text.AlignHCenter
                      Layout.fillWidth: true
                      Layout.topMargin: 20
                      Layout.bottomMargin: 20
                    }
                    
                    // BASE64 Script Section
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 15
                      
                      Label {
                        text: qsTr("BASE64 Encoded Script:")
                        font: Theme.defaultFont
                        color: Theme.mainColor
                      }
                      
                      TextArea {
                        id: scriptContentField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        Layout.topMargin: 5
                        placeholderText: qsTr("Paste your BASE64 encoded script here")
                        text: scriptContent
                        wrapMode: TextEdit.Wrap
                        
                        onTextChanged: {
                          scriptContent = text
                          if (layerName === "CUSTOM") {
                            sentinelConfigScreen.evalScript = text
                          }
                          updatePreview()
                        }
                      }
                      
                      Label {
                        text: qsTr("The script must be BASE64 encoded before pasting here.")
                        font: Theme.tipFont
                        color: Theme.secondaryTextColor
                        wrapMode: Text.WordWrap
                      }
                      
                      Label {
                        text: qsTr("Note: Either provide a Script URL OR a BASE64 encoded script, not both.")
                        font: Theme.tipFont
                        color: Theme.warningColor
                        wrapMode: Text.WordWrap
                        visible: scriptUrlField.text.trim() !== "" && scriptContentField.text.trim() !== ""
                      }
                    }
                    
                    // Save Button for Custom Layer
                    Button {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 60
                      Layout.topMargin: 30
                      Layout.bottomMargin: 10
                      visible: layerName === "CUSTOM"
                      
                      text: qsTr("Save Custom Layer Settings")
                      font.bold: true
                      
                      onClicked: {
                        // Make sure to get the latest values from the custom layer
                        if (customLayerLoader && customLayerLoader.item) {
                          sentinelConfigScreen.customLayerId = customLayerLoader.item.customId
                          sentinelConfigScreen.evalScriptUrl = customLayerLoader.item.scriptUrl
                          sentinelConfigScreen.evalScript = customLayerLoader.item.scriptContent
                        }
                        
                        saveLayerSettings()
                        mainWindow.displayToast(qsTr("Custom layer settings saved"))
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
                    if (layerName === "CUSTOM") {
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
                item.layerDescription = qsTr("Natural color image (RGB)")
                item.isChecked = selectedLayers.includes("TRUE_COLOR")
                item.currentStyle = layerStyles["TRUE_COLOR"] || "ON"
              }
            }
            
            // False Color Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "FALSE_COLOR"
                item.layerDescription = qsTr("Uses near-infrared instead of blue band")
                item.isChecked = selectedLayers.includes("FALSE_COLOR")
                item.currentStyle = layerStyles["FALSE_COLOR"] || "ON"
              }
            }
            
            // NDVI Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "NDVI"
                item.layerDescription = qsTr("Normalized Difference Vegetation Index")
                item.isChecked = selectedLayers.includes("NDVI")
                item.currentStyle = layerStyles["NDVI"] || "ON"
              }
            }
            
            // EVI Layer
            Loader {
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "EVI"
                item.layerDescription = qsTr("Enhanced Vegetation Index")
                item.isChecked = selectedLayers.includes("EVI")
                item.currentStyle = layerStyles["EVI"] || "ON"
              }
            }
            
            // Custom Layer
            Loader {
              id: customLayerLoader
              Layout.fillWidth: true
              sourceComponent: layerCardComponent
              
              onLoaded: {
                item.layerName = "CUSTOM"
                item.layerDescription = qsTr("Custom layer with configurable layer ID")
                item.isChecked = selectedLayers.includes("CUSTOM")
                item.currentStyle = layerStyles["CUSTOM"] || "DEFAULT"
                item.hasCustomOptions = true
                item.customId = sentinelConfigScreen.customLayerId
                item.scriptUrl = sentinelConfigScreen.evalScriptUrl
                item.scriptContent = sentinelConfigScreen.evalScript
              }
            }
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
                  text: qsTr("Layer Style Options")
                  font.bold: true
                  color: Theme.mainColor
                }
                
                Label {
                  Layout.fillWidth: true
                  text: qsTr("ON: Layer is visible with default styling")
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                }
                
                Label {
                  Layout.fillWidth: true
                  text: qsTr("OFF: Layer is available but initially hidden")
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                }
                
                Label {
                  Layout.fillWidth: true
                  text: qsTr("DEFAULT: Uses Sentinel Hub's default styling (Custom layer only)")
                  font: Theme.tipFont
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                }
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
              
              text: qsTr("Save All Layer Settings")
              font.bold: true
              
              onClicked: {
                // Make sure to get the latest values from the custom layer
                if (customLayerLoader && customLayerLoader.item) {
                  sentinelConfigScreen.customLayerId = customLayerLoader.item.customId
                  sentinelConfigScreen.evalScriptUrl = customLayerLoader.item.scriptUrl
                  sentinelConfigScreen.evalScript = customLayerLoader.item.scriptContent
                }
                
                saveLayerSettings()
                mainWindow.displayToast(qsTr("All layer settings saved"))
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
              text: qsTr("WMS Query Builder")
              font: Theme.strongFont
              color: Theme.mainColor
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("Configure additional WMS parameters:")
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
                text: qsTr("Format:")
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
              text: qsTr("Enable time range")
              checked: false
              
              onCheckedChanged: {
                updatePreview()
              }
            }
            
            Label {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              text: qsTr("The time range allows you to filter images by date. Sentinel Hub will return the most recent image within the specified date range that meets your criteria (e.g., cloud coverage).")
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
                text: qsTr("Start date:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: startDateField
                Layout.fillWidth: true
                text: new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0]
                placeholderText: "YYYY-MM-DD"
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                text: qsTr("End date:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              TextField {
                id: endDateField
                Layout.fillWidth: true
                text: new Date().toISOString().split('T')[0]
                placeholderText: "YYYY-MM-DD"
                
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
              text: qsTr("Show advanced parameters")
              checked: false
            }
            
            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              columns: 2
              visible: showAdvancedParams.checked
              
              Label {
                text: qsTr("DPI Mode:")
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
                text: qsTr("DPI Mode controls the resolution of the WMS images. Higher values mean higher resolution but use more credits.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Tile Pixel Ratio:")
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
                text: qsTr("Tile Pixel Ratio affects the resolution of tiles. Higher values use more credits.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Max Cloud Coverage (%):")
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
                text: qsTr("Maximum allowable cloud coverage in percent. Lower values may result in fewer available images.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Quality (JPEG only):")
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
                text: qsTr("Show Warnings:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              ComboBox {
                id: warningsCombo
                Layout.fillWidth: true
                model: ["YES", "NO"]
                currentIndex: 0
                
                onCurrentTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                text: qsTr("Priority:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              ComboBox {
                id: priorityCombo
                Layout.fillWidth: true
                model: ["mostRecent", "leastRecent", "leastCC", "leastTimeDifference"]
                currentIndex: 0
                
                onCurrentTextChanged: {
                  updatePreview()
                }
              }
              
              // Credit Usage Limiting Options
              Label {
                Layout.columnSpan: 2
                Layout.topMargin: 10
                text: qsTr("Credit Usage Limiting Options")
                font.bold: true
                color: Theme.mainColor
              }
              
              Label {
                text: qsTr("Enable BBOX Limiting:")
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
                text: qsTr("Limiting BBOX restricts the area requested, saving processing credits.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("BBOX Width (m):")
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
                text: qsTr("BBOX Height (m):")
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
                text: qsTr("Enable Rate Limiting:")
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
                text: qsTr("Rate limiting adds a delay between requests to avoid excessive credit usage.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Delay Between Requests (ms):")
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
              }
              
              Label {
                text: qsTr("Enable Custom Script:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
              }
              
              CheckBox {
                id: enableCustomScript
                checked: false
                
                onCheckedChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Custom scripts allow advanced processing but may use more credits.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
              
              Label {
                text: qsTr("Script URL:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: enableCustomScript.checked
              }
              
              TextField {
                id: scriptUrlField
                Layout.fillWidth: true
                text: ""
                placeholderText: "https://example.com/script.js"
                enabled: enableCustomScript.checked
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("OR")
                font.bold: true
                color: Theme.mainTextColor
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                enabled: enableCustomScript.checked
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Custom Evaluation Script:")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: enableCustomScript.checked
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
                
                onTextChanged: {
                  updatePreview()
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Note: Custom scripts will be BASE64 encoded automatically. Either provide a Script URL OR a Custom Script, not both.")
                font: Theme.tipFont
                color: Theme.warningColor
                wrapMode: Text.WordWrap
                enabled: enableCustomScript.checked
              }
              
              Button {
                Layout.columnSpan: 2
                text: qsTr("Save Script to Library")
                enabled: enableCustomScript.checked && customScriptField.text.length > 0
                Layout.alignment: Qt.AlignRight
                
                onClicked: {
                  // Open dialog to name and save the script
                  saveScriptDialog.open()
                }
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
                
                Component.onCompleted: {
                  loadSavedScripts()
                }
                
                onCurrentIndexChanged: {
                  if (currentIndex > 0) {
                    // Load the selected script
                    let scriptName = currentText
                    let scriptContent = settings.value("QField/Sentinel/SavedScripts/" + scriptName, "")
                    customScriptField.text = scriptContent
                  }
                }
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("Select a saved script from the dropdown above")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                visible: enableCustomScript.checked && savedScriptsCombo.count > 1
              }
              
              Button {
                Layout.columnSpan: 2
                text: qsTr("Delete Selected Script")
                enabled: enableCustomScript.checked && savedScriptsCombo.currentIndex > 0
                Layout.alignment: Qt.AlignRight
                
                onClicked: {
                  // Delete the selected script
                  let scriptName = savedScriptsCombo.currentText
                  
                  // Check if settings object exists
                  if (typeof settings === 'undefined' || settings === null) {
                    console.log("Settings object is null or undefined")
                    mainWindow.displayToast(qsTr("Error: Settings object is not available"))
                    return
                  }
                  
                  settings.remove("QField/Sentinel/SavedScripts/" + scriptName)
                  
                  // Update the scripts list by removing the script name from the list
                  let scriptNames = settings.value("QField/Sentinel/SavedScriptsList", "").toString()
                  let scriptNamesList = scriptNames ? scriptNames.split(",") : []
                  
                  // Remove the script name from the list
                  let index = scriptNamesList.indexOf(scriptName)
                  if (index !== -1) {
                    scriptNamesList.splice(index, 1)
                    settings.setValue("QField/Sentinel/SavedScriptsList", scriptNamesList.join(","))
                  }
                  
                  loadSavedScripts()
                  mainWindow.displayToast(qsTr("Script deleted: ") + scriptName)
                }
              }
              
              Label {
                Layout.columnSpan: 2
                Layout.topMargin: 10
                text: qsTr("WMS vs WMTS")
                font.bold: true
                color: Theme.mainColor
              }
              
              Label {
                Layout.columnSpan: 2
                text: qsTr("WMS (Web Map Service) provides custom-generated images on demand, ideal for NDVI and crop analysis with flexible parameters.\n\nWMTS (Web Map Tile Service) uses pre-rendered tiles, faster but less flexible for custom analysis. For crop monitoring, WMS is generally preferred.")
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
              text: qsTr("Note: Advanced parameters can significantly affect your Sentinel Hub credit usage. Use with caution.")
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
      Layout.preferredHeight: 150
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
          text: qsTr("Preview WMS URL")
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
          text: qsTr("Copy to Clipboard")
          Layout.alignment: Qt.AlignRight
          Layout.preferredHeight: 30
          Layout.preferredWidth: 180
          
          onClicked: {
            // Check if clipboard is available
            if (typeof mainWindow.clipboard !== 'undefined' && mainWindow.clipboard) {
              mainWindow.clipboard.setText(previewText.text)
              mainWindow.displayToast(qsTr("URL copied to clipboard"))
            } else {
              // Fallback if clipboard is not available
              console.log("Clipboard not available, URL: " + previewText.text)
              mainWindow.displayToast(qsTr("Clipboard not available. See console for URL."))
            }
          }
        }
      }
    }
  }
  
  // Save Script Dialog
  Dialog {
    id: saveScriptDialog
    title: qsTr("Save Script")
    standardButtons: Dialog.Save | Dialog.Cancel
    modal: true
    
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width - 50, 400)
    
    ColumnLayout {
      width: parent.width
      
      Label {
        text: qsTr("Script Name:")
        font: Theme.defaultFont
      }
      
      TextField {
        id: scriptNameField
        Layout.fillWidth: true
        placeholderText: qsTr("Enter a name for your script")
      }
    }
    
    onAccepted: {
      if (scriptNameField.text.trim() === "") {
        mainWindow.displayToast(qsTr("Please enter a name for your script"))
        return
      }
      
      // Check if settings object exists
      if (typeof settings === 'undefined' || settings === null) {
        console.log("Settings object is null or undefined")
        mainWindow.displayToast(qsTr("Error: Settings object is not available"))
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
      
      mainWindow.displayToast(qsTr("Script saved: ") + scriptName)
      scriptNameField.text = ""
    }
  }
  
  // Functions
  function updatePreview() {
    // Get the instance ID from the field
    let instanceId = instanceIdField ? instanceIdField.text : ""
    
    if (!instanceId) {
      previewText.text = qsTr("Please enter a Sentinel Hub instance ID")
      return
    }
    
    // For custom layer, check if we have a layer ID
    if (selectedLayers.includes("CUSTOM")) {
      // Get the custom layer ID from the loader
      let customLayerId = ""
      if (customLayerLoader && customLayerLoader.item) {
        customLayerId = customLayerLoader.item.customId
      }
      
      if (!customLayerId) {
        previewText.text = qsTr("Please enter a custom layer ID")
        return
      }
      
      // Build the WMS URL for the custom layer
      let params = [
        "contextualWMSLegend=0",
        "crs=" + crsCombo.currentText,
        "dpiMode=" + dpiModeField.text,
        "featureCount=5",
        "format=" + formatCombo.currentText,
        "layers=" + customLayerId,
        "styles=" + layerStyles["CUSTOM"]
      ]
      
      // Add script parameters if available
      let scriptUrl = ""
      let scriptContent = ""
      
      if (customLayerLoader && customLayerLoader.item) {
        scriptUrl = customLayerLoader.item.scriptUrl
        scriptContent = customLayerLoader.item.scriptContent
      }
      
      if (scriptUrl) {
        params.push("EVALSCRIPTURL=" + scriptUrl)
      } else if (scriptContent) {
        params.push("EVALSCRIPT=" + scriptContent)
      }
      
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
        if (warningsCombo.currentText !== "YES") {
          params.push("WARNINGS=" + warningsCombo.currentText)
        }
        
        // Add PRIORITY parameter
        if (priorityCombo.currentText !== "mostRecent") {
          params.push("PRIORITY=" + priorityCombo.currentText)
        }
        
        // Add custom script if enabled
        if (enableCustomScript.checked) {
          if (scriptUrlField && scriptUrlField.text) {
            params.push("EVALSCRIPTURL=" + scriptUrlField.text)
          } else if (customScriptField && customScriptField.text) {
            // For preview purposes, we'll show a placeholder for the BASE64 encoded script
            params.push("EVALSCRIPT=[BASE64_ENCODED_SCRIPT]")
          }
        }
      }
      
      // Add the URL
      params.push("url=https://sh.dataspace.copernicus.eu/ogc/wms/" + instanceId)
      
      // Construct the final URL
      let wmsUrl = params.join("&")
      
      // Add note about rate limiting if enabled
      if (enableRateLimiting.checked) {
        let delay = rateLimitDelayField.text || "1000"
        previewText.text = wmsUrl + "\n\n" + qsTr("Note: Rate limiting is enabled with a delay of ") + delay + qsTr(" ms between requests.")
      } else {
        previewText.text = wmsUrl
      }
      
      // If custom layer has script parameters, show them below the URL
      if (scriptUrl) {
        previewText.text += "\n\n" + qsTr("Custom Layer Script URL:") + "\n" + scriptUrl
      } else if (scriptContent) {
        previewText.text += "\n\n" + qsTr("Custom Layer BASE64 Script:") + "\n" + scriptContent
      }
      
      return
    }
    
    // Build the WMS URL for the selected layer
    let selectedLayer = selectedLayers.length > 0 ? selectedLayers[0] : "NDVI"
    let style = layerStyles[selectedLayer] || "ON"
    
    let params = [
      "contextualWMSLegend=0",
      "crs=" + crsCombo.currentText,
      "dpiMode=" + dpiModeField.text,
      "featureCount=5",
      "format=" + formatCombo.currentText,
      "layers=" + selectedLayer,
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
      if (warningsCombo.currentText !== "YES") {
        params.push("WARNINGS=" + warningsCombo.currentText)
      }
      
      // Add PRIORITY parameter
      if (priorityCombo.currentText !== "mostRecent") {
        params.push("PRIORITY=" + priorityCombo.currentText)
      }
      
      // Add custom script if enabled
      if (enableCustomScript.checked) {
        if (scriptUrlField && scriptUrlField.text) {
          params.push("EVALSCRIPTURL=" + scriptUrlField.text)
        } else if (customScriptField && customScriptField.text) {
          // For preview purposes, we'll show a placeholder for the BASE64 encoded script
          params.push("EVALSCRIPT=[BASE64_ENCODED_SCRIPT]")
        }
      }
    }
    
    // Add the URL
    params.push("url=https://sh.dataspace.copernicus.eu/ogc/wms/" + instanceId)
    
    // Construct the final URL
    let wmsUrl = params.join("&")
    
    // Add note about rate limiting if enabled
    if (enableRateLimiting.checked) {
      let delay = rateLimitDelayField.text || "1000"
      previewText.text = wmsUrl + "\n\n" + qsTr("Note: Rate limiting is enabled with a delay of ") + delay + qsTr(" ms between requests.")
    } else {
      previewText.text = wmsUrl
    }
    
    // If custom script is enabled and has content, show it below the URL
    if (enableCustomScript.checked && customScriptField && customScriptField.text) {
      previewText.text += "\n\n" + qsTr("Custom Script:") + "\n" + customScriptField.text
    }
  }
  
  function loadSavedScripts() {
    // Check if settings object exists
    if (typeof settings === 'undefined' || settings === null) {
      console.log("Settings object is null or undefined")
      return
    }
    
    // Create model with a "Select a script..." option first
    let model = [qsTr("Select a script...")]
    
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
    let enabledLayersStr = settings.value("QField/Sentinel/EnabledLayers", "TRUE_COLOR,FALSE_COLOR,NDVI,CUSTOM")
    let enabledLayersList = enabledLayersStr.split(",")
    
    // Initialize selectedLayers with the saved layers
    selectedLayers = []
    for (let i = 0; i < enabledLayersList.length; i++) {
      if (enabledLayersList[i].trim() !== "") {
        selectedLayers.push(enabledLayersList[i])
        layerStyles[enabledLayersList[i]] = settings.value("QField/Sentinel/Styles/" + enabledLayersList[i], 
                                                          enabledLayersList[i] === "CUSTOM" ? "DEFAULT" : "ON")
      }
    }
    
    // Load custom layer ID and script settings
    customLayerId = settings.value("QField/Sentinel/CustomLayerId", "")
    evalScriptUrl = settings.value("QField/Sentinel/EvalScriptUrl", "")
    evalScript = settings.value("QField/Sentinel/EvalScript", "")
    
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
    warningsCombo.currentIndex = warningsCombo.find(settings.value("QField/Sentinel/WARNINGS", "YES"))
    priorityCombo.currentIndex = priorityCombo.find(settings.value("QField/Sentinel/PRIORITY", "mostRecent"))
    
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
    
    // Get custom layer values from the custom layer component if it exists
    if (customLayerLoader && customLayerLoader.item) {
      customLayerId = customLayerLoader.item.customId
      evalScriptUrl = customLayerLoader.item.scriptUrl
      evalScript = customLayerLoader.item.scriptContent
    }
    
    // Save custom layer settings
    settings.setValue("QField/Sentinel/CustomLayerId", customLayerId)
    settings.setValue("QField/Sentinel/EvalScriptUrl", evalScriptUrl)
    settings.setValue("QField/Sentinel/EvalScript", evalScript)
    
    // Save layer configuration
    let enabledLayersList = []
    for (let i = 0; i < selectedLayers.length; i++) {
      enabledLayersList.push(selectedLayers[i])
    }
    
    // Convert to string to avoid QJSValue error
    settings.setValue("QField/Sentinel/EnabledLayers", enabledLayersList.join(","))
    
    // Save all layer styles
    for (let layer in layerStyles) {
      settings.setValue("QField/Sentinel/Styles/" + layer, layerStyles[layer])
    }
    
    mainWindow.displayToast(qsTr("Layer settings saved"))
  }
} 