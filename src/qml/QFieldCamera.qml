import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Window
import QtMultimedia
import QtCore
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Popup {
  id: cameraItem
  z: 10000 // 1000s are embedded feature forms, use a higher value to insure feature form popups always show above embedded feature forms

  property bool isCapturing: state == "PhotoCapture" || state == "VideoCapture"
  property bool isPortraitMode: mainWindow.height > mainWindow.width

  property string currentPath: ''
  property var currentPosition: PositioningUtils.createEmptyGnssPositionInformation()

  signal finished(string path)
  signal canceled

  x: 0
  y: 0
  width: mainWindow.width
  height: mainWindow.height
  padding: 0

  parent: mainWindow.contentItem
  modal: true
  focus: true

  property string state: "PhotoCapture"
  onStateChanged: {
    if (state == "PhotoCapture") {
      photoPreview.source = '';
      videoPreview.source = '';
    } else if (state == "VideoCapture") {
      photoPreview.source = '';
      videoPreview.source = '';
    }
  }

  onAboutToShow: {
    if (cameraPermission.status === Qt.PermissionStatus.Undetermined) {
      cameraPermission.request();
    } else if (microphonePermission.status === Qt.PermissionStatus.Undetermined) {
      microphonePermission.request();
    }
    recorder.mediaFormat.audioCodec = MediaFormat.AudioCodec.AAC;
    recorder.mediaFormat.videoCodec = MediaFormat.VideoCodec.H264;
    recorder.mediaFormat.fileFormat = MediaFormat.MPEG4;
  }

  Component.onCompleted: {
    let cameraPicked = false;
    if (cameraSettings.deviceId != '') {
      for (const device of mediaDevices.videoInputs) {
        if (device.id == cameraSettings.deviceId) {
          camera.cameraDevice = device;
          cameraPicked = true;
        }
      }
    }
    if (!cameraPicked) {
      camera.cameraDevice = mediaDevices.defaultVideoInput;
    }
    camera.applyCameraFormat(false);
  }

  QfCameraPermission {
    id: cameraPermission

    onStatusChanged: {
      if (microphonePermission.status === Qt.PermissionStatus.Undetermined) {
        microphonePermission.request();
      }
    }
  }
  QfMicrophonePermission {
    id: microphonePermission

    onStatusChanged: {
      if (cameraPermission.status === Qt.PermissionStatus.Undetermined) {
        cameraPermission.request();
      }
    }
  }

  Settings {
    id: cameraSettings
    property bool stamping: false
    property bool geoTagging: true
    property bool showGrid: false
    property bool showOverlay: true
    property string deviceId: ''
    property string folderName: "DCIM" // Default folder name is DCIM
    property string photoPrefix: "" // New property for photo prefix
    property size resolution: Qt.size(0, 0)
    property int pixelFormat: 0
    property string stampTextColor: "#FFFF00" // Yellow text for timestamp
    property string stampBackgroundColor: "#80000000" // Semi-transparent black background
    property int stampFontSize: 24 // Font size for timestamp
    
    // Drawing annotation properties
    property int brushSize: 5 // Default brush size
    property string brushColor: "#FF0000" // Default brush color (red)
    property int textSize: 24 // Default text size
    property string textColor: "#FFFFFF" // Default text color (white)
    
    // GPS accuracy thresholds (in meters)
    property real accuracyThresholdGood: 5.0
    property real accuracyThresholdModerate: 20.0
  }

  // Dialog for setting folder name
  Popup {
    id: folderNameDialog
    visible: false // Hide this dialog since we're using date-based folders only
    width: Math.min(mainWindow.width * 0.9, 400)
    height: folderNameColumn.height + 40
    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height) / 2
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    Column {
      id: folderNameColumn
      width: parent.width - 40
      anchors.centerIn: parent
      spacing: 10
      
      Text {
        width: parent.width
        text: qsTr("Set Folder Name")
        font.bold: true
        font.pixelSize: 16
      }
      
      Text {
        width: parent.width
        text: qsTr("Enter a name for the photo folder. If left empty, photos will be saved in a folder with today's date.")
        font.pixelSize: 12
        wrapMode: Text.WordWrap
      }
      
      TextField {
        id: folderNameField
        width: parent.width
        placeholderText: qsTr("e.g., Greenhouse 1")
        text: cameraSettings.folderName
        leftPadding: 10
        rightPadding: 10
        verticalAlignment: TextInput.AlignVCenter
        
        // Use theme-aware colors for text
        color: Theme.darkTheme ? "white" : "black"
        placeholderTextColor: Theme.darkTheme ? "#aaaaaa" : "#888888"
        
        // Ensure the field gets focus and shows keyboard on Android
        Component.onCompleted: {
          forceActiveFocus()
          if (Qt.platform.os === "android") {
            Qt.inputMethod.show()
          }
        }
        
        // Style the text field to be more visible
        background: Rectangle {
          // Use theme-aware colors
          color: Theme.darkTheme ? "#505050" : "white"
          border.color: folderNameField.activeFocus ? Theme.mainColor : (Theme.darkTheme ? "#aaaaaa" : "#888888")
          border.width: folderNameField.activeFocus ? 2 : 1
          radius: 4
        }
        
        onAccepted: {
          folderNameDialog.accept()
        }
      }
      
      Row {
        width: parent.width
        spacing: 10
        
        Button {
          text: qsTr("Cancel")
          onClicked: folderNameDialog.close()
          width: (parent.width - 10) / 2
        }
        
        Button {
          text: qsTr("Save")
          width: (parent.width - 10) / 2
          onClicked: {
            cameraSettings.folderName = folderNameField.text.trim();
            folderNameDialog.close();
            displayToast(qsTr("Folder name set to: ") + (cameraSettings.folderName || qsTr("Date-based folder")));
          }
        }
      }
    }
  }

  ExpressionEvaluator {
    id: stampExpressionEvaluator

    mode: ExpressionEvaluator.ExpressionMode
    expressionText: "format_date(now(), 'dd-MM-yyyy HH:mm:ss') || if(@gnss_coordinate is not null, format('\n" + qsTr("Latitude") + " %1 | " + qsTr("Longitude") + " %2 | " + qsTr("Altitude") + " %3\n" + qsTr("Speed") + " %4 | " + qsTr("Orientation") + " %5', coalesce(format_number(y(@gnss_coordinate), 7), 'N/A'), coalesce(format_number(x(@gnss_coordinate), 7), 'N/A'), coalesce(format_number(z(@gnss_coordinate), 3) || ' m', 'N/A'), if(@gnss_ground_speed != 'nan', format_number(@gnss_ground_speed, 3) || ' m/s', 'N/A'), if(@gnss_orientation != 'nan', format_number(@gnss_orientation, 1) || ' °', 'N/A')), '')" + 
        " || if(@horizontal_accuracy != 'nan', '\n" + qsTr("Accuracy") + ": ' || format_number(@horizontal_accuracy, 1) || ' m', '')" +
        " || '\n" + qsTr("Project") + ": ' || @project_title" +
        " || '\n" + qsTr("Folder") + ": ' || '" + cameraSettings.folderName + "'" +
        (cameraSettings.photoPrefix ? " || '\n" + qsTr("Series") + ": ' || '" + cameraSettings.photoPrefix + "'" : "") +
        " || '\nSIGPACGO - Agricultural Field Survey'"

    project: qgisProject
    positionInformation: currentPosition
  }

  Page {
    width: parent.width
    height: parent.height
    padding: 0

    background: Rectangle {
      anchors.fill: parent
      color: "#000000"
    }

    MediaDevices {
      id: mediaDevices
    }

    CaptureSession {
      id: captureSession

      camera: Camera {
        id: camera

        property bool restarting: false
        active: cameraItem.visible && cameraPermission.status === Qt.PermissionStatus.Granted && !restarting

        function applyCameraFormat(restart) {
          if (cameraSettings.pixelFormat != 0) {
            let fallbackIndex = -1;
            let i = 0;
            for (let format of camera.cameraDevice.videoFormats) {
              if (format.resolution == cameraSettings.resolution && format.pixelFormat == cameraSettings.pixelFormat) {
                camera.cameraFormat = format;
                fallbackIndex = -1;
                break;
              } else if (format.resolution == cameraSettings.resolution) {
                // If we can't match the pixel format and resolution, go for resolution match across devices
                fallbackIndex = i;
              }
              i++;
            }
            if (fallbackIndex >= 0) {
              camera.cameraFormat = camera.cameraDevice.videoFormats[fallbackIndex];
            }
            if (restart) {
              camera.restarting = true;
              camera.restarting = false;
            }
          }
        }

        function zoomIn(increase) {
          var zoom = camera.zoomFactor + increase;
          if (zoom < camera.maximumZoomFactor) {
            camera.zoomFactor = zoom;
          } else {
            camera.zoomFactor = camera.maximumZoomFactor;
          }
        }

        function zoomOut(decrease) {
          var zoom = camera.zoomFactor - decrease;
          if (zoom > 1) {
            camera.zoomFactor = zoom;
          } else {
            camera.zoomFactor = 1;
          }
        }
      }
      videoOutput: videoOutput
      imageCapture: ImageCapture {
        id: imageCapture

        onImageSaved: (requestId, path) => {
          currentPath = path;
          photoPreview.source = UrlUtils.fromString(path);
          cameraItem.state = "PhotoPreview";
        }
      }
      recorder: MediaRecorder {
        id: recorder

        onRecorderStateChanged: {
          if (cameraItem.state == "VideoPreview" && recorderState === MediaRecorder.StoppedState) {
            videoPreview.source = captureSession.recorder.actualLocation;
            videoPreview.play();
          }
        }
      }
    }

    VideoOutput {
      id: videoOutput
      anchors.fill: parent
      visible: cameraItem.state == "PhotoCapture" || cameraItem.state == "VideoCapture"
      
      Rectangle {
        id: infoOverlay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: infoText.contentHeight + dateTimeText.contentHeight + 30
        color: "#80000000"
        visible: cameraItem.state == "PhotoCapture" && cameraSettings.showOverlay
        
        // Add a gradient background for better visibility
        gradient: Gradient {
          GradientStop { position: 0.0; color: "#00000000" }
          GradientStop { position: 0.3; color: "#A0000000" }
          GradientStop { position: 1.0; color: "#D0000000" }
        }
        
        Rectangle {
          width: 4
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          color: Theme.mainColor
        }
        
        Row {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 10
          anchors.topMargin: 10
          anchors.bottomMargin: 10
          spacing: 10
          
          Column {
            width: parent.width - compassIndicator.width - parent.spacing
            height: parent.height
            spacing: 8
            
            Row {
              width: parent.width
              spacing: 8
              
              Image {
                width: 20
                height: 20
                source: Theme.getThemeVectorIcon("ic_access_time_white_24dp")
                sourceSize.width: 20
                sourceSize.height: 20
              }
              
              Text {
                id: dateTimeText
                width: parent.width - 28
                color: "yellow"
                font.pixelSize: 20
                font.bold: true
                text: {
                  let dateTime = new Date()
                  return Qt.formatDateTime(dateTime, "dd-MM-yyyy | HH:mm:ss")
                }
                
                layer.enabled: true
                layer.effect: QfDropShadow {
                  horizontalOffset: 1
                  verticalOffset: 1
                  radius: 3.0
                  color: "#80000000"
                  source: dateTimeText
                }
              }
            }
            
            Row {
              width: parent.width
              spacing: 8
              visible: infoText.text !== ""
              
              Image {
                width: 20
                height: 20
                source: Theme.getThemeVectorIcon("ic_my_location_white_24dp")
                sourceSize.width: 20
                sourceSize.height: 20
                anchors.verticalCenter: parent.verticalCenter
              }
              
              Item {
                width: parent.width - 28
                height: infoText.contentHeight
                
                // GPS accuracy indicator
                Rectangle {
                  id: accuracyIndicator
                  width: 12
                  height: 12
                  radius: width / 2
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.topMargin: 4
                  
                  visible: positionSource.active && positionSource.positionInformation.latitudeValid
                  
                  // Border for the indicator
                  border.width: 1.5
                  border.color: "white"
                  
                  // Color based on accuracy
                  color: !positionSource.positionInformation || 
                         !positionSource.positionInformation.haccValid || 
                         positionSource.positionInformation.hacc > cameraSettings.accuracyThresholdModerate ? 
                         "#FF4444" : // Bad accuracy (red)
                         positionSource.positionInformation.hacc > cameraSettings.accuracyThresholdGood ? 
                         "#FFBB33" : // Medium accuracy (orange)
                         "#99CC00"   // Good accuracy (green)
                  
                  // Pulsing animation for the indicator
                  SequentialAnimation {
                    id: pulseAnimation
                    running: accuracyIndicator.visible
                    loops: Animation.Infinite
                    
                    PropertyAnimation {
                      target: accuracyIndicator
                      property: "opacity"
                      from: 1.0
                      to: 0.5
                      duration: 1000
                      easing.type: Easing.InOutQuad
                    }
                    
                    PropertyAnimation {
                      target: accuracyIndicator
                      property: "opacity"
                      from: 0.5
                      to: 1.0
                      duration: 1000
                      easing.type: Easing.InOutQuad
                    }
                  }
                  
                  // Tooltip for the indicator
                  ToolTip.visible: accuracyMouseArea.containsMouse
                  ToolTip.text: {
                    if (!positionSource.positionInformation || !positionSource.positionInformation.haccValid) {
                      return qsTr("Accuracy: Unknown")
                    }
                    let accuracy = positionSource.positionInformation.hacc.toFixed(1)
                    let accuracyText = ""
                    
                    if (accuracy > cameraSettings.accuracyThresholdModerate) {
                      accuracyText = qsTr("Poor")
                    } else if (accuracy > cameraSettings.accuracyThresholdGood) {
                      accuracyText = qsTr("Moderate")
                    } else {
                      accuracyText = qsTr("Good")
                    }
                    
                    return qsTr("Accuracy") + ": " + accuracyText + " (" + accuracy + " m)"
                  }
                  
                  MouseArea {
                    id: accuracyMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                  }
                }
                
                Text {
                  id: infoText
                  width: parent.width - (accuracyIndicator.visible ? 20 : 0)
                  color: "yellow"
                  font.pixelSize: 16
                  wrapMode: Text.WordWrap
                  text: {
                    let coordsStr = ""
                    
                    if (positionSource.active && positionSource.positionInformation.latitudeValid && positionSource.positionInformation.longitudeValid) {
                      let lat = positionSource.positionInformation.latitude.toFixed(7)
                      let lon = positionSource.positionInformation.longitude.toFixed(7)
                      let alt = positionSource.positionInformation.elevationValid ? positionSource.positionInformation.elevation.toFixed(2) + " m" : "N/A"
                      
                      // Add accuracy information if available
                      let accuracy = ""
                      if (positionSource.positionInformation.haccValid) {
                        accuracy = " ±" + positionSource.positionInformation.hacc.toFixed(1) + "m"
                      }
                      
                      coordsStr = qsTr("Lat") + ": " + lat + " | " + qsTr("Lon") + ": " + lon + accuracy
                      
                      if (positionSource.positionInformation.elevationValid) {
                        coordsStr += " | " + qsTr("Alt") + ": " + alt
                      }
                      
                      if (positionSource.positionInformation.speedValid) {
                        coordsStr += "\n" + qsTr("Speed") + ": " + positionSource.positionInformation.speed.toFixed(1) + " m/s"
                      }
                      
                      if (positionSource.positionInformation.orientationValid) {
                        coordsStr += " | " + qsTr("Direction") + ": " + positionSource.positionInformation.orientation.toFixed(1) + "°"
                      }
                      
                      // Add project name
                      coordsStr += "\n" + qsTr("Project") + ": " + qgisProject.title
                      
                      // Add agricultural field info if available
                      if (typeof fieldInfo !== 'undefined' && fieldInfo && fieldInfo.fieldName) {
                        coordsStr += "\n" + qsTr("Field") + ": " + fieldInfo.fieldName
                        if (fieldInfo.cropType) {
                          coordsStr += " | " + qsTr("Crop") + ": " + fieldInfo.cropType
                        }
                      }
                      
                      // Add folder info
                      coordsStr += "\n" + qsTr("Saving to") + ": " + cameraSettings.folderName
                      
                      // Add series/prefix info if available
                      if (cameraSettings.photoPrefix) {
                        coordsStr += " | " + qsTr("Series") + ": " + cameraSettings.photoPrefix
                      }
                      
                      // Add photo count if available
                      if (typeof platformUtilities.countFilesInDir === 'function') {
                        try {
                          let count = platformUtilities.countFilesInDir(qgisProject.homePath + '/' + cameraSettings.folderName, "*.jpg")
                          coordsStr += " | " + qsTr("Photos") + ": " + count
                        } catch (e) {
                          // Ignore errors if function not available
                        }
                      }
                      
                      return coordsStr
                    } else {
                      return qsTr("GPS coordinates not available") + 
                             "\n" + qsTr("Project") + ": " + qgisProject.title +
                             "\n" + qsTr("Saving to") + ": " + cameraSettings.folderName
                    }
                  }
                  
                  layer.enabled: true
                  layer.effect: QfDropShadow {
                    horizontalOffset: 1
                    verticalOffset: 1
                    radius: 3.0
                    color: "#80000000"
                    source: infoText
                  }
                }
              }
            }
            
            // Weather info row (placeholder for future implementation)
            Row {
              width: parent.width
              spacing: 8
              visible: false // Hidden until weather data is available
              
              Image {
                width: 20
                height: 20
                source: Theme.getThemeVectorIcon("ic_wb_sunny_white_24dp")
                sourceSize.width: 20
                sourceSize.height: 20
              }
              
              Text {
                id: weatherText
                width: parent.width - 28
                color: "white"
                font.pixelSize: 14
                text: "25°C | Sunny | Humidity: 45%"
                
                layer.enabled: true
                layer.effect: QfDropShadow {
                  horizontalOffset: 1
                  verticalOffset: 1
                  radius: 3.0
                  color: "#80000000"
                  source: weatherText
                }
              }
            }
            
            // Battery level row
            Row {
              width: parent.width
              spacing: 8
              visible: typeof platformUtilities.batteryLevel === 'function'
              
              Image {
                width: 20
                height: 20
                source: {
                  try {
                    let level = platformUtilities.batteryLevel()
                    if (level > 75) return Theme.getThemeVectorIcon("ic_battery_full_white_24dp")
                    if (level > 50) return Theme.getThemeVectorIcon("ic_battery_3_bar_white_24dp")
                    if (level > 25) return Theme.getThemeVectorIcon("ic_battery_2_bar_white_24dp")
                    return Theme.getThemeVectorIcon("ic_battery_1_bar_white_24dp")
                  } catch (e) {
                    return Theme.getThemeVectorIcon("ic_battery_unknown_white_24dp")
                  }
                }
                sourceSize.width: 20
                sourceSize.height: 20
              }
              
              Text {
                id: batteryText
                width: parent.width - 28
                color: {
                  try {
                    let level = platformUtilities.batteryLevel()
                    if (level <= 15) return "red"
                    if (level <= 30) return "#FFCC00" // Yellow
                    return "white"
                  } catch (e) {
                    return "white"
                  }
                }
                font.pixelSize: 14
                text: {
                  try {
                    let level = platformUtilities.batteryLevel()
                    return qsTr("Battery") + ": " + level + "%"
                  } catch (e) {
                    return qsTr("Battery level unknown")
                  }
                }
                
                layer.enabled: true
                layer.effect: QfDropShadow {
                  horizontalOffset: 1
                  verticalOffset: 1
                  radius: 3.0
                  color: "#80000000"
                  source: batteryText
                }
              }
            }
          }
          
          Item {
            id: compassIndicator
            width: 50
            height: parent.height
            visible: positionSource.active && positionSource.positionInformation.orientationValid
            
            Rectangle {
              id: compassCircle
              anchors.centerIn: parent
              width: Math.min(parent.width, parent.height) - 4
              height: width
              radius: width / 2
              color: "#40FFFFFF"
              border.color: "white"
              border.width: 1
              
              Text {
                anchors.centerIn: parent
                text: "N"
                color: "white"
                font.pixelSize: 12
                font.bold: true
              }
              
              Rectangle {
                id: compassNeedle
                anchors.centerIn: parent
                width: 2
                height: parent.height * 0.8
                color: Theme.mainColor
                antialiasing: true
                transform: Rotation {
                  origin.x: compassNeedle.width / 2
                  origin.y: compassNeedle.height / 2
                  angle: positionSource.positionInformation.orientationValid ? positionSource.positionInformation.orientation : 0
                }
              }
            }
            
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: compassCircle.bottom
              anchors.topMargin: 2
              text: positionSource.positionInformation.orientationValid ? Math.round(positionSource.positionInformation.orientation) + "°" : ""
              color: "white"
              font.pixelSize: 10
              font.bold: true
            }
          }
        }
        
        Timer {
          interval: 1000
          running: infoOverlay.visible
          repeat: true
          onTriggered: {
            // Force update of the bindings
            dateTimeText.text = dateTimeText.text
            infoText.text = infoText.text
            if (compassIndicator.visible) {
              compassNeedle.rotation = positionSource.positionInformation.orientation
            }
          }
        }
      }
    }

    Shape {
      id: grid
      visible: cameraSettings.showGrid
      anchors.centerIn: parent

      property bool isLandscape: (mainWindow.width / mainWindow.height) > (videoOutput.contentRect.width / videoOutput.contentRect.height)

      width: isLandscape ? videoOutput.contentRect.width * mainWindow.height / videoOutput.contentRect.height : mainWindow.width
      height: isLandscape ? mainWindow.height : videoOutput.contentRect.height * mainWindow.width / videoOutput.contentRect.width

      ShapePath {
        strokeColor: "#99000000"
        strokeWidth: 3
        fillColor: "transparent"

        startX: grid.width / 3
        startY: 0

        PathLine {
          x: grid.width / 3
          y: grid.height
        }
        PathMove {
          x: grid.width / 3 * 2
          y: 0
        }
        PathLine {
          x: grid.width / 3 * 2
          y: grid.height
        }
        PathMove {
          x: 0
          y: grid.height / 3
        }
        PathLine {
          x: grid.width
          y: grid.height / 3
        }
        PathMove {
          x: 0
          y: grid.height / 3 * 2
        }
        PathLine {
          x: grid.width
          y: grid.height / 3 * 2
        }
      }

      ShapePath {
        strokeColor: "#AAFFFFFF"
        strokeWidth: 1
        fillColor: "transparent"

        startX: grid.width / 3
        startY: 0

        PathLine {
          x: grid.width / 3
          y: grid.height
        }
        PathMove {
          x: grid.width / 3 * 2
          y: 0
        }
        PathLine {
          x: grid.width / 3 * 2
          y: grid.height
        }
        PathMove {
          x: 0
          y: grid.height / 3
        }
        PathLine {
          x: grid.width
          y: grid.height / 3
        }
        PathMove {
          x: 0
          y: grid.height / 3 * 2
        }
        PathLine {
          x: grid.width
          y: grid.height / 3 * 2
        }
      }
    }

    Video {
      id: videoPreview
      anchors.fill: parent

      visible: cameraItem.state == "VideoPreview"

      loops: MediaPlayer.Infinite
      muted: true
    }

    Image {
      id: photoPreview

      visible: cameraItem.state == "PhotoPreview"

      anchors.fill: parent

      fillMode: Image.PreserveAspectFit
      smooth: true
      focus: visible
    }

    PinchArea {
      id: pinchArea
      enabled: cameraItem.visible && cameraItem.isCapturing
      anchors.fill: parent

      onPinchUpdated: pinch => {
        if (pinch.scale > pinch.previousScale) {
          camera.zoomIn(0.05);
        } else {
          camera.zoomOut(0.05);
        }
      }
    }

    WheelHandler {
      enabled: cameraItem.visible && cameraItem.isCapturing
      target: null
      grabPermissions: PointerHandler.CanTakeOverFromHandlersOfDifferentType | PointerHandler.ApprovesTakeOverByItems

      onWheel: event => {
        if (event.angleDelta.y > 0) {
          camera.zoomIn(0.25);
        } else {
          camera.zoomOut(0.25);
        }
      }
    }

    Rectangle {
      x: cameraItem.isPortraitMode ? 0 : parent.width - 100
      y: cameraItem.isPortraitMode ? parent.height - 100 : 0
      width: cameraItem.isPortraitMode ? parent.width : 100
      height: cameraItem.isPortraitMode ? 100 : parent.height

      color: Theme.darkGraySemiOpaque

      Rectangle {
        x: cameraItem.isPortraitMode ? 0 : parent.width - 100
        y: cameraItem.isPortraitMode ? parent.height - 100 - mainWindow.sceneBottomMargin : 0
        width: cameraItem.isPortraitMode ? parent.width : 100
        height: cameraItem.isPortraitMode ? 100 + mainWindow.sceneBottomMargin : parent.height

        color: Theme.darkGraySemiOpaque

        Rectangle {
          anchors.top: parent.top
          width: parent.width
          height: cameraItem.isPortraitMode ? parent.height - mainWindow.sceneBottomMargin : parent.height
          color: "transparent"

          Rectangle {
            id: captureRing
            anchors.centerIn: parent
            width: 64
            height: 64
            radius: 32
            color: Theme.darkGraySemiOpaque
            border.color: cameraItem.state == "VideoCapture" && captureSession.recorder.recorderState !== MediaRecorder.StoppedState ? "red" : "white"
            border.width: 2

            QfToolButton {
              id: captureButton

              anchors.centerIn: parent
              visible: camera.cameraStatus == Camera.ActiveStatus || camera.cameraStatus == Camera.LoadedStatus || camera.cameraStatus == Camera.StandbyStatus

              round: true
              roundborder: true
              iconSource: cameraItem.state == "PhotoPreview" || cameraItem.state == "VideoPreview" ? Theme.getThemeVectorIcon("ic_check_white_24dp") : ''
              iconColor: Theme.toolButtonColor
              bgcolor: cameraItem.state == "PhotoPreview" || cameraItem.state == "VideoPreview" ? Theme.mainColor : cameraItem.state == "VideoCapture" ? "red" : "white"

              onClicked: {
                if (cameraItem.state == "PhotoCapture") {
                  // Create DCIM folder if it doesn't exist
                  platformUtilities.createDir(qgisProject.homePath, cameraSettings.folderName);
                  
                  // Get current date/time for filename
                  let today = new Date();
                  let dateStr = today.getFullYear().toString() +
                               (today.getMonth() + 1).toString().padStart(2, '0') +
                               today.getDate().toString().padStart(2, '0');
                  
                  let timestamp = today.getHours().toString().padStart(2, '0') +
                                 today.getMinutes().toString().padStart(2, '0') +
                                 today.getSeconds().toString().padStart(2, '0');
                  
                  // Add prefix if it exists
                  let prefix = cameraSettings.photoPrefix ? cameraSettings.photoPrefix + "_" : "";
                  let filename = prefix + "IMG_" + dateStr + "_" + timestamp + ".jpg";
                  
                  // Capture the photo to the specified folder with the constructed filename
                  captureSession.imageCapture.captureToFile(qgisProject.homePath + '/' + cameraSettings.folderName + '/' + filename);
                  
                  if (positionSource.active) {
                    currentPosition = positionSource.positionInformation;
                  } else {
                    currentPosition = PositioningUtils.createEmptyGnssPositionInformation();
                  }
                  if (cameraSettings.geoTagging && !positionSource.active) {
                    displayToast(qsTr("Image geotagging requires positioning to be turned on"), "warning");
                  }
                } else if (cameraItem.state == "VideoCapture") {
                  if (captureSession.recorder.recorderState === MediaRecorder.StoppedState) {
                    captureSession.recorder.record();
                  } else {
                    cameraItem.state = "VideoPreview";
                    captureSession.recorder.stop();
                    var path = captureSession.recorder.actualLocation.toString();
                    var filePos = path.indexOf('file://');
                    currentPath = filePos === 0 ? path.substring(7) : path;
                  }
                } else if (cameraItem.state == "PhotoPreview" || cameraItem.state == "VideoPreview") {
                  if (cameraItem.state == "PhotoPreview") {
                    if (cameraSettings.geoTagging && positionSource.active) {
                      FileUtils.addImageMetadata(currentPath, currentPosition);
                      // Set the Make to SIGPACGO instead of QField
                      platformUtilities.setExifTag(currentPath, "Exif.Image.Make", "SIGPACGO");
                      platformUtilities.setExifTag(currentPath, "Xmp.tiff.Make", "SIGPACGO");
                    }
                    if (cameraSettings.stamping) {
                      // Apply custom styling to the timestamp
                      let stampText = stampExpressionEvaluator.evaluate();
                      let styledStamp = {
                        "text": stampText,
                        "color": cameraSettings.stampTextColor,
                        "backgroundColor": cameraSettings.stampBackgroundColor,
                        "fontSize": cameraSettings.stampFontSize,
                        "padding": 10,
                        "position": "bottomLeft" // Position in the image
                      };
                      FileUtils.addImageStamp(currentPath, stampText, styledStamp);
                    }
                  }
                  cameraItem.finished(currentPath);
                }
              }
            }
          }

          QfToolButton {
            id: zoomButton
            visible: cameraItem.isCapturing && (camera.maximumZoomFactor !== 1.0 || camera.minimumZoomFactor !== 1.0)

            x: cameraItem.isPortraitMode ? (parent.width / 4) - (width / 2) : (parent.width - width) / 2
            y: cameraItem.isPortraitMode ? (parent.height - height) / 2 : (parent.height / 4) * 3 - (height / 2)

            iconColor: Theme.toolButtonColor
            bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
            round: true

            text: camera.zoomFactor.toFixed(1) + 'X'
            font: Theme.tinyFont

            onClicked: {
              camera.zoomFactor = 1;
            }
          }

          QfToolButton {
            id: flashButton
            visible: cameraItem.isCapturing && camera.isFlashModeSupported(Camera.FlashOn)

            x: cameraItem.isPortraitMode ? (parent.width / 4) * 3 - (width / 2) : (parent.width - width) / 2
            y: cameraItem.isPortraitMode ? (parent.height - height) / 2 : (parent.height / 4) - (height / 2)

            iconSource: {
              switch (camera.flashMode) {
              case Camera.FlashAuto:
                return Theme.getThemeVectorIcon('ic_flash_auto_black_24dp');
              case Camera.FlashOn:
                return Theme.getThemeVectorIcon('ic_flash_on_black_24dp');
              case Camera.FlashOff:
                return Theme.getThemeVectorIcon('ic_flash_off_black_24dp');
              default:
                return '';
              }
            }
            iconColor: Theme.toolButtonColor
            bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
            round: true

            onClicked: {
              if (camera.flashMode === Camera.FlashOff) {
                camera.flashMode = Camera.FlashOn;
              } else {
                camera.flashMode = Camera.FlashOff;
              }
            }
          }

          Rectangle {
            visible: cameraItem.state == "VideoCapture" && captureSession.recorder.recorderState !== MediaRecorder.StoppedState

            x: cameraItem.isPortraitMode ? captureRing.x + captureRing.width / 2 - width / 2 : captureRing.x + captureRing.width / 2 - width / 2
            y: cameraItem.isPortraitMode ? captureRing.y - height - 20 : captureRing.y - height - 20

            width: durationLabelMetrics.boundingRect('00:00:00').width + 20
            height: durationLabelMetrics.boundingRect('00:00:00').height + 10
            radius: 6

            color: 'red'

            Text {
              id: durationLabel
              anchors.centerIn: parent
              text: {
                if (captureSession.recorder.duration > 0) {
                  var seconds = Math.ceil(captureSession.recorder.duration / 1000);
                  var hours = Math.floor(seconds / 60 / 60) + '';
                  seconds -= hours * 60 * 60;
                  var minutes = Math.floor(seconds / 60) + '';
                  seconds = (seconds - minutes * 60) + '';
                  return hours.padStart(2, '0') + ':' + minutes.padStart(2, '0') + ':' + seconds.padStart(2, '0');
                } else {
                  // tiny bit of a cheat here as the first second isn't triggered
                  return '00:00:01';
                }
              }
              color: "white"
            }

            FontMetrics {
              id: durationLabelMetrics
              font: durationLabel.font
            }
          }
        }
      }
    }

    QfToolButton {
      id: backButton

      anchors.left: parent.left
      anchors.leftMargin: 4
      anchors.top: parent.top
      anchors.topMargin: mainWindow.sceneTopMargin + 4

      iconSource: Theme.getThemeVectorIcon("ic_chevron_left_white_24dp")
      iconColor: Theme.toolButtonColor
      bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
      round: true

      onClicked: {
        if (cameraItem.state == "PhotoPreview") {
          cameraItem.state = "PhotoCapture";
        } else if (cameraItem.state == "VideoPreview") {
          videoPreview.stop();
          cameraItem.state = "VideoCapture";
        } else {
          if (currentPath != '') {
            platformUtilities.rmFile(currentPath);
          }
          cameraItem.canceled();
        }
      }
    }

    QfToolButtonDrawer {
      name: "cameraSettingsDrawer"

      anchors.left: parent.left
      anchors.leftMargin: 4
      anchors.top: backButton.bottom
      anchors.topMargin: 4

      iconSource: Theme.getThemeVectorIcon("ic_camera_settings_black_24dp")
      iconColor: Theme.toolButtonColor
      bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
      spacing: 4
      collapsed: false

      QfToolButton {
        id: cameraSelectionButton

        width: 40
        height: cameraSelectionMenu.count > 1 ? width : 0
        visible: cameraSelectionMenu.count
        padding: 2

        iconSource: Theme.getThemeVectorIcon("ic_camera_switch_black_24dp")
        iconColor: Theme.toolButtonColor
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          cameraSelectionMenu.popup(cameraSelectionButton.x, cameraSelectionButton.y);
        }
      }

      QfToolButton {
        id: resolutionSelectionButton

        width: 40
        height: resolutionSelectionMenu.count > 1 ? width : 0
        visible: resolutionSelectionMenu.count
        padding: 2

        iconSource: Theme.getThemeVectorIcon("ic_camera_resolution_black_24dp")
        iconColor: Theme.toolButtonColor
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          resolutionSelectionMenu.popup(resolutionSelectionButton.x, resolutionSelectionButton.y);
        }
      }

      QfToolButton {
        id: stampingButton

        width: 40
        height: 40
        padding: 2

        iconSource: Theme.getThemeVectorIcon("ic_text_black_24dp")
        iconColor: cameraSettings.stamping ? Theme.mainColor : Theme.toolButtonColor
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          cameraSettings.stamping = !cameraSettings.stamping;
          displayToast(cameraSettings.stamping ? qsTr("Details stamping enabled") : qsTr("Details stamping disabled"));
        }
        
        ToolTip.visible: hovered
        ToolTip.text: cameraSettings.stamping ? qsTr("Disable photo stamping") : qsTr("Enable photo stamping")
      }

      QfToolButton {
        id: overlayButton

        width: 40
        height: 40
        padding: 2

        iconSource: Theme.getThemeVectorIcon("ic_layers_white_24dp")
        iconColor: cameraSettings.showOverlay ? Theme.mainColor : Theme.toolButtonColor
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          cameraSettings.showOverlay = !cameraSettings.showOverlay;
          displayToast(cameraSettings.showOverlay ? qsTr("Info overlay enabled") : qsTr("Info overlay disabled"));
        }
        
        ToolTip.visible: hovered
        ToolTip.text: cameraSettings.showOverlay ? qsTr("Hide info overlay") : qsTr("Show info overlay")
      }

      QfToolButton {
        id: geotagButton

        width: 40
        height: 40
        padding: 2

        iconSource: positionSource.active ? Theme.getThemeVectorIcon("ic_geotag_white_24dp") : Theme.getThemeVectorIcon("ic_geotag_missing_white_24dp")
        iconColor: cameraSettings.geoTagging ? Theme.mainColor : Theme.toolButtonColor
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          cameraSettings.geoTagging = !cameraSettings.geoTagging;
          displayToast(cameraSettings.geoTagging ? qsTr("Geotagging enabled") : qsTr("Geotagging disabled"));
        }
      }

      QfToolButton {
        id: gridButton

        width: 40
        height: 40
        padding: 2

        iconSource: Theme.getThemeVectorIcon("ic_3x3_grid_white_24dp")
        iconColor: cameraSettings.showGrid ? Theme.mainColor : Theme.toolButtonColor
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          cameraSettings.showGrid = !cameraSettings.showGrid;
          displayToast(cameraSettings.showGrid ? qsTr("Grid enabled") : qsTr("Grid disabled"));
        }
      }
      
      QfToolButton {
        id: folderNameButton

        width: 40
        height: 40
        padding: 2
        visible: true // Make the button visible

        iconSource: Theme.getThemeVectorIcon("ic_folder_white_24dp")
        iconColor: Theme.mainColor // Always show as enabled
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          // Create a dialog to set the folder name
          let dialog = Qt.createQmlObject(`
            import QtQuick
            import QtQuick.Controls
            import QtQuick.Layouts
            import Theme
            
            Dialog {
              id: folderDialog
              modal: true
              
              // Set explicit dimensions to avoid binding loops
              x: (parent.width - 380) / 2
              y: (parent.height - 300) / 2
              width: 380
              height: 300
              
              // Remove standardButtons to avoid binding loops
              standardButtons: Dialog.NoButton
              
              // Make the dialog more visible with a distinct background
              background: Rectangle {
                // Use theme-aware colors
                color: Theme.darkTheme ? "#303030" : "#f0f0f0"
                border.color: Theme.mainColor
                border.width: 2
                radius: 8
              }
              
              // Add a header with a title
              header: Rectangle {
                color: Theme.mainColor
                height: 50
                width: parent.width
                
                Label {
                  anchors.centerIn: parent
                  text: qsTr("Set Photo Folder")
                  font.bold: true
                  font.pixelSize: 18
                  color: "white"
                }
              }
              
              contentItem: Item {
                width: parent.width
                height: 180
                
                Column {
                  anchors.fill: parent
                  anchors.margins: 16
                  spacing: 16
                  
                  Label {
                    width: parent.width
                    text: qsTr("Enter folder name:")
                    font.pixelSize: 16
                    font.bold: true
                    // Use theme-aware text color
                    color: Theme.darkTheme ? "white" : "#333333"
                  }
                  
                  TextField {
                    id: folderNameField
                    width: parent.width
                    height: 50
                    text: cameraSettings.folderName
                    placeholderText: qsTr("e.g., Greenhouse 1")
                    font.pixelSize: 18
                    
                    // Use theme-aware colors for text
                    color: Theme.darkTheme ? "white" : "black"
                    placeholderTextColor: Theme.darkTheme ? "#aaaaaa" : "#888888"
                    
                    // Fix placeholder text positioning
                    leftPadding: 10
                    rightPadding: 10
                    verticalAlignment: TextInput.AlignVCenter
                    
                    // Ensure the field gets focus and shows keyboard on Android
                    Component.onCompleted: {
                      forceActiveFocus()
                      if (Qt.platform.os === "android") {
                        Qt.inputMethod.show()
                      }
                    }
                    
                    // Style the text field to be more visible
                    background: Rectangle {
                      // Use theme-aware colors
                      color: Theme.darkTheme ? "#505050" : "white"
                      border.color: folderNameField.activeFocus ? Theme.mainColor : (Theme.darkTheme ? "#aaaaaa" : "#888888")
                      border.width: folderNameField.activeFocus ? 2 : 1
                      radius: 4
                    }
                    
                    onAccepted: {
                      folderDialog.accept()
                    }
                  }
                  
                  Label {
                    width: parent.width
                    text: qsTr("Default is DCIM. This folder will be created in the project directory.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    // Use theme-aware text color
                    color: Theme.darkTheme ? "#cccccc" : "#555555"
                  }
                }
              }
              
              // Custom footer with buttons
              footer: Rectangle {
                width: parent.width
                height: 70
                // Use theme-aware background
                color: "transparent"
                
                Row {
                  anchors.centerIn: parent
                  spacing: 20
                  
                  Button {
                    width: 150
                    height: 50
                    text: qsTr("Cancel")
                    
                    background: Rectangle {
                      // Use theme-aware colors
                      color: Theme.darkTheme ? "#404040" : "#dddddd"
                      radius: 4
                      border.color: Theme.darkTheme ? "#aaaaaa" : "#888888"
                      border.width: 1
                    }
                    
                    contentItem: Text {
                      text: qsTr("Cancel")
                      font.pixelSize: 16
                      font.bold: true
                      // Use theme-aware text color
                      color: Theme.darkTheme ? "white" : "#333333"
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                      folderDialog.reject()
                    }
                  }
                  
                  Button {
                    width: 150
                    height: 50
                    text: qsTr("Save")
                    
                    background: Rectangle {
                      color: Theme.mainColor
                      radius: 4
                      border.color: Qt.darker(Theme.mainColor, 1.3)
                      border.width: 1
                    }
                    
                    contentItem: Text {
                      text: qsTr("Save")
                      font.pixelSize: 16
                      font.bold: true
                      color: "white"
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                      folderDialog.accept()
                    }
                  }
                }
              }
              
              onAccepted: {
                let newFolderName = folderNameField.text.trim()
                if (newFolderName) {
                  cameraSettings.folderName = newFolderName
                  displayToast(qsTr("Photos will be saved to: ") + newFolderName)
                  
                  // Create the folder if it doesn't exist
                  platformUtilities.createDir(qgisProject.homePath, cameraSettings.folderName)
                }
              }
              
              // Hide keyboard when dialog is closed
              onClosed: {
                if (Qt.platform.os === "android") {
                  Qt.inputMethod.hide()
                }
              }
            }
          `, cameraItem, "folderDialog")
          
          dialog.open()
        }
        
        ToolTip.visible: hovered
        ToolTip.text: qsTr("Set photo folder (current: ") + cameraSettings.folderName + ")"
      }

      QfToolButton {
        id: photoPrefixButton

        width: 40
        height: 40
        padding: 2
        visible: true // Make the button visible

        iconSource: Theme.getThemeVectorIcon("ic_label_white_24dp")
        iconColor: cameraSettings.photoPrefix ? Theme.mainColor : Theme.toolButtonColor
        bgcolor: Theme.toolButtonBackgroundSemiOpaqueColor
        round: true

        onClicked: {
          // Create a dialog to set the photo prefix
          let dialog = Qt.createQmlObject(`
            import QtQuick
            import QtQuick.Controls
            import QtQuick.Layouts
            import Theme
            
            Dialog {
              id: prefixDialog
              modal: true
              
              // Set explicit dimensions to avoid binding loops
              x: (parent.width - 380) / 2
              y: (parent.height - 300) / 2
              width: 380
              height: 300
              
              // Remove standardButtons to avoid binding loops
              standardButtons: Dialog.NoButton
              
              // Make the dialog more visible with a distinct background
              background: Rectangle {
                // Use theme-aware colors
                color: Theme.darkTheme ? "#303030" : "#f0f0f0"
                border.color: Theme.mainColor
                border.width: 2
                radius: 8
              }
              
              // Add a header with a title
              header: Rectangle {
                color: Theme.mainColor
                height: 50
                width: parent.width
                
                Label {
                  anchors.centerIn: parent
                  text: qsTr("Set Photo Series")
                  font.bold: true
                  font.pixelSize: 18
                  color: "white"
                }
              }
              
              contentItem: Item {
                width: parent.width
                height: 180
                
                Column {
                  anchors.fill: parent
                  anchors.margins: 16
                  spacing: 16
                  
                  Label {
                    width: parent.width
                    text: qsTr("Enter photo series prefix:")
                    font.pixelSize: 16
                    font.bold: true
                    // Use theme-aware text color
                    color: Theme.darkTheme ? "white" : "#333333"
                  }
                  
                  TextField {
                    id: prefixField
                    width: parent.width
                    height: 50
                    text: cameraSettings.photoPrefix
                    placeholderText: qsTr("e.g., Nave1, Field3, Plot5")
                    font.pixelSize: 18
                    
                    // Use theme-aware colors for text
                    color: Theme.darkTheme ? "white" : "black"
                    placeholderTextColor: Theme.darkTheme ? "#aaaaaa" : "#888888"
                    
                    // Fix placeholder text positioning
                    leftPadding: 10
                    rightPadding: 10
                    verticalAlignment: TextInput.AlignVCenter
                    
                    // Ensure the field gets focus and shows keyboard on Android
                    Component.onCompleted: {
                      forceActiveFocus()
                      if (Qt.platform.os === "android") {
                        Qt.inputMethod.show()
                      }
                    }
                    
                    // Style the text field to be more visible
                    background: Rectangle {
                      // Use theme-aware colors
                      color: Theme.darkTheme ? "#505050" : "white"
                      border.color: prefixField.activeFocus ? Theme.mainColor : (Theme.darkTheme ? "#aaaaaa" : "#888888")
                      border.width: prefixField.activeFocus ? 2 : 1
                      radius: 4
                    }
                    
                    onAccepted: {
                      prefixDialog.accept()
                    }
                  }
                  
                  Label {
                    width: parent.width
                    text: qsTr("This prefix will be added to photo filenames and shown in the overlay and stamp.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    // Use theme-aware text color
                    color: Theme.darkTheme ? "#cccccc" : "#555555"
                  }
                }
              }
              
              // Custom footer with buttons
              footer: Rectangle {
                width: parent.width
                height: 70
                // Use theme-aware background
                color: "transparent"
                
                Row {
                  anchors.centerIn: parent
                  spacing: 20
                  
                  Button {
                    width: 150
                    height: 50
                    text: qsTr("Cancel")
                    
                    background: Rectangle {
                      // Use theme-aware colors
                      color: Theme.darkTheme ? "#404040" : "#dddddd"
                      radius: 4
                      border.color: Theme.darkTheme ? "#aaaaaa" : "#888888"
                      border.width: 1
                    }
                    
                    contentItem: Text {
                      text: qsTr("Cancel")
                      font.pixelSize: 16
                      font.bold: true
                      // Use theme-aware text color
                      color: Theme.darkTheme ? "white" : "#333333"
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                      prefixDialog.reject()
                    }
                  }
                  
                  Button {
                    width: 150
                    height: 50
                    text: qsTr("Save")
                    
                    background: Rectangle {
                      color: Theme.mainColor
                      radius: 4
                      border.color: Qt.darker(Theme.mainColor, 1.3)
                      border.width: 1
                    }
                    
                    contentItem: Text {
                      text: qsTr("Save")
                      font.pixelSize: 16
                      font.bold: true
                      color: "white"
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                      prefixDialog.accept()
                    }
                  }
                }
              }
              
              onAccepted: {
                let newPrefix = prefixField.text.trim()
                cameraSettings.photoPrefix = newPrefix
                if (newPrefix) {
                  displayToast(qsTr("Photo series set to: ") + newPrefix)
                } else {
                  displayToast(qsTr("Photo series prefix cleared"))
                }
              }
              
              // Hide keyboard when dialog is closed
              onClosed: {
                if (Qt.platform.os === "android") {
                  Qt.inputMethod.hide()
                }
              }
            }
          `, cameraItem, "prefixDialog")
          
          dialog.open()
        }
        
        ToolTip.visible: hovered
        ToolTip.text: cameraSettings.photoPrefix ? 
                     qsTr("Change photo series (current: ") + cameraSettings.photoPrefix + ")" :
                     qsTr("Set photo series prefix")
      }
    }

    Menu {
      id: cameraSelectionMenu

      topMargin: sceneTopMargin
      bottomMargin: sceneBottomMargin
      z: 10000 // 1000s are embedded feature forms, use higher value

      width: {
        let result = 50;
        let padding = 0;
        for (let i = 0; i < count; ++i) {
          let item = itemAt(i);
          result = Math.max(item.contentItem.implicitWidth, result);
          padding = Math.max(item.leftPadding + item.rightPadding, padding);
        }
        return mainWindow.width > 0 ? Math.min(result + padding, mainWindow.width - 20) : 0;
      }

      Repeater {
        model: mediaDevices.videoInputs

        delegate: MenuItem {
          property string deviceId: modelData.id
          property bool isDefault: modelData.isDefault

          text: modelData.description + (modelData.position !== CameraDevice.UnspecifiedPosition ? ' (' + (modelData.position === CameraDevice.FrontFace ? qsTr('front') : qsTr('back')) + ')' : '')
          height: 48
          leftPadding: Theme.menuItemCheckLeftPadding
          font: Theme.defaultFont
          enabled: !checked
          checkable: true
          checked: deviceId == cameraSettings.deviceId || (isDefault && cameraSettings.deviceId == '')
          indicator.height: 20
          indicator.width: 20
          indicator.implicitHeight: 24
          indicator.implicitWidth: 24

          onCheckedChanged: {
            if (checked && cameraSettings.deviceId !== modelData.id) {
              cameraSettings.deviceId = modelData.id;
              camera.cameraDevice = modelData;
              camera.applyCameraFormat(true);
            }
          }
        }
      }
    }

    Menu {
      id: resolutionSelectionMenu

      topMargin: sceneTopMargin
      bottomMargin: sceneBottomMargin
      z: 10000 // 1000s are embedded feature forms, use higher value

      width: {
        let result = 50;
        let padding = 0;
        for (let i = 0; i < count; ++i) {
          let item = itemAt(i);
          result = Math.max(item.contentItem.implicitWidth, result);
          padding = Math.max(item.leftPadding + item.rightPadding, padding);
        }
        return mainWindow.width > 0 ? Math.min(result + padding, mainWindow.width - 20) : 0;
      }

      function ratioFromResolution(resolution) {
        let smallerValue = Math.min(resolution.width, resolution.height);
        let gdc = 0;
        for (let i = 1; i < smallerValue; i++) {
          if (resolution.width % i === 0 && resolution.height % i === 0) {
            gdc = i;
          }
        }
        return resolution.width / gdc + ':' + resolution.height / gdc;
      }

      function pixelFormatDescription(pixelFormat) {
        switch (pixelFormat) {
        case 13:
          return 'YUV420P';
        case 14:
          return 'YUV422P';
        case 17:
          return 'YUYV';
        case 29:
          return 'JPEG';
        }
        return '' + pixelFormat;
      }

      Repeater {
        model: camera.cameraDevice.videoFormats

        delegate: MenuItem {
          property int pixelFormat: modelData.pixelFormat
          property size resolution: modelData.resolution

          text: {
            let details = [];
            let ratio = resolutionSelectionMenu.ratioFromResolution(resolution);
            if (ratio !== '') {
              details.push(ratio);
            }
            let description = resolutionSelectionMenu.pixelFormatDescription(pixelFormat);
            if (description !== '') {
              details.push(description);
            }
            return resolution.width + ' × ' + resolution.height + (details.length > 0 ? ' — ' + details.join(' / ') : '');
          }
          height: 48
          leftPadding: Theme.menuItemCheckLeftPadding
          font: Theme.defaultFont
          enabled: !checked
          checkable: true
          checked: cameraSettings.resolution == resolution && cameraSettings.pixelFormat == pixelFormat
          indicator.height: 20
          indicator.width: 20
          indicator.implicitHeight: 24
          indicator.implicitWidth: 24

          onCheckedChanged: {
            if (checked && (cameraSettings.resolution != resolution || cameraSettings.pixelFormat != pixelFormat)) {
              cameraSettings.resolution = resolution;
              cameraSettings.pixelFormat = pixelFormat;
              camera.applyCameraFormat(true);
            }
          }
        }
      }
    }
  }

  Rectangle {
    id: stampBackground
    visible: stampCheckBox.checked
    color: "#80000000"
    height: dateStamp.height + 10 // Increased height to fully show the date
    width: parent.width
    anchors.bottom: parent.bottom
  }

  // Improved rectangular accuracy indicator for camera
  Rectangle {
    id: cameraAccuracyIndicator
    visible: positioningSettings.accuracyIndicator && positionSource.active
    width: 24
    height: 12
    radius: 3
    color: {
      if (positionSource.accuracy === 'bad')
        return Theme.accuracyBad
      else if (positionSource.accuracy === 'good')
        return Theme.accuracyExcellent
      else
        return Theme.accuracyTolerated
    }
    border.color: Theme.light
    border.width: 1
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 10
    anchors.topMargin: 10
    z: 1000
    
    // Add a small GPS icon to make it clear what this indicator represents
    Text {
      anchors.centerIn: parent
      text: "GPS"
      color: "white"
      font.pixelSize: 8
      font.bold: true
    }
  }

  // Photo Annotation Components
  Item {
    id: annotationContainer
    anchors.fill: parent
    visible: cameraItem.state == "PhotoAnnotation"
    
    // Define annotation modes
    property string currentTool: "freehand" // Options: "freehand", "arrow", "rectangle", "circle", "text"
    property string arrowStyle: "standard" // Options: "standard", "filled", "double"
    
    // Text input
    property bool textInputActive: false
    property bool colorPickerVisible: false
    property bool brushSettingsVisible: false
    
    // Canvas for drawing
    Canvas {
      id: annotationCanvas
      anchors.fill: parent
      
      property point lastPoint
      property point startPoint // For shape drawing
      property bool drawing: false
      property var temporaryPaths: [] // Store temporary shape paths for preview
      property var permanentPaths: [] // Store permanent paths
      
      onPaint: {
        var ctx = getContext("2d");
        ctx.lineWidth = cameraSettings.brushSize;
        ctx.strokeStyle = cameraSettings.brushColor;
        ctx.fillStyle = cameraSettings.brushColor;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        
        // Draw any permanent paths first
        for (var i = 0; i < permanentPaths.length; i++) {
          drawPath(ctx, permanentPaths[i]);
        }
        
        // Draw any temporary paths (for shapes in progress)
        for (var j = 0; j < temporaryPaths.length; j++) {
          drawPath(ctx, temporaryPaths[j]);
        }
      }
      
      function drawPath(ctx, path) {
        if (!path) return;
        
        // Handle different path types
        if (path.type === "freehand") {
          if (path.points.length < 2) return;
          
          ctx.beginPath();
          ctx.moveTo(path.points[0].x, path.points[0].y);
          
          for (var i = 1; i < path.points.length; i++) {
            ctx.lineTo(path.points[i].x, path.points[i].y);
          }
          
          ctx.stroke();
        } 
        else if (path.type === "arrow") {
          if (!path.start || !path.end) return;
          
          // Draw the arrow line
          ctx.beginPath();
          ctx.moveTo(path.start.x, path.start.y);
          ctx.lineTo(path.end.x, path.end.y);
          ctx.stroke();
          
          // Calculate arrowhead
          var angle = Math.atan2(path.end.y - path.start.y, path.end.x - path.start.x);
          var headLength = Math.max(10, ctx.lineWidth * 3); // Scale arrow head with line width
          
          // Draw arrowhead based on style
          if (path.style === "filled") {
            // Filled arrowhead
            ctx.beginPath();
            ctx.moveTo(path.end.x, path.end.y);
            ctx.lineTo(
              path.end.x - headLength * Math.cos(angle - Math.PI/6),
              path.end.y - headLength * Math.sin(angle - Math.PI/6)
            );
            ctx.lineTo(
              path.end.x - headLength * Math.cos(angle + Math.PI/6),
              path.end.y - headLength * Math.sin(angle + Math.PI/6)
            );
            ctx.closePath();
            ctx.fill();
          } 
          else if (path.style === "double") {
            // Double arrow (both ends)
            // First end
            ctx.beginPath();
            ctx.moveTo(path.end.x, path.end.y);
            ctx.lineTo(
              path.end.x - headLength * Math.cos(angle - Math.PI/6),
              path.end.y - headLength * Math.sin(angle - Math.PI/6)
            );
            ctx.moveTo(path.end.x, path.end.y);
            ctx.lineTo(
              path.end.x - headLength * Math.cos(angle + Math.PI/6),
              path.end.y - headLength * Math.sin(angle + Math.PI/6)
            );
            
            // Second end (opposite direction)
            var oppositeAngle = angle + Math.PI;
            ctx.moveTo(path.start.x, path.start.y);
            ctx.lineTo(
              path.start.x - headLength * Math.cos(oppositeAngle - Math.PI/6),
              path.start.y - headLength * Math.sin(oppositeAngle - Math.PI/6)
            );
            ctx.moveTo(path.start.x, path.start.y);
            ctx.lineTo(
              path.start.x - headLength * Math.cos(oppositeAngle + Math.PI/6),
              path.start.y - headLength * Math.sin(oppositeAngle + Math.PI/6)
            );
            
            ctx.stroke();
          } 
          else { // standard
            // Standard arrow
            ctx.beginPath();
            ctx.moveTo(path.end.x, path.end.y);
            ctx.lineTo(
              path.end.x - headLength * Math.cos(angle - Math.PI/6),
              path.end.y - headLength * Math.sin(angle - Math.PI/6)
            );
            ctx.moveTo(path.end.x, path.end.y);
            ctx.lineTo(
              path.end.x - headLength * Math.cos(angle + Math.PI/6),
              path.end.y - headLength * Math.sin(angle + Math.PI/6)
            );
            ctx.stroke();
          }
        }
        else if (path.type === "rectangle") {
          if (!path.start || !path.end) return;
          
          var x = Math.min(path.start.x, path.end.x);
          var y = Math.min(path.start.y, path.end.y);
          var width = Math.abs(path.end.x - path.start.x);
          var height = Math.abs(path.end.y - path.start.y);
          
          ctx.beginPath();
          ctx.rect(x, y, width, height);
          ctx.stroke();
        }
        else if (path.type === "circle") {
          if (!path.start || !path.end) return;
          
          var centerX = (path.start.x + path.end.x) / 2;
          var centerY = (path.start.y + path.end.y) / 2;
          var radiusX = Math.abs(path.end.x - path.start.x) / 2;
          var radiusY = Math.abs(path.end.y - path.start.y) / 2;
          
          ctx.beginPath();
          ctx.ellipse(centerX, centerY, radiusX, radiusY, 0, 0, 2 * Math.PI);
          ctx.stroke();
        }
        else if (path.type === "text") {
          // Render text
          ctx.font = path.fontSize + "px sans-serif";
          ctx.fillStyle = path.color;
          
          // Set text alignment to center
          ctx.textAlign = "center";
          ctx.textBaseline = "middle";
          
          // If text is selected, draw a highlight background
          if (path.selected) {
            let textWidth = path.text.length * path.fontSize * 0.6;
            let textHeight = path.fontSize * 1.2;
            
            ctx.fillStyle = "rgba(100, 100, 255, 0.3)";
            ctx.fillRect(
              path.position.x - textWidth/2 - 5,
              path.position.y - textHeight/2 - 5,
              textWidth + 10,
              textHeight + 10
            );
            
            // Reset fill style for text
            ctx.fillStyle = path.color;
          }
          
          // Apply text
          ctx.fillText(path.text, path.position.x, path.position.y);
          
          // Draw a draggable handle or indicator
          if (path.showHandle) {
            // Draw a small circle to indicate the text can be moved
            ctx.beginPath();
            ctx.fillStyle = "rgba(255, 255, 255, 0.8)";
            ctx.arc(path.position.x, path.position.y + path.fontSize/2 + 10, 6, 0, 2 * Math.PI);
            ctx.fill();
            ctx.strokeStyle = "rgba(0, 0, 0, 0.8)";
            ctx.lineWidth = 1.5;
            ctx.stroke();
            
            // Draw move icon inside the handle
            ctx.beginPath();
            ctx.strokeStyle = "rgba(0, 0, 0, 0.8)";
            ctx.lineWidth = 1;
            // Draw four small lines like a move icon
            ctx.moveTo(path.position.x - 3, path.position.y + path.fontSize/2 + 10);
            ctx.lineTo(path.position.x + 3, path.position.y + path.fontSize/2 + 10);
            ctx.moveTo(path.position.x, path.position.y + path.fontSize/2 + 7);
            ctx.lineTo(path.position.x, path.position.y + path.fontSize/2 + 13);
            ctx.stroke();
          }
        }
      }
      
      MouseArea {
        anchors.fill: parent
        
        property var selectedTextPath: null
        property bool isDraggingText: false
        property point dragStartPoint
        
        onPressed: {
          if (annotationContainer.textInputActive || annotationContainer.colorPickerVisible || annotationContainer.brushSettingsVisible) {
            return;
          }
          
          // Store tap position for potential text placement
          annotationCanvas.startPoint = Qt.point(mouseX, mouseY);
          
          // Check if user is clicking on existing text to move it
          let clickPoint = Qt.point(mouseX, mouseY);
          let foundText = false;
          
          // Check in reverse order (top-most first)
          for (let i = annotationCanvas.permanentPaths.length - 1; i >= 0; i--) {
            let path = annotationCanvas.permanentPaths[i];
            if (path.type === "text") {
              // Create a rectangular hit area around the text
              let textWidth = path.text.length * path.fontSize * 0.6; // Approximate width
              let textHeight = path.fontSize * 1.2; // Approximate height
              
              let left = path.position.x - textWidth/2;
              let right = path.position.x + textWidth/2;
              let top = path.position.y - textHeight/2;
              let bottom = path.position.y + textHeight/2;
              
              if (clickPoint.x >= left && clickPoint.x <= right && 
                  clickPoint.y >= top && clickPoint.y <= bottom) {
                // Found a text path to move
                selectedTextPath = path;
                isDraggingText = true;
                dragStartPoint = clickPoint;
                foundText = true;
                
                // Set all text handles to not show except the selected one
                for (let j = 0; j < annotationCanvas.permanentPaths.length; j++) {
                  if (annotationCanvas.permanentPaths[j].type === "text") {
                    annotationCanvas.permanentPaths[j].showHandle = (j === i);
                    annotationCanvas.permanentPaths[j].selected = (j === i);
                  }
                }
                
                // Update instruction text to indicate text can be moved
                instructionText.text = qsTr("Drag the text to reposition it. Tap elsewhere to deselect.");
                
                annotationCanvas.requestPaint();
                break;
              }
            }
          }
          
          // If not clicking on text, deselect any selected text
          if (!foundText) {
            let hadSelectedText = false;
            
            for (let i = 0; i < annotationCanvas.permanentPaths.length; i++) {
              if (annotationCanvas.permanentPaths[i].type === "text" && 
                 (annotationCanvas.permanentPaths[i].selected || annotationCanvas.permanentPaths[i].showHandle)) {
                annotationCanvas.permanentPaths[i].selected = false;
                annotationCanvas.permanentPaths[i].showHandle = false;
                hadSelectedText = true;
              }
            }
            
            if (hadSelectedText) {
              // Reset instruction text
              instructionText.text = qsTr("Tap a tool to begin annotating. Text can be dragged after adding.");
              annotationCanvas.requestPaint();
            }
            
            if (annotationContainer.currentTool === "text") {
              // For text tool, activate text input dialog
              annotationContainer.textInputActive = true;
              // Store the tap position for later text placement
              annotationTextField.textPosition = annotationCanvas.startPoint;
              return;
            }
            
            annotationCanvas.lastPoint = Qt.point(mouseX, mouseY);
            
            if (annotationContainer.currentTool === "freehand") {
              // Start a new freehand drawing path
              var newPath = {
                type: "freehand",
                points: [Qt.point(mouseX, mouseY)],
                color: cameraSettings.brushColor,
                width: cameraSettings.brushSize
              };
              
              annotationCanvas.temporaryPaths.push(newPath);
            } else {
              // Start shape drawing (rectangle, circle, arrow)
              var newShape = {
                type: annotationContainer.currentTool,
                start: Qt.point(mouseX, mouseY),
                end: Qt.point(mouseX, mouseY),
                color: cameraSettings.brushColor,
                width: cameraSettings.brushSize
              };
              
              // For arrows, include the style
              if (annotationContainer.currentTool === "arrow") {
                newShape.style = annotationContainer.arrowStyle;
              }
              
              annotationCanvas.temporaryPaths.push(newShape);
            }
            
            annotationCanvas.drawing = true;
            annotationCanvas.requestPaint();
          }
        }
        
        onPositionChanged: {
          // If dragging text, update its position
          if (isDraggingText && selectedTextPath) {
            selectedTextPath.position = Qt.point(mouseX, mouseY);
            annotationCanvas.requestPaint();
            return;
          }
          
          if (!annotationCanvas.drawing) return;
          
          if (annotationContainer.currentTool === "freehand") {
            // For freehand drawing, add points to the current path
            var currentPath = annotationCanvas.temporaryPaths[annotationCanvas.temporaryPaths.length - 1];
            currentPath.points.push(Qt.point(mouseX, mouseY));
          } else {
            // For shapes, update the end point
            var currentShape = annotationCanvas.temporaryPaths[annotationCanvas.temporaryPaths.length - 1];
            currentShape.end = Qt.point(mouseX, mouseY);
          }
          
          annotationCanvas.requestPaint();
          annotationCanvas.lastPoint = Qt.point(mouseX, mouseY);
        }
        
        onReleased: {
          // End text dragging if active
          if (isDraggingText) {
            isDraggingText = false;
            return;
          }
          
          if (!annotationCanvas.drawing) return;
          
          // Finalize the drawing by moving from temporary to permanent paths
          if (annotationCanvas.temporaryPaths.length > 0) {
            var finishedPath = annotationCanvas.temporaryPaths.pop();
            
            // Only add if it's not just a click (check for minimal movement)
            if (annotationContainer.currentTool === "freehand") {
              if (finishedPath.points.length > 1) {
                annotationCanvas.permanentPaths.push(finishedPath);
              }
            } else {
              // For shapes, check if start and end are different enough
              var dx = finishedPath.end.x - finishedPath.start.x;
              var dy = finishedPath.end.y - finishedPath.start.y;
              var distance = Math.sqrt(dx * dx + dy * dy);
              
              if (distance > 5) { // Minimum distance threshold
                annotationCanvas.permanentPaths.push(finishedPath);
              }
            }
          }
          
          annotationCanvas.drawing = false;
          annotationCanvas.requestPaint();
        }
      }
    }
    
    // Annotation toolbar
    Rectangle {
      id: annotationToolbar
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 10
      height: 60
      color: "#303030"
      radius: 8
      
      property bool drawingMode: annotationContainer.currentTool !== "text"
      
      Row {
        anchors.centerIn: parent
        spacing: 10
        
        // Brush size/settings button
        Rectangle {
          id: brushSettingsButton
          width: 44
          height: 44
          radius: 4
          color: "#555555"
          
          Image {
            anchors.centerIn: parent
            width: 28
            height: 28
            source: Theme.getThemeVectorIcon("ic_settings_black_24dp")
            sourceSize.width: 28
            sourceSize.height: 28
            fillMode: Image.PreserveAspectFit
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.brushSettingsVisible = !annotationContainer.brushSettingsVisible;
              annotationContainer.colorPickerVisible = false;
              arrowStyleSelector.visible = false;
              
              // Update instruction text
              instructionText.text = qsTr("Adjust brush size and color");
            }
          }
        }
        
        // Freehand drawing tool
        Rectangle {
          id: freehandToolButton
          width: 44
          height: 44
          radius: 4
          color: annotationContainer.currentTool === "freehand" ? Theme.mainColor : "#555555"
          
          Image {
            anchors.centerIn: parent
            width: 28
            height: 28
            source: Theme.getThemeVectorIcon("ic_edit_black_24dp")
            sourceSize.width: 28
            sourceSize.height: 28
            fillMode: Image.PreserveAspectFit
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "freehand";
              arrowStyleSelector.visible = false;
              annotationContainer.brushSettingsVisible = false;
              instructionText.text = qsTr("Draw freehand on the image");
            }
          }
        }
        
        // Arrow tool button
        Rectangle {
          id: arrowToolButton
          width: 44
          height: 44
          radius: 4
          color: annotationContainer.currentTool === "arrow" ? Theme.mainColor : "#555555"
          
          Canvas {
            anchors.centerIn: parent
            width: 36
            height: 36
            
            onPaint: {
              var ctx = getContext("2d");
              ctx.lineWidth = 2;
              ctx.strokeStyle = "white";
              
              // Draw arrow shaft
              ctx.beginPath();
              ctx.moveTo(5, 18);
              ctx.lineTo(25, 18);
              ctx.stroke();
              
              // Draw arrowhead
              ctx.beginPath();
              ctx.moveTo(25, 18);
              ctx.lineTo(20, 13);
              ctx.moveTo(25, 18);
              ctx.lineTo(20, 23);
              ctx.stroke();
            }
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "arrow";
              
              // Toggle arrow style selector visibility
              arrowStyleSelector.visible = !arrowStyleSelector.visible;
              annotationContainer.brushSettingsVisible = false;
              
              instructionText.text = qsTr("Tap and drag to draw an arrow. Tap the arrow button again to change arrow style.");
            }
          }
        }

        // Text tool button
        Rectangle {
          id: textToolButton
          width: 44
          height: 44
          radius: 4
          color: annotationContainer.currentTool === "text" ? Theme.mainColor : "#555555"
          
          Text {
            anchors.centerIn: parent
            text: "T"
            color: "white"
            font.bold: true
            font.pixelSize: 24
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "text";
              arrowStyleSelector.visible = false;
              annotationContainer.brushSettingsVisible = false;
              annotationContainer.textInputActive = true;
              instructionText.text = qsTr("Add text to the image");
            }
          }
        }
        
        // Shape tool button
        Rectangle {
          id: shapeToolButton
          width: 44
          height: 44
          radius: 4
          color: (annotationContainer.currentTool === "rectangle" || annotationContainer.currentTool === "circle") ? Theme.mainColor : "#555555"
          
          Canvas {
            anchors.centerIn: parent
            width: 36
            height: 36
            
            onPaint: {
              var ctx = getContext("2d");
              ctx.lineWidth = 2;
              ctx.strokeStyle = "white";
              
              // Draw rectangle
              ctx.beginPath();
              ctx.rect(8, 8, 20, 20);
              ctx.stroke();
            }
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              // Toggle between rectangle and circle
              if (annotationContainer.currentTool !== "rectangle" && annotationContainer.currentTool !== "circle") {
                annotationContainer.currentTool = "rectangle";
                instructionText.text = qsTr("Tap and drag to draw a rectangle");
              } else if (annotationContainer.currentTool === "rectangle") {
                annotationContainer.currentTool = "circle";
                instructionText.text = qsTr("Tap and drag to draw a circle");
              } else {
                annotationContainer.currentTool = "rectangle";
                instructionText.text = qsTr("Tap and drag to draw a rectangle");
              }
              
              arrowStyleSelector.visible = false;
              annotationContainer.brushSettingsVisible = false;
            }
          }
        }

        // Accept button
        Rectangle {
          id: acceptButton
          width: 44
          height: 44
          radius: 4
          color: "#008800"
          
          Image {
            anchors.centerIn: parent
            width: 28
            height: 28
            source: Theme.getThemeVectorIcon("ic_check_black_24dp")
            sourceSize.width: 28
            sourceSize.height: 28
            fillMode: Image.PreserveAspectFit
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              // Save the annotated image
              cameraItem.saveAnnotatedImage();
            }
          }
        }
        
        // Cancel button
        Rectangle {
          id: cancelButton
          width: 44
          height: 44
          radius: 4
          color: "#AA0000"
          
          Image {
            anchors.centerIn: parent
            width: 28
            height: 28
            source: Theme.getThemeVectorIcon("ic_close_black_24dp")
            sourceSize.width: 28
            sourceSize.height: 28
            fillMode: Image.PreserveAspectFit
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              // Cancel annotation mode
              cameraItem.state = "PhotoCapture";
              annotationCanvas.temporaryPaths = [];
              annotationCanvas.permanentPaths = [];
              annotationCanvas.requestPaint();
            }
          }
        }
      }
    }
    
    // Arrow style selector
    Rectangle {
      id: arrowStyleSelector
      visible: false
      anchors {
        bottom: annotationToolbar.top
        horizontalCenter: parent.horizontalCenter
        bottomMargin: 10
      }
      width: arrowStyleRow.width + 20
      height: arrowStyleRow.height + 20
      color: "#303030"
      radius: 8
      border.color: "#909090"
      border.width: 1
      
      Row {
        id: arrowStyleRow
        anchors.centerIn: parent
        spacing: 20
        
        // Standard arrow style
        Rectangle {
          width: 60
          height: 40
          radius: 4
          color: annotationContainer.arrowStyle === "standard" ? "#555555" : "#404040"
          
          Canvas {
            anchors.centerIn: parent
            width: 50
            height: 30
            
            onPaint: {
              var ctx = getContext("2d");
              ctx.lineWidth = 2;
              ctx.strokeStyle = "white";
              
              // Draw arrow shaft
              ctx.beginPath();
              ctx.moveTo(5, 15);
              ctx.lineTo(35, 15);
              ctx.stroke();
              
              // Draw arrowhead
              ctx.beginPath();
              ctx.moveTo(35, 15);
              ctx.lineTo(30, 10);
              ctx.moveTo(35, 15);
              ctx.lineTo(30, 20);
              ctx.stroke();
            }
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.arrowStyle = "standard";
              arrowStyleSelector.visible = false;
            }
          }
        }
        
        // Filled arrow style
        Rectangle {
          width: 60
          height: 40
          radius: 4
          color: annotationContainer.arrowStyle === "filled" ? "#555555" : "#404040"
          
          Canvas {
            anchors.centerIn: parent
            width: 50
            height: 30
            
            onPaint: {
              var ctx = getContext("2d");
              ctx.lineWidth = 2;
              ctx.strokeStyle = "white";
              ctx.fillStyle = "white";
              
              // Draw arrow shaft
              ctx.beginPath();
              ctx.moveTo(5, 15);
              ctx.lineTo(35, 15);
              ctx.stroke();
              
              // Draw filled arrowhead
              ctx.beginPath();
              ctx.moveTo(35, 15);
              ctx.lineTo(30, 10);
              ctx.lineTo(30, 20);
              ctx.closePath();
              ctx.fill();
            }
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.arrowStyle = "filled";
              arrowStyleSelector.visible = false;
            }
          }
        }
        
        // Double arrow style
        Rectangle {
          width: 60
          height: 40
          radius: 4
          color: annotationContainer.arrowStyle === "double" ? "#555555" : "#404040"
          
          Canvas {
            anchors.centerIn: parent
            width: 50
            height: 30
            
            onPaint: {
              var ctx = getContext("2d");
              ctx.lineWidth = 2;
              ctx.strokeStyle = "white";
              
              // Draw arrow shaft
              ctx.beginPath();
              ctx.moveTo(5, 15);
              ctx.lineTo(45, 15);
              ctx.stroke();
              
              // Draw left arrowhead
              ctx.beginPath();
              ctx.moveTo(5, 15);
              ctx.lineTo(10, 10);
              ctx.moveTo(5, 15);
              ctx.lineTo(10, 20);
              
              // Draw right arrowhead
              ctx.moveTo(45, 15);
              ctx.lineTo(40, 10);
              ctx.moveTo(45, 15);
              ctx.lineTo(40, 20);
              ctx.stroke();
            }
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.arrowStyle = "double";
              arrowStyleSelector.visible = false;
            }
          }
        }
      }
    }

    // Instructions text
    Rectangle {
      id: instructionRect
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: 10
      }
      height: instructionText.contentHeight + 16
      color: "#80000000"
      radius: 4
      visible: true
      
      Text {
        id: instructionText
        anchors {
          verticalCenter: parent.verticalCenter
          left: parent.left
          right: parent.right
          margins: 8
        }
        color: "white"
        font.pixelSize: 14
        wrapMode: Text.WordWrap
        text: qsTr("Tap a tool to begin annotating. Text can be dragged after adding.")
      }
    }
  }

  // Brush size and color settings panel
  Rectangle {
    id: brushSettingsPanel
    visible: annotationContainer.brushSettingsVisible
    anchors {
      bottom: annotationToolbar.top
      horizontalCenter: parent.horizontalCenter
      bottomMargin: 10
    }
    width: Math.min(parent.width * 0.9, 400)
    height: brushSettingsColumn.height + 20
    color: "#303030"
    radius: 8
    border.color: "#909090"
    border.width: 1
    
    Column {
      id: brushSettingsColumn
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: 10
      }
      spacing: 10
      
      Text {
        text: annotationContainer.currentTool === "text" ? qsTr("Text Settings") : qsTr("Brush Settings")
        color: "white"
        font.bold: true
        font.pixelSize: 16
        anchors.horizontalCenter: parent.horizontalCenter
      }
      
      // Size slider
      Column {
        width: parent.width
        spacing: 5
        
        Text {
          text: annotationContainer.currentTool === "text" ? 
                qsTr("Text Size: %1").arg(annotationContainer.currentTool === "text" ? cameraSettings.textSize : cameraSettings.brushSize) : 
                qsTr("Brush Size: %1").arg(cameraSettings.brushSize)
          color: "white"
          font.pixelSize: 14
        }
        
        Slider {
          id: sizeSlider
          width: parent.width
          from: annotationContainer.currentTool === "text" ? 12 : 1
          to: annotationContainer.currentTool === "text" ? 72 : 50
          stepSize: 1
          value: annotationContainer.currentTool === "text" ? cameraSettings.textSize : cameraSettings.brushSize
          
          onValueChanged: {
            if (annotationContainer.currentTool === "text") {
              cameraSettings.textSize = value;
            } else {
              cameraSettings.brushSize = value;
            }
            annotationCanvas.requestPaint();
          }
        }
      }
      
      // Color selection
      Row {
        width: parent.width
        spacing: 10
        
        Text {
          text: qsTr("Color:")
          color: "white"
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }
        
        // Color swatches row
        Row {
          spacing: 8
          anchors.verticalCenter: parent.verticalCenter
          
          Repeater {
            model: ["#FF0000", "#FFA500", "#FFFF00", "#00FF00", "#0000FF", "#800080", "#FFFFFF", "#000000"]
            
            Rectangle {
              width: 30
              height: 30
              radius: 15
              color: modelData
              border.color: (annotationContainer.currentTool === "text" && cameraSettings.textColor === modelData) || 
                           (annotationContainer.currentTool !== "text" && cameraSettings.brushColor === modelData) ? 
                           "#FFFFFF" : "#404040"
              border.width: (annotationContainer.currentTool === "text" && cameraSettings.textColor === modelData) || 
                           (annotationContainer.currentTool !== "text" && cameraSettings.brushColor === modelData) ? 
                           3 : 1
              
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  if (annotationContainer.currentTool === "text") {
                    cameraSettings.textColor = modelData;
                  } else {
                    cameraSettings.brushColor = modelData;
                  }
                  annotationCanvas.requestPaint();
                }
              }
            }
          }
        }
      }
      
      // Close button
      Button {
        text: qsTr("Close")
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: annotationContainer.brushSettingsVisible = false
      }
    }
  }

  // Text entry dialog for annotations
  Rectangle {
    id: textEntryDialog
    visible: annotationContainer.textInputActive
    anchors.centerIn: parent
    width: Math.min(parent.width * 0.9, 400)
    height: textEntryColumn.height + 20
    color: "#303030"
    radius: 8
    border.color: "#909090"
    border.width: 1
    
    Column {
      id: textEntryColumn
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: 10
      }
      spacing: 10
      
      Text {
        text: qsTr("Enter Text")
        color: "white"
        font.bold: true
        font.pixelSize: 16
        anchors.horizontalCenter: parent.horizontalCenter
      }
      
      TextField {
        id: annotationTextField
        width: parent.width
        placeholderText: qsTr("Type your text here")
        color: "white"
        font.pixelSize: 16
        
        property point textPosition: Qt.point(0, 0)
        
        background: Rectangle {
          color: "#404040"
          border.color: "#909090"
          border.width: 1
          radius: 4
        }
        
        // Ensure keyboard shows up on Android
        Component.onCompleted: {
          forceActiveFocus()
          if (Qt.platform.os === "android") {
            Qt.inputMethod.show()
          }
        }
        
        onAccepted: {
          acceptTextButton.clicked()
        }
      }
      
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20
        
        Button {
          text: qsTr("Cancel")
          onClicked: {
            annotationContainer.textInputActive = false
            annotationTextField.text = ""
          }
        }
        
        Button {
          id: acceptTextButton
          text: qsTr("Add Text")
          onClicked: {
            if (annotationTextField.text.trim() !== "") {
              // Create a new text annotation at the tapped position rather than screen center
              var newText = {
                type: "text",
                text: annotationTextField.text,
                position: annotationTextField.textPosition,
                color: cameraSettings.textColor,
                fontSize: cameraSettings.textSize,
                showHandle: true, // Add a handle to indicate it can be moved
                selected: true // Initially select it so user can see it's movable
              };
              
              // Add to permanent paths for rendering
              annotationCanvas.permanentPaths.push(newText);
              
              // Update instruction to let user know they can move the text
              instructionText.text = qsTr("Drag the text to reposition it. Tap elsewhere to deselect.");
              
              annotationCanvas.requestPaint();
              
              // Close the dialog
              annotationContainer.textInputActive = false;
              annotationTextField.text = "";
            }
          }
        }
      }
    }
  }
}
