import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material.impl
import QtQuick.Layouts
import QtQuick.Particles
import QtCore
import org.qfield 1.0
import Theme

/**
 * \ingroup qml
 */
Page {
  id: welcomeScreen

  property bool firstShown: false
  property string mainProjectPath: "" // Path to main project file
  property string mainProjectTitle: qsTr("Mapa Principal SIGPAC-Go") // Title of main project

  // Add debug logging for project paths
  Component.onCompleted: {
    // Initialize terms and conditions
    termsAndConditionsLoader.active = true;
    sigpacTermsLoader.active = true;
    
    // Try to find the main map in standard locations
    const pathsToTry = [];
    
    // Add platform-specific paths
    if (Qt.platform.os === "android") {
      const dataDir = platformUtilities.appDataDirs()[0];
      pathsToTry.push(
        dataDir + "SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
        dataDir + "sigpacgo_main/SIGPACGO.qgz",
        // Add direct path which should work on the device
        "/data/user/0/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
        "/data/data/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
        dataDir + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
      );
    } else {
      // Desktop paths
      pathsToTry.push(
        platformUtilities.applicationDirectory() + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
      );
    }
    
    // Log all paths we're checking
    console.log("Checking the following paths for SIGPACGO_Mapa_Principal:");
    for (let i = 0; i < pathsToTry.length; i++) {
      console.log("Path " + (i+1) + ": " + pathsToTry[i]);
    }
    
    // Try each path
    let mapFound = false;
    for (let i = 0; i < pathsToTry.length; i++) {
      let path = pathsToTry[i];
      let fileInfo = platformUtilities.getFileInfo(path);
      if (fileInfo && fileInfo.exists) {
        mainProjectPath = path;
        console.log("Found main map at: " + mainProjectPath);
        mapFound = true;
        break;
      }
    }
    
    if (!mapFound) {
      console.log("Main map not found in any standard location.");
      mainProjectPath = pathsToTry[0]; // Use the first path as default for later copy attempts
    }
    
    // Check if maps exist, copy if needed
    checkMapsExist();
  }

  property alias model: table.model
  signal openLocalDataPicker
  signal showSettings

  visible: false
  focus: visible

  Settings {
    id: registry
    category: 'QField'

    property string baseMapProject: ''
    property string defaultProject: ''
    property bool loadProjectOnLaunch: false
    property string phrasesFilePath: ''
  }
  
  // Add Terms and Conditions popup with lazy loading
  Loader {
    id: termsAndConditionsLoader
    active: false  // Don't load immediately
    source: "TermsAndConditions.qml"
    asynchronous: true  // Load asynchronously to prevent UI blocking
    
    onLoaded: {
      item.parent = Overlay.overlay;
      console.log("Terms and conditions loaded successfully");
      
      // Connect to the termsAccepted signal to save the setting and show SIGPAC terms if needed
      item.termsAccepted.connect(function() {
        console.log("Terms and conditions accepted signal received");
        // Store locally that we've shown and accepted terms
        settings.setValue("SIGPACGO/termsAccepted", true);
        
        // After accepting the main terms, show SIGPAC terms if needed
        showSigpacTermsIfNeeded();
      });
      
      // Check if we need to show terms when loaded
      if (needToShowTerms) {
        showTermsDialogIfNeeded();
      }
    }
  }
  
  // Add SIGPAC Terms popup with lazy loading
  Loader {
    id: sigpacTermsLoader
    active: false  // Don't load immediately
    source: "SigpacTerms.qml"
    asynchronous: true  // Load asynchronously to prevent UI blocking
    
    onLoaded: {
      item.parent = Overlay.overlay;
      console.log("SIGPAC terms loaded successfully");
      
      // Connect to the termsAccepted signal to save the setting
      item.termsAccepted.connect(function() {
        console.log("SIGPAC terms accepted signal received");
        // Store locally that we've shown and accepted terms
        settings.setValue("SIGPACGO/sigpacTermsAccepted", true);
      });
      
      // Check if we need to show SIGPAC terms when loaded
      if (needToShowSigpacTerms) {
        showSigpacDialogIfNeeded();
      }
    }
  }
  
  // Property to track if we've checked terms this session
  property bool termsCheckedThisSession: false
  // Property to track if we need to show terms when loader completes
  property bool needToShowTerms: false
  // Property to track if we need to show SIGPAC terms when loader completes
  property bool needToShowSigpacTerms: false

  // Function to show terms and conditions if needed
  function showTermsAndConditions() {
    // If we've already checked terms this session, don't check again
    if (termsCheckedThisSession) {
      console.log("Terms already checked this session, not showing dialog");
      return;
    }
    
    // Check if terms have already been accepted in settings
    if (settings.valueBool("SIGPACGO/termsAccepted", false)) {
      console.log("Terms already accepted according to settings, not showing dialog");
      termsCheckedThisSession = true;
      
      // Check if we need to show SIGPAC terms (only if main terms are accepted)
      showSigpacTermsIfNeeded();
      return;
    }
    
    // First, make sure the component is loaded
    if (!termsAndConditionsLoader.active) {
      termsAndConditionsLoader.active = true;
      needToShowTerms = true;
    } else if (termsAndConditionsLoader.status === Loader.Ready) {
      // Component already loaded
      showTermsDialogIfNeeded();
    }
  }
  
  // Helper function to show the terms dialog if needed
  function showTermsDialogIfNeeded() {
    if (!termsAndConditionsLoader.item.accepted) {
      termsAndConditionsLoader.item.open();
      console.log("Showing terms and conditions dialog");
    } else {
      console.log("Terms already accepted in component, not showing dialog");
      
      // If main terms are accepted, check if we need to show SIGPAC terms
      showSigpacTermsIfNeeded();
    }
    termsCheckedThisSession = true;
    needToShowTerms = false;
  }
  
  // Function to show SIGPAC terms if needed
  function showSigpacTermsIfNeeded() {
    // Check if SIGPAC terms have already been accepted in settings
    if (settings.valueBool("SIGPACGO/sigpacTermsAccepted", false)) {
      console.log("SIGPAC terms already accepted according to settings, not showing dialog");
      return;
    }
    
    // First, make sure the component is loaded
    if (!sigpacTermsLoader.active) {
      sigpacTermsLoader.active = true;
      needToShowSigpacTerms = true;
    } else if (sigpacTermsLoader.status === Loader.Ready) {
      // Component already loaded
      showSigpacDialogIfNeeded();
    }
  }
  
  // Helper function to show the SIGPAC terms dialog if needed
  function showSigpacDialogIfNeeded() {
    if (!sigpacTermsLoader.item.accepted) {
      sigpacTermsLoader.item.open();
      console.log("Showing SIGPAC terms dialog");
    } else {
      console.log("SIGPAC terms already accepted in component, not showing dialog");
    }
    needToShowSigpacTerms = false;
  }

  Rectangle {
    id: welcomeBackground
    anchors.fill: parent
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: Theme.darkTheme ? "#c8a49818" : "#e1d9bc"
      }
      GradientStop {
        position: 0.80
        color: Theme.mainBackgroundColor
      }
    }
  }

  ScrollView {
    padding: 0
    topPadding: Math.max(0, Math.min(80, (mainWindow.height - welcomeGrid.height) / 2 - 45))
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: QfScrollBar {
      opacity: active
      _maxSize: 4
      _minSize: 2

      Behavior on opacity  {
        NumberAnimation {
          duration: 200
        }
      }
    }
    contentItem: welcomeGrid
    contentWidth: welcomeGrid.width
    contentHeight: welcomeGrid.height
    anchors.fill: parent
    clip: true

    GridLayout {
      id: welcomeGrid
      columns: 1
      rowSpacing: 4

      width: mainWindow.width

      ImageDial {
        id: imageDialLogo
        value: 1

        Layout.margins: 6
        Layout.topMargin: 14 + mainWindow.sceneTopMargin
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        Layout.preferredWidth: Math.min(138, mainWindow.height / 4)
        Layout.preferredHeight: Math.min(138, mainWindow.height / 4)

        source: "qrc:/images/sigpacgo_logo.svg"
        rotationOffset: 220
      }

      Text {
        id: welcomeText
        visible: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        text: ""
        font: Theme.defaultFont
        color: Theme.mainTextColor
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }

      Rectangle {
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.fillWidth: true
        Layout.maximumWidth: 410
        Layout.preferredHeight: welcomeActions.height
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        color: "transparent"

        ColumnLayout {
          id: welcomeActions
          width: parent.width
          spacing: 12

          // Stylish button for opening local files
          QfButton {
            id: localProjectButton
            Layout.fillWidth: true
            text: qsTr("Abrir archivo local")
            font.bold: true
            font.pixelSize: Theme.defaultFont.pixelSize * 1.2
            icon.source: Theme.getThemeIcon("ic_folder_open_black_24dp") 
            icon.color: Theme.mainColor
            Material.accent: Theme.mainColor
            highlighted: true
            onClicked: {
              platformUtilities.requestStoragePermission();
              openLocalDataPicker();
            }
          }

          Rectangle {
            id: phrasesContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            Layout.margins: 4
            color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.1)
            radius: 6
            border.color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.5)
            border.width: 1
            
            Rectangle {
              id: phrasesGlow
              anchors.fill: parent
              radius: 6
              color: "transparent"
              border.color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.2)
              border.width: 2
              opacity: 0.5
              
              SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 2000; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.5; duration: 2000; easing.type: Easing.InOutQuad }
              }
            }
            
            ListView {
              id: phrasesListView
              anchors.fill: parent
              anchors.margins: 6
              model: phrasesListModel
              clip: true
              interactive: false
              orientation: ListView.Horizontal
              snapMode: ListView.SnapOneItem
              highlightRangeMode: ListView.StrictlyEnforceRange
              highlightMoveDuration: 500
              preferredHighlightBegin: 0
              preferredHighlightEnd: width
              
              delegate: Item {
                width: phrasesListView.width
                height: phrasesListView.height
                
                Text {
                  anchors.fill: parent
                  text: model.text
                  font {
                    family: Theme.defaultFont.family
                    pointSize: Theme.defaultFont.pointSize + 1
                    bold: true
                  }
                  color: Theme.mainColor
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  wrapMode: Text.WordWrap
                }
              }
            }
            
            ListModel {
              id: phrasesListModel
              
              property var displaySequence: [0]  // Initialize with first index
              property int currentPhraseIndex: 0
              
              // Default phrases embedded directly in the code
              Component.onCompleted: {
                // Clear any existing items
                clear();
                
                // Add phrases directly in the code
                append({ text: "SIGPAC-Go - SIG para el campo" });
                append({ text: "Explore mapas y datos geográficos en el campo" });
                append({ text: "Captura datos con precisión GPS" });
                append({ text: "Trabaja sin conexión en cualquier lugar" });
                append({ text: "Sincroniza tus datos cuando vuelvas a tener conexión" });
                append({ text: "Visualiza capas vectoriales y ráster" });
                append({ text: "Edita atributos y geometrías en el terreno" });
                append({ text: "Navega con GPS en tiempo real" });
                append({ text: "Toma fotos y vincúlalas a tus datos" });
                append({ text: "Personaliza formularios para captura de datos" });
                append({ text: "Mejora tu productividad en el campo" });
                append({ text: "Lleva tus mapas QGIS a donde vayas" });
                
                // Generate random sequence (excluding first phrase)
                generateRandomSequence();
                
                // Start with the first phrase
                if (count > 0) {
                    phrasesListView.currentIndex = 0;
                }
                
                // Start the timer to cycle through phrases
                phraseChangeTimer.restart();
              }
              
              // Generate a random sequence of indices (excluding the first phrase)
              function generateRandomSequence() {
                if (count < 2) return; // Need at least 2 phrases
                
                // Reset the sequence but keep the first phrase
                displaySequence = [0];
                currentPhraseIndex = 0;
                
                // Create an array of indices from 1 to count-1
                var indices = [];
                for (var i = 1; i < count; i++) {
                  indices.push(i);
                }
                
                // Shuffle the indices (Fisher-Yates algorithm)
                for (var i = indices.length - 1; i > 0; i--) {
                  var j = Math.floor(Math.random() * (i + 1));
                  var temp = indices[i];
                  indices[i] = indices[j];
                  indices[j] = temp;
                }
                
                // Add the shuffled indices to the sequence
                displaySequence = displaySequence.concat(indices);
                
                console.log("Generated random sequence: " + displaySequence.join(", "));
              }
            }
            
            Timer {
              id: phraseChangeTimer
              interval: 10000 // 10 seconds
              running: welcomeScreen.visible && phrasesListModel.count > 0
              repeat: true
              
              onTriggered: {
                if (phrasesListModel.count < 2) return; // Need at least 2 phrases
                
                // Get the next index from the sequence
                phrasesListModel.currentPhraseIndex = (phrasesListModel.currentPhraseIndex + 1) % phrasesListModel.displaySequence.length;
                var nextIndex = phrasesListModel.displaySequence[phrasesListModel.currentPhraseIndex];
                
                // Verify the index is valid before setting it
                if (nextIndex !== undefined && nextIndex >= 0 && nextIndex < phrasesListModel.count) {
                    phrasesListView.currentIndex = nextIndex;
                } else {
                    // If something went wrong, regenerate sequence and start from beginning
                    phrasesListModel.generateRandomSequence();
                    phrasesListView.currentIndex = 0;
                    phrasesListModel.currentPhraseIndex = 0;
                }
                
                // If we've gone through the whole sequence, regenerate it (keeping the first phrase first)
                if (phrasesListModel.currentPhraseIndex === 0) {
                    phrasesListModel.generateRandomSequence();
                }
              }
            }
          }
          RowLayout {
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: mainWindow.sceneBottomMargin
            
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 40
              color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.08)
              radius: 4
              border.color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.2)
              border.width: 1
              
              RowLayout {
                id: switchRow
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 15
                
                QfSwitch {
                  id: reloadOnLaunch
                  Layout.alignment: Qt.AlignVCenter
                  small: true
                  
                  checked: registry.loadProjectOnLaunch
                  onCheckedChanged: {
                    registry.loadProjectOnLaunch = checked;
                  }
                }
                
                Label {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  font: Theme.tipFont
                  wrapMode: Text.WordWrap
                  color: reloadOnLaunch.checked ? Theme.mainTextColor : Theme.secondaryTextColor
                  verticalAlignment: Text.AlignVCenter
                  
                  text: reloadOnLaunch.checked ? qsTr('Cargar proyecto por defecto al iniciar') : qsTr('Cargar último proyecto al iniciar')
                  
                  MouseArea {
                    anchors.fill: parent
                    onClicked: reloadOnLaunch.checked = !reloadOnLaunch.checked
                  }
                }
              }
            }
          }
          // Main project section
          Rectangle {
            id: mainProjectContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Layout.margins: 10
            radius: 8
            
            // Replace plain color with gradient background
            gradient: Gradient {
              GradientStop { position: 0.0; color: Qt.hsla(0.33, 0.15, 0.97, 1.0) }
              GradientStop { position: 1.0; color: Qt.hsla(0.33, 0.25, 0.93, 1.0) }
            }
            
            // Add pattern overlay
            Canvas {
                id: patternCanvas
                anchors.fill: parent
                opacity: 0.08
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.fillStyle = "#4CAF50";
                    
                    // Create grid pattern
                    var gridSize = 6;
                    var dotSize = 1;
                    
                    for (var x = 0; x < width; x += gridSize) {
                        for (var y = 0; y < height; y += gridSize) {
                            ctx.fillRect(x, y, dotSize, dotSize);
                        }
                    }
                }
            }
            
            // Image with map of Spain
            Image {
                id: spainMapImage
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: parent.width * 0.4
                height: parent.height * 0.8
                source: "qrc:/images/sigpacgo_logo.svg"  // Fallback to logo if spain.svg doesn't work
                opacity: 0.15
                fillMode: Image.PreserveAspectFit
            }
            
            border.color: "#4CAF50" // Green border
            border.width: 2
            
            // Shadow effect
            Rectangle {
              z: -1
              anchors.fill: parent
              anchors.leftMargin: -2
              anchors.topMargin: -2
              anchors.rightMargin: -4
              anchors.bottomMargin: -4
              color: "#20000000"
              radius: 8
            }
            
            // Glow effect
            Rectangle {
              anchors.fill: parent
              radius: 8
              color: "transparent"
              border.color: Qt.hsla(0.33, 0.5, 0.7, 0.5)
              border.width: 2
              opacity: 0.7
              
              SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 2000; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.7; duration: 2000; easing.type: Easing.InOutQuad }
              }
            }
            
            RowLayout {
              anchors.fill: parent
              anchors.margins: 10
              spacing: 15
              
              // Project icon
              Image {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                Layout.alignment: Qt.AlignVCenter
                source: Theme.getThemeVectorIcon('ic_map_green_48dp')
                sourceSize.width: 120
                sourceSize.height: 120
              }
              
              // Project info
              ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4
                
                Text {
                  Layout.fillWidth: true
                  text: mainProjectTitle
                  font.pointSize: Theme.defaultFont.pointSize + 2
                  font.bold: true
                  color: Theme.mainColor
                  elide: Text.ElideRight
                }
                
                Text {
                  Layout.fillWidth: true
                  text: qsTr("Mapa base oficial para trabajo de campo")
                  font.pointSize: Theme.tipFont.pointSize
                  color: Theme.secondaryTextColor
                  elide: Text.ElideRight
                  wrapMode: Text.WordWrap
                  maximumLineCount: 2
                }
                
                Item { Layout.fillHeight: true } // Spacer
                
                QfButton {
                  Layout.preferredWidth: 120
                  text: qsTr("Abrir")
                  font.bold: true
                  icon.source: Theme.getThemeIcon("ic_folder_open_black_24dp")
                  icon.color: Theme.mainColor
                  Material.accent: "#4CAF50" // Green accent to match container theme
                  highlighted: true
                  onClicked: {
                    // First try to use the already verified path
                    if (mainProjectPath && mainProjectPath.length > 0) {
                      let fileInfo = platformUtilities.getFileInfo(mainProjectPath);
                      if (fileInfo && fileInfo.exists) {
                        iface.loadFile(mainProjectPath, qsTr("Mapa Principal SIGPAC-Go"));
                        console.log("Loading main map from verified path: " + mainProjectPath);
                        return;
                      }
                    }
                    
                    // Try the specific hard-coded path from the user's device
                    const specificPath = "/data/user/0/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz";
                    let specificFileInfo = platformUtilities.getFileInfo(specificPath);
                    if (specificFileInfo && specificFileInfo.exists) {
                      console.log("Loading main map from specific device path: " + specificPath);
                      iface.loadFile(specificPath, qsTr("Mapa Principal SIGPAC-Go"));
                      mainProjectPath = specificPath; // Update the verified path
                      return;
                    }
                    
                    // If that fails, try standard locations
                    const pathsToTry = [];
                    
                    // Add Android-specific paths
                    if (Qt.platform.os === "android") {
                      const dataDir = platformUtilities.appDataDirs()[0];
                      pathsToTry.push(
                        dataDir + "SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
                        dataDir + "sigpacgo_main/SIGPACGO.qgz"
                      );
                      
                      // Add more variations of paths that might work
                      const extraPaths = [
                        "/data/user/0/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
                        "/data/data/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
                        dataDir + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
                      ];
                      
                      for (const path of extraPaths) {
                        if (!pathsToTry.includes(path)) {
                          pathsToTry.push(path);
                        }
                      }
                    } else {
                      // Desktop paths
                      pathsToTry.push(
                        platformUtilities.applicationDirectory() + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
                      );
                    }
                    
                    // Log all paths we're checking
                    console.log("Checking the following paths for SIGPACGO.qgz:");
                    for (let i = 0; i < pathsToTry.length; i++) {
                      console.log("Path " + (i+1) + ": " + pathsToTry[i]);
                    }
                    
                    // Try each path
                    let mapFound = false;
                    for (let i = 0; i < pathsToTry.length; i++) {
                      let path = pathsToTry[i];
                      let fileInfo = platformUtilities.getFileInfo(path);
                      if (fileInfo && fileInfo.exists) {
                        iface.loadFile(path, qsTr("Mapa Principal SIGPAC-Go"));
                        console.log("Loading main map: " + path);
                        mainProjectPath = path; // Update the verified path
                        mapFound = true;
                        break;
                      }
                    }
                    
                    // If no map found, try to copy
                    if (!mapFound) {
                      console.log("No map found in standard locations, trying to copy");
                      try {
                        // Clear previous error state
                        console.log("Attempting to reset and copy map files again");
                        
                        platformUtilities.copyMainMapProject();
                        
                        // Check paths again
                        for (let i = 0; i < pathsToTry.length; i++) {
                          let path = pathsToTry[i];
                          let fileInfo = platformUtilities.getFileInfo(path);
                          if (fileInfo && fileInfo.exists) {
                            iface.loadFile(path, qsTr("Mapa Principal SIGPAC-Go"));
                            console.log("Loading main map after copy: " + path);
                            mainProjectPath = path; // Update the verified path
                            mapFound = true;
                            break;
                          }
                        }
                      } catch (e) {
                        console.log("Error during map copy: " + e);
                      }
                      
                      // Still no map found
                      if (!mapFound) {
                        console.log("No map found after copy attempts");
                        if (typeof displayToast === 'function') {
                          displayToast(qsTr("No se encontró el mapa. Por favor reinstale la aplicación."));
                        } else {
                          console.log("Error: No map found. Please reinstall the application.");
                        }
                      }
                    }
                  }
                }
              }
            }
            
            // Mouse area for the entire container
            MouseArea {
              anchors.fill: parent
              onClicked: {
                // First try to use the already verified path
                if (mainProjectPath && mainProjectPath.length > 0) {
                  let fileInfo = platformUtilities.getFileInfo(mainProjectPath);
                  if (fileInfo && fileInfo.exists) {
                    iface.loadFile(mainProjectPath, qsTr("Mapa Principal SIGPAC-Go"));
                    console.log("Loading main map from verified path: " + mainProjectPath);
                    return;
                  }
                }
                
                // Try the specific hard-coded path from the user's device
                const specificPath = "/data/user/0/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz";
                let specificFileInfo = platformUtilities.getFileInfo(specificPath);
                if (specificFileInfo && specificFileInfo.exists) {
                  console.log("Loading main map from specific device path: " + specificPath);
                  iface.loadFile(specificPath, qsTr("Mapa Principal SIGPAC-Go"));
                  mainProjectPath = specificPath; // Update the verified path
                  return;
                }
                
                // If that fails, try standard locations
                const pathsToTry = [];
                
                // Add Android-specific paths
                if (Qt.platform.os === "android") {
                  const dataDir = platformUtilities.appDataDirs()[0];
                  pathsToTry.push(
                    dataDir + "SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
                    dataDir + "sigpacgo_main/SIGPACGO.qgz"
                  );
                  
                  // Add more variations of paths that might work
                  const extraPaths = [
                    "/data/user/0/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
                    "/data/data/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
                    dataDir + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
                  ];
                  
                  for (const path of extraPaths) {
                    if (!pathsToTry.includes(path)) {
                      pathsToTry.push(path);
                    }
                  }
                } else {
                  // Desktop paths
                  pathsToTry.push(
                    platformUtilities.applicationDirectory() + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
                  );
                }
                
                // Try each path
                let mapFound = false;
                for (let i = 0; i < pathsToTry.length; i++) {
                  let path = pathsToTry[i];
                  let fileInfo = platformUtilities.getFileInfo(path);
                  if (fileInfo && fileInfo.exists) {
                    iface.loadFile(path, qsTr("Mapa Principal SIGPAC-Go"));
                    console.log("Loading main map: " + path);
                    mainProjectPath = path; // Update the verified path
                    mapFound = true;
                    break;
                  }
                }
                
                // If no map found, try to copy
                if (!mapFound) {
                  console.log("No map found in standard locations, trying to copy");
                  try {
                    // Clear previous error state
                    console.log("Attempting to reset and copy map files again");
                    
                    platformUtilities.copyMainMapProject();
                    
                    // Check paths again
                    for (let i = 0; i < pathsToTry.length; i++) {
                      let path = pathsToTry[i];
                      let fileInfo = platformUtilities.getFileInfo(path);
                      if (fileInfo && fileInfo.exists) {
                        iface.loadFile(path, qsTr("Mapa Principal SIGPAC-Go"));
                        console.log("Loading main map after copy: " + path);
                        mainProjectPath = path; // Update the verified path
                        mapFound = true;
                        break;
                      }
                    }
                  } catch (e) {
                    console.log("Error during map copy: " + e);
                  }
                  
                  // Still no map found
                  if (!mapFound) {
                    console.log("No map found after copy attempts");
                    if (typeof displayToast === 'function') {
                      displayToast(qsTr("No se encontró el mapa. Por favor reinstale la aplicación."));
                    } else {
                      console.log("Error: No map found. Please reinstall the application.");
                    }
                  }
                }
              }
            }
          }

          Text {
            id: recentText
            text: qsTr("Proyectos Recientes")
            font.pointSize: Theme.tipFont.pointSize
            font.bold: true
            color: Theme.mainTextColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 400
            color: "transparent"
            
            // Empty state message when no projects
            Text {
              anchors.centerIn: parent
              text: qsTr("No hay proyectos recientes")
              font.pointSize: Theme.tipFont.pointSize
              font.italic: true
              color: Theme.secondaryTextColor
              visible: !table.model || table.model.count === 0
            }
            
            // Hidden ListView to maintain model compatibility
            ListView {
              id: table
              visible: false
              width: 0
              height: 0
            }
            
            ScrollView {
              id: projectsScrollView
              anchors.fill: parent
              clip: true
              ScrollBar.vertical: QfScrollBar {}
              
              GridView {
                id: projectsGrid
                anchors.fill: parent
                anchors.margins: 5
                cellWidth: width > 600 ? (width > 900 ? width / 3 : width / 2) : width
                cellHeight: 180
                model: table.model
                boundsBehavior: Flickable.StopAtBounds
                visible: true
                
                Component.onCompleted: {
                  console.log("GridView created with model count: " + (model ? model.count : "null"))
                }
                
                delegate: Item {
                  id: gridDelegate
                  width: projectsGrid.cellWidth - 10
                  height: projectsGrid.cellHeight - 10
                  
                  property bool isPressed: false
                  property string path: ProjectPath
                  property string title: ProjectTitle
                  property var type: ProjectType
                  
                  Rectangle {
                    id: projectCard
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 8
                    color: {
                      // Different colors based on project type
                      switch (type) {
                        case 0: return Qt.hsla(0.33, 0.2, 0.9, 1.0); // Light green tint for local
                        case 1: return Qt.hsla(0.1, 0.2, 0.9, 1.0);  // Light orange tint for dataset
                        default: return Qt.hsla(0.0, 0.0, 0.9, 1.0); // Light grey for unknown
                      }
                    }
                    border.color: {
                      // Matching border colors
                      switch (type) {
                        case 0: return "#4CAF50"; // Green for local
                        case 1: return "#FF9800"; // Orange for dataset
                        default: return "#9E9E9E"; // Grey for unknown
                      }
                    }
                    border.width: 2
                    
                    // Enhanced shadow using multiple rectangles
                    Rectangle {
                      z: -1
                      anchors.fill: parent
                      anchors.leftMargin: -2
                      anchors.topMargin: -2
                      anchors.rightMargin: -4
                      anchors.bottomMargin: -4
                      color: "#20000000"
                      radius: 8
                    }
                    
                    Rectangle {
                      z: -2
                      anchors.fill: parent
                      anchors.leftMargin: -1
                      anchors.topMargin: -1
                      anchors.rightMargin: -6
                      anchors.bottomMargin: -6
                      color: "#10000000"
                      radius: 8
                    }
                    
                    // Project preview image
                    Rectangle {
                      id: previewContainer
                      anchors.top: parent.top
                      anchors.left: parent.left
                      anchors.right: parent.right
                      height: parent.height * 0.6
                      radius: 8
                      clip: true
                      
                      Image {
                        id: previewImage
                        anchors.fill: parent
                        source: welcomeScreen.visible ? 'image://projects/' + ProjectPath : ''
                        fillMode: Image.PreserveAspectCrop
                        
                        // Fallback when image fails to load
                        Rectangle {
                          anchors.fill: parent
                          color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.2)
                          visible: previewImage.status === Image.Error || previewImage.status === Image.Null
                          
                          Text {
                            anchors.centerIn: parent
                            text: title ? title.charAt(0).toUpperCase() : "P"
                            font.pointSize: 24
                            font.bold: true
                            color: Theme.mainColor
                          }
                        }
                      }
                      
                      // Gradient overlay for better text visibility
                      Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                          GradientStop { position: 0.7; color: "transparent" }
                          GradientStop { position: 1.0; color: "#80000000" }
                        }
                      }
                    }
                    
                    // Project info section
                    Column {
                      anchors.top: previewContainer.bottom
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.bottom: parent.bottom
                      anchors.margins: 8
                      spacing: 2
                      
                      Row {
                        spacing: 8
                        width: parent.width
                        
                        Image {
                          id: typeIcon
                          anchors.verticalCenter: parent.verticalCenter
                          width: 40
                          height: 40
                          source: {
                            switch (type) {
                              case 0: return Theme.getThemeVectorIcon('ic_map_green_48dp');     
                              case 1: return Theme.getThemeVectorIcon('ic_file_48dp');
                              default: return Theme.getThemeVectorIcon('ic_map_green_48dp');    
                            }
                          }
                          sourceSize.width: 80
                          sourceSize.height: 80
                          // Make sure icon is visible even if theme icon fails
                          onStatusChanged: {
                            if (status === Image.Error) {
                              console.log("Failed to load icon for type: " + type);
                              source = "qrc:/images/sigpacgo_logo.svg"; // Fallback to app logo
                            }
                          }
                        }
                        
                        Text {
                          id: projectTitle
                          width: parent.width - typeIcon.width - 8
                          text: title
                          font.pointSize: Theme.tipFont.pointSize
                          font.bold: true
                          color: Theme.mainColor
                          elide: Text.ElideRight
                          maximumLineCount: 1
                        }
                      }
                      
                      Text {
                        id: projectNote
                        width: parent.width
                        text: {
                          var notes = [];
                          if (index == 0) {
                            var firstRun = settings && !settings.value("/QField/FirstRunFlag", false);
                            if (!firstRun && firstShown === false)
                              notes.push(qsTr("Última sesión"));
                          }
                          if (path === registry.defaultProject) {
                            notes.push(qsTr("Proyecto predeterminado"));
                          }
                          if (path === registry.baseMapProject) {
                            notes.push(qsTr("Mapa base"));
                          }
                          if (notes.length > 0) {
                            return notes.join('; ');
                          } else {
                            return "";
                          }
                        }
                        visible: text != ""
                        font.pointSize: Theme.tipFont.pointSize - 2
                        font.italic: true
                        color: Theme.secondaryTextColor
                        elide: Text.ElideRight
                        maximumLineCount: 1
                      }
                    }
                    
                    // Ripple effect for touch feedback
                    Ripple {
                      anchors.fill: parent
                      clip: true
                      pressed: gridDelegate.isPressed
                      active: gridDelegate.isPressed
                      color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.15)
                    }
                    
                    // Menu button
                    Rectangle {
                      id: menuButton
                      anchors.top: parent.top
                      anchors.right: parent.right
                      anchors.topMargin: 6
                      anchors.rightMargin: 6
                      width: 36
                      height: 36
                      radius: 18
                      color: "#40000000"
                      border.color: "#80FFFFFF"
                      border.width: 1
                      
                      Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: Theme.getThemeIcon("ic_more_vert_white_24dp")
                        sourceSize.width: 48
                        sourceSize.height: 48
                        
                        // Fallback if icon not found
                        Text {
                          anchors.centerIn: parent
                          text: "⋮" // Three vertical dots
                          font.pointSize: 16
                          font.bold: true
                          color: "#FFFFFF"
                          visible: parent.status === Image.Error || parent.status === Image.Null
                        }
                      }
                      
                      MouseArea {
                        anchors.fill: parent
                        onClicked: {
                          recentProjectActions.recentProjectPath = gridDelegate.path;
                          recentProjectActions.recentProjectType = gridDelegate.type;
                          recentProjectActions.popup(menuButton.parent.mapToItem(welcomeScreen, menuButton.x, menuButton.y + menuButton.height));
                        }
                      }
                    }
                  }
                  
                  MouseArea {
                    anchors.fill: parent
                    onPressed: {
                      gridDelegate.isPressed = true;
                    }
                    onReleased: {
                      gridDelegate.isPressed = false;
                    }
                    onCanceled: {
                      gridDelegate.isPressed = false;
                    }
                    onClicked: {
                      iface.loadFile(path, title);
                    }
                    onPressAndHold: {
                      recentProjectActions.recentProjectPath = gridDelegate.path;
                      recentProjectActions.recentProjectType = gridDelegate.type;
                      recentProjectActions.popup(mouseX, mouseY);
                    }
                  }
                }
              }
            }
          }

          Menu {
            id: recentProjectActions

            property string recentProjectPath: ''
            property int recentProjectType: 0

            title: qsTr('Acciones del Proyecto Reciente')
            
            // Add background styling
            background: Rectangle {
                implicitWidth: 210
                color: Theme.menuBackgroundColor
                radius: 4
                border.color: Theme.mainColor
                border.width: 1
            }

            width: {
              let result = 210;
              let padding = 0;
              for (let i = 0; i < count; ++i) {
                let item = itemAt(i);
                result = Math.max(item.contentItem.implicitWidth, result);
                padding = Math.max(item.leftPadding + item.rightPadding, padding);
              }
              return mainWindow.width > 0 ? Math.min(result + padding, mainWindow.width - 20) : result + padding;
            }

            topMargin: mainWindow.sceneTopMargin
            bottomMargin: mainWindow.sceneBottomMargin

            MenuItem {
              id: defaultProject
              // Show this menu item for all project types except non-existent ones
              visible: true

              font: Theme.defaultFont
              width: parent.width
              height: visible ? 48 : 0
              leftPadding: Theme.menuItemIconlessLeftPadding
              checkable: true
              checked: recentProjectActions.recentProjectPath === registry.defaultProject
              
              // Add icon
              icon.source: Theme.getThemeIcon("ic_star_black_24dp")
              icon.color: checked ? Theme.mainColor : Theme.secondaryTextColor

              text: qsTr("Proyecto Predeterminado")
              onTriggered: {
                registry.defaultProject = recentProjectActions.recentProjectPath === registry.defaultProject ? '' : recentProjectActions.recentProjectPath;
              }
            }

            MenuItem {
              id: baseMapProject
              // Show this menu item for all project types except non-existent ones
              visible: true

              font: Theme.defaultFont
              width: parent.width
              height: visible ? 48 : 0
              leftPadding: Theme.menuItemIconlessLeftPadding
              checkable: true
              checked: recentProjectActions.recentProjectPath === registry.baseMapProject
              
              // Add icon
              icon.source: Theme.getThemeIcon("ic_map_black_24dp")
              icon.color: checked ? Theme.mainColor : Theme.secondaryTextColor

              text: qsTr("Mapa Base para Conjuntos de Datos")
              onTriggered: {
                registry.baseMapProject = recentProjectActions.recentProjectPath === registry.baseMapProject ? '' : recentProjectActions.recentProjectPath;
              }
            }

            MenuSeparator {
              visible: baseMapProject.visible
              width: parent.width
              height: visible ? undefined : 0
              contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.dividerColor
              }
            }

            MenuItem {
              id: removeProject

              font: Theme.defaultFont
              width: parent.width
              height: visible ? 48 : 0
              leftPadding: Theme.menuItemIconlessLeftPadding
              
              // Add icon
              icon.source: Theme.getThemeIcon("ic_delete_black_24dp")
              icon.color: Theme.errorColor

              text: qsTr("Eliminar de Proyectos Recientes")
              onTriggered: {
                iface.removeRecentProject(recentProjectActions.recentProjectPath);
                model.reloadModel();
              }
            }
          }

          
        }
      }
    }
  }

  Column {
    spacing: 4
    anchors {
      top: parent.top
      left: parent.left
      topMargin: mainWindow.sceneTopMargin + 4
      leftMargin: 4
    }
    QfActionButton {
      id: currentProjectButton
      toolImage: Theme.getThemeVectorIcon('ic_arrow_left_white_24dp')
      toolText: welcomeScreen.width > 420 ? qsTr('Volver al mapa') : ""
      visible: qgisProject && !!qgisProject.homePath
      innerActionIcon.visible: false

      onClicked: {
        welcomeScreen.visible = false;
      }
    }

    QfToolButton {
      id: settingsButton
      iconSource: Theme.getThemeVectorIcon('ic_tune_white_24dp')
      iconColor: Theme.toolButtonColor
      bgcolor: Theme.toolButtonBackgroundColor
      round: true

      onClicked: {
        showSettings();
      }
    }
    
    QfToolButton {
      id: infoButton
      iconSource: Theme.getThemeVectorIcon('ic_info_outline_white_24dp')
      iconColor: Theme.toolButtonColor
      bgcolor: Theme.toolButtonBackgroundColor
      round: true

      onClicked: {
        // Show the information panel
        infoPanel.visible = true;
      }
      
      ToolTip.visible: hovered || pressed
      ToolTip.text: qsTr("Información de SIGPAC-Go")
      ToolTip.delay: 500
    }
  }

  QfToolButton {
    id: exitButton
    visible: qgisProject && !!qgisProject.homePath && (Qt.platform.os === "ios" || Qt.platform.os === "android" || mainWindow.sceneBorderless)
    anchors {
      top: parent.top
      right: parent.right
      topMargin: mainWindow.sceneTopMargin + 4
      rightMargin: 4
    }
    iconSource: Theme.getThemeVectorIcon('ic_shutdown_24dp')
    iconColor: "white"  // White for better visibility on red background
    bgcolor: "#e53935"  // Bright red for better visibility
    round: true
    width: 48  // Increase size
    height: 48 // Increase size
    
    // Add a visible border for better definition
    Rectangle {
      anchors.fill: parent
      anchors.margins: -2
      radius: parent.width / 2 + 2
      color: "transparent"
      border.color: "white"
      border.width: 1
      z: -1
    }

    onClicked: {
      mainWindow.closeAlreadyRequested = true;
      mainWindow.close();
    }
  }

  
    function adjustWelcomeScreen() {
    if (visible) {
      if (firstShown) {
        welcomeText.text = " ";
      } else {
        var firstRun = !settings.valueBool("/QField/FirstRunDone", false);
        if (firstRun) {
          welcomeText.text = qsTr("Bienvenido a SIGPAC-Go");
          settings.setValue("/QField/FirstRunDone", true);
          settings.setValue("/QField/showMapCanvasGuide", true);
        } else {
          welcomeText.text = qsTr("SIGPAC-Go SIG para el campo");
        }
      }
      
      // Regenerate random sequence when welcome screen becomes visible
      if (phrasesListModel) {
        phrasesListModel.generateRandomSequence();
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      // Show terms and conditions when welcome screen becomes visible
      showTermsAndConditions();
      adjustWelcomeScreen();
    }
    if (!visible) {
      firstShown = true;
    } else {
      // Check if the maps exist
      checkMapsExist();
      
      // Debug model info when screen becomes visible
      console.log("Welcome screen visible, model count: " + (model ? model.count : "null"));
      if (model && model.count > 0) {
        console.log("First project: " + model.get(0).ProjectTitle);
      }
    }
  }

  // Function to check if the maps exist and copy them if needed
  function checkMapsExist() {
    console.log("Checking if main map exists at path: " + mainProjectPath);
    
    // Try all possible paths on the device
    const allPossiblePaths = [];
    
    if (Qt.platform.os === "android") {
      const dataDir = platformUtilities.appDataDirs()[0];
      allPossiblePaths.push(
        dataDir + "SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
        dataDir + "sigpacgo_main/SIGPACGO.qgz",
        "/data/user/0/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
        "/data/data/com.imagritools.sigpacgo/files/SIGPACGO_Mapa_Principal/SIGPACGO.qgz",
        dataDir + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
      );
    } else {
      allPossiblePaths.push(
        platformUtilities.applicationDirectory() + "/SIGPACGO_Mapa_Principal/SIGPACGO.qgz"
      );
    }
    
    // Log each path to check
    console.log("Checking all possible paths for SIGPACGO.qgz:");
    for (let i = 0; i < allPossiblePaths.length; i++) {
      console.log("Path " + (i+1) + ": " + allPossiblePaths[i]);
      
      let fileInfo = platformUtilities.getFileInfo(allPossiblePaths[i]);
      if (fileInfo && fileInfo.exists) {
        console.log("Found main map at: " + allPossiblePaths[i]);
        mainProjectPath = allPossiblePaths[i]; // Update to this verified path
        return; // No need to continue if we found the file
      }
    }

    // First try to directly copy all maps without checking
    try {
      console.log("Proactively copying all map resources...");
      
      // Try to copy both main map project and sample projects
      platformUtilities.copySampleProjects(); // This will copy both sample projects and main map
      console.log("Called platformUtilities.copySampleProjects() to copy all required resources");
      
      // List available directories to verify
      if (Qt.platform.os === "android") {
        const dataDir = platformUtilities.appDataDirs()[0];
        console.log("Checking Android app data directory contents: " + dataDir);
        
        // Try to create directories if they don't exist
        console.log("Ensuring SIGPACGO_Mapa_Principal directory exists");
        platformUtilities.createDir(dataDir, "SIGPACGO_Mapa_Principal");
        
        // Check sample_projects dir
        let sampleDirInfo = platformUtilities.getFileInfo(dataDir + "sample_projects");
        if (sampleDirInfo && sampleDirInfo.exists) {
          console.log("sample_projects directory exists");
        } else {
          console.log("sample_projects directory does not exist, explicitly trying to create it");
          platformUtilities.createDir(dataDir, "sample_projects");
        }
        
        // Check SIGPACGO_Mapa_Principal dir
        let mapDirInfo = platformUtilities.getFileInfo(dataDir + "SIGPACGO_Mapa_Principal");
        if (mapDirInfo && mapDirInfo.exists) {
          console.log("SIGPACGO_Mapa_Principal directory exists");
        } else {
          console.log("SIGPACGO_Mapa_Principal directory does not exist, explicitly trying to create it");
          platformUtilities.createDir(dataDir, "SIGPACGO_Mapa_Principal");
        }
        
        // Check directory without slash
        mapDirInfo = platformUtilities.getFileInfo(dataDir + "SIGPACGO_Mapa_Principal");
        if (mapDirInfo && mapDirInfo.exists) {
          console.log("SIGPACGO_Mapa_Principal directory exists (without slash)");
        }
      }
    } catch (e) {
      console.log("Error during proactive map copy: " + e);
    }
    
    // Now check if the main map exists after copying
    for (let i = 0; i < allPossiblePaths.length; i++) {
      let fileInfo = platformUtilities.getFileInfo(allPossiblePaths[i]);
      if (fileInfo && fileInfo.exists) {
        console.log("Found main map after copying at: " + allPossiblePaths[i]);
        mainProjectPath = allPossiblePaths[i]; // Update to this verified path
        return; // No need to continue if we found the file
      }
    }
    
    // If still not found, try direct call to copyMainMapProject
    console.log("Still couldn't find main map, trying direct copy...");
    try {
      platformUtilities.copyMainMapProject();
      console.log("Called platformUtilities.copyMainMapProject() directly");
      
      // Check again
      for (let i = 0; i < allPossiblePaths.length; i++) {
        let fileInfo = platformUtilities.getFileInfo(allPossiblePaths[i]);
        if (fileInfo && fileInfo.exists) {
          console.log("Found main map after direct copy at: " + allPossiblePaths[i]);
          mainProjectPath = allPossiblePaths[i]; // Update to this verified path
          return; // Success!
        }
      }
      
      console.log("Failed to find main map file after all attempts");
    } catch (e) {
      console.log("Error during direct map copy: " + e);
    }
  }

  Keys.onReleased: event => {
    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
      if (infoPanel.visible) {
        infoPanel.visible = false;
        event.accepted = true;
      } else if (qgisProject.fileName != '') {
        event.accepted = true;
        visible = false;
      } else {
        event.accepted = false;
      }
    }
  }
  
  // Information Panel
  Rectangle {
    id: infoPanel
    visible: false
    anchors.fill: parent
    color: "#80000000"
    z: 999
    
    MouseArea {
      anchors.fill: parent
      onClicked: {
        infoPanel.visible = false;
      }
    }
    
    Rectangle {
      id: infoPanelContent
      width: Math.min(parent.width * 0.9, 500)
      height: Math.min(parent.height * 0.8, 600)
      anchors.centerIn: parent
      radius: 10
      color: Theme.secondaryBackgroundColor
      border.color: Theme.mainColor
      border.width: 2
      
      // Prevent clicks on the panel from closing it
      MouseArea {
        anchors.fill: parent
        onClicked: mouse.accepted = true
      }
      
      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        // Header with title and close button
        RowLayout {
          Layout.fillWidth: true
          
          Text {
            text: qsTr("Información de SIGPAC-Go")
            font.pointSize: Theme.defaultFont.pointSize + 4
            font.bold: true
            color: Theme.mainColor
            Layout.fillWidth: true
          }
          
          QfToolButton {
            iconSource: Theme.getThemeVectorIcon('ic_close_white_24dp')
            iconColor: Theme.toolButtonColor
            bgcolor: Theme.toolButtonBackgroundColor
            round: true
            onClicked: {
              infoPanel.visible = false;
            }
          }
        }
        
        // Scrollable content area
        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          ScrollBar.vertical: QfScrollBar {}
          
          ColumnLayout {
            width: infoPanelContent.width - 40
            spacing: 20
            
            // Logo
            Image {
              Layout.alignment: Qt.AlignHCenter
              source: "qrc:/images/sigpacgo_logo.svg"
              Layout.preferredWidth: 120
              Layout.preferredHeight: 120
              fillMode: Image.PreserveAspectFit
            }
            
            // Version info
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: versionText.implicitHeight + 20
              color: Qt.rgba(Theme.mainColor.r, Theme.mainColor.g, Theme.mainColor.b, 0.1)
              radius: 5
              
              Text {
                id: versionText
                anchors.fill: parent
                anchors.margins: 10
                text: qsTr("Versión: beta1.1.0\nBasado en: QGIS 3.40.3 | QField 3.5.2")
                color: Theme.mainColor
                font.pointSize: Theme.defaultFont.pointSize
                horizontalAlignment: Text.AlignHCenter
              }
            }
            
            // Information sections
            Repeater {
              model: [
                { title: qsTr("Acerca de SIGPAC-Go"), content: qsTr("SIGPAC-Go es una aplicación de sistema de información geográfica (SIG) para el campo, especialmente diseñada para consultar y trabajar con datos SIGPAC en campo.") },
                { title: qsTr("Funcionalidades"), content: qsTr("• Visualización de mapas offline\n• Edición de geometrías y atributos\n• Captura de datos con GPS\n• Toma de fotografías geolocalizadas\n• Consulta de parcelas SIGPAC") },
                { title: qsTr("Guía rápida"), content: qsTr("1. Utilice el botón 'Abrir archivo local' para cargar sus propios mapas\n2. Use el 'Mapa Principal SIGPAC-Go' para acceder a la cartografía SIGPAC\n3. Pulse sobre cualquier proyecto reciente para abrirlo") }
              ]
              
              delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                Text {
                  text: modelData.title
                  font.pointSize: Theme.defaultFont.pointSize + 1
                  font.bold: true
                  color: Theme.mainTextColor
                }
                
                Text {
                  text: modelData.content
                  font.pointSize: Theme.defaultFont.pointSize
                  color: Theme.secondaryTextColor
                  wrapMode: Text.WordWrap
                  Layout.fillWidth: true
                }
                
                Rectangle {
                  Layout.fillWidth: true
                  height: 1
                  color: Theme.dividerColor
                  visible: index < 2
                }
              }
            }
            
            // Credits
            Text {
              Layout.fillWidth: true
              text: qsTr("Desarrollado con ❤️ por IMAGRITOOLS")
              font.pointSize: Theme.defaultFont.pointSize - 1
              font.italic: true
              color: Theme.secondaryTextColor
              horizontalAlignment: Text.AlignHCenter
              Layout.topMargin: 10
            }
            
            // Extra space at bottom
            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: 10
            }
          }
        }
      }
    }
  }
}
