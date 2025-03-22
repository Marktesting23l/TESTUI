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
    
    // Drawing-related properties
    property int brushSize: 5 // Brush size for drawing
    property int textSize: 24 // Text size for text annotations
    property string brushColor: "#FF0000" // Red color for brush
    property string textColor: "#FFFFFF" // White color for text
    
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
        " || '\n" + qsTr("Folder") + ": ' || '" + (cameraSettings ? cameraSettings.folderName : "DCIM") + "'" +
        (cameraSettings && cameraSettings.photoPrefix ? " || '\n" + qsTr("Series") + ": ' || '" + cameraSettings.photoPrefix + "'" : "") +
        " || '\nSIGPACGO - Agricultural Field Survey'"

    project: qgisProject ? qgisProject : null
    positionInformation: currentPosition ? currentPosition : null
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
                source: {
                  let icon = Theme.getThemeVectorIcon("ic_access_time_white_24dp")
                  return icon || "qrc:/images/themes/default/mActionClock.svg"
                }
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
                source: {
                  let icon = Theme.getThemeVectorIcon("ic_my_location_white_24dp")
                  return icon || "qrc:/images/themes/default/mActionGPS.svg"
                }
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
                source: {
                  let icon = Theme.getThemeVectorIcon("ic_wb_sunny_white_24dp")
                  return icon || "qrc:/images/themes/default/mActionSun.svg"
                }
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
                    if (level > 75) {
                      let icon = Theme.getThemeVectorIcon("ic_battery_full_white_24dp")
                      return icon || "qrc:/images/themes/default/mActionBattery.svg"
                    }
                    if (level > 50) {
                      let icon = Theme.getThemeVectorIcon("ic_battery_3_bar_white_24dp")
                      return icon || "qrc:/images/themes/default/mActionBattery.svg"
                    }
                    if (level > 25) {
                      let icon = Theme.getThemeVectorIcon("ic_battery_2_bar_white_24dp")
                      return icon || "qrc:/images/themes/default/mActionBattery.svg"
                    }
                    let icon = Theme.getThemeVectorIcon("ic_battery_1_bar_white_24dp")
                    return icon || "qrc:/images/themes/default/mActionBattery.svg"
                  } catch (e) {
                    let icon = Theme.getThemeVectorIcon("ic_battery_unknown_white_24dp")
                    return icon || "qrc:/images/themes/default/mActionUnknown.svg"
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
                      // Use only two parameters as per the updated FileUtils.addImageStamp function
                      FileUtils.addImageStamp(currentPath, stampText);
                    }
                  }
                  cameraItem.finished(currentPath);
                } else if (cameraItem.state == "PhotoAnnotation") {
                  // Add handling for annotation mode to move to preview mode after annotating
                  annotationContainer.mergeAnnotationsWithImage();
                  cameraItem.state = "PhotoPreview";
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
    visible: cameraSettings.stamping  // Changed from stampCheckBox.checked to use the cameraSettings property
    color: "#80000000"
    height: 50  // Fixed height instead of relying on dateStamp.height
    width: parent.width
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 15 // Add some margin to the bottom to move it lower
    
    // Add the dateStamp Text element
    Text {
      id: dateStamp
      anchors.centerIn: parent
      color: cameraSettings.stampTextColor
      font.pixelSize: cameraSettings.stampFontSize
      text: stampExpressionEvaluator.evaluate()
      wrapMode: Text.WordWrap
      width: parent.width - 20
      horizontalAlignment: Text.AlignLeft
      leftPadding: 10
    }
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
    
    // Canvas for drawing
    Canvas {
      id: annotationCanvas
      anchors.fill: parent
      
      property point lastPoint
      property point startPoint // For shape drawing
      property bool drawing: false
      property var temporaryPaths: [] // Store temporary shape paths for preview
      
      onPaint: {
        var ctx = getContext("2d");
        ctx.lineWidth = cameraSettings.brushSize;
        ctx.strokeStyle = cameraSettings.brushColor;
        ctx.fillStyle = cameraSettings.brushColor;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        
        // Draw any temporary paths (for shapes in progress)
        for (var i = 0; i < temporaryPaths.length; i++) {
          var path = temporaryPaths[i];
          drawPath(ctx, path);
        }
      }
      
      function clear() {
        var ctx = getContext("2d");
        ctx.reset();
        temporaryPaths = [];
        requestPaint();
      }
      
      function drawPath(ctx, path) {
        if (!path || !path.type) return;
        
        ctx.save();
        ctx.beginPath();
        
        if (path.type === "freehand") {
          ctx.moveTo(path.points[0].x, path.points[0].y);
          for (var i = 1; i < path.points.length; i++) {
            ctx.lineTo(path.points[i].x, path.points[i].y);
          }
          ctx.stroke();
        } 
        else if (path.type === "arrow") {
          // Draw arrow line
          ctx.moveTo(path.start.x, path.start.y);
          ctx.lineTo(path.end.x, path.end.y);
          ctx.stroke();
          
          // Calculate arrowhead
          var angle = Math.atan2(path.end.y - path.start.y, path.end.x - path.start.x);
          var arrowHeadLength = Math.min(20, Math.max(12, ctx.lineWidth * 2.5)); // Scale with line width
          
          // Draw arrowhead based on style
          if (annotationContainer.arrowStyle === "standard" || annotationContainer.arrowStyle === "filled") {
            ctx.beginPath();
            ctx.moveTo(path.end.x, path.end.y);
            ctx.lineTo(
              path.end.x - arrowHeadLength * Math.cos(angle - Math.PI/6),
              path.end.y - arrowHeadLength * Math.sin(angle - Math.PI/6)
            );
            ctx.lineTo(
              path.end.x - arrowHeadLength * Math.cos(angle + Math.PI/6),
              path.end.y - arrowHeadLength * Math.sin(angle + Math.PI/6)
            );
            
            if (annotationContainer.arrowStyle === "filled") {
              ctx.closePath();
              ctx.fill();
            } else {
              ctx.closePath();
              ctx.stroke();
            }
          } 
          else if (annotationContainer.arrowStyle === "double") {
            // First arrowhead at end
            ctx.beginPath();
            ctx.moveTo(path.end.x, path.end.y);
            ctx.lineTo(
              path.end.x - arrowHeadLength * Math.cos(angle - Math.PI/6),
              path.end.y - arrowHeadLength * Math.sin(angle - Math.PI/6)
            );
            ctx.lineTo(
              path.end.x - arrowHeadLength * Math.cos(angle + Math.PI/6),
              path.end.y - arrowHeadLength * Math.sin(angle + Math.PI/6)
            );
            ctx.closePath();
            ctx.fill();
            
            // Second arrowhead at start (reversed direction)
            ctx.beginPath();
            ctx.moveTo(path.start.x, path.start.y);
            ctx.lineTo(
              path.start.x + arrowHeadLength * Math.cos(angle - Math.PI/6),
              path.start.y + arrowHeadLength * Math.sin(angle - Math.PI/6)
            );
            ctx.lineTo(
              path.start.x + arrowHeadLength * Math.cos(angle + Math.PI/6),
              path.start.y + arrowHeadLength * Math.sin(angle + Math.PI/6)
            );
            ctx.closePath();
            ctx.fill();
          }
        } 
        else if (path.type === "rectangle") {
          var x = Math.min(path.start.x, path.end.x);
          var y = Math.min(path.start.y, path.end.y);
          var width = Math.abs(path.end.x - path.start.x);
          var height = Math.abs(path.end.y - path.start.y);
          
          ctx.rect(x, y, width, height);
          ctx.stroke();
        } 
        else if (path.type === "circle") {
          var centerX = (path.start.x + path.end.x) / 2;
          var centerY = (path.start.y + path.end.y) / 2;
          var radiusX = Math.abs(path.end.x - path.start.x) / 2;
          var radiusY = Math.abs(path.end.y - path.start.y) / 2;
          
          ctx.ellipse(centerX, centerY, radiusX, radiusY);
          ctx.stroke();
        }
        else if (path.type === "text") {
          // Center-align text
          ctx.textAlign = "center";
          ctx.textBaseline = "middle";
          ctx.font = cameraSettings.textSize + "px sans-serif";
          ctx.fillStyle = cameraSettings.textColor;
          
          // Draw the text centered at the specified position
          ctx.fillText(path.text, path.x, path.y);
        }
        
        ctx.restore();
      }
      
      function addTemporaryPath(path) {
        temporaryPaths.push(path);
        requestPaint();
      }
      
      function commitTemporaryPaths() {
        // For permanent drawing, we'll draw directly to the canvas
        var ctx = getContext("2d");
        
        for (var i = 0; i < temporaryPaths.length; i++) {
          drawPath(ctx, temporaryPaths[i]);
        }
        
        temporaryPaths = [];
        requestPaint();
      }
      
      MouseArea {
        id: canvasMouseArea
        anchors.fill: parent
        enabled: !annotationContainer.textInputActive && !annotationContainer.colorPickerVisible
        
        onPressed: {
          annotationCanvas.startPoint = Qt.point(mouseX, mouseY);
          annotationCanvas.lastPoint = Qt.point(mouseX, mouseY);
          annotationCanvas.drawing = true;
          
          if (annotationContainer.currentTool === "freehand") {
            // For freehand, we'll start a new path
            annotationCanvas.addTemporaryPath({
              type: "freehand",
              points: [annotationCanvas.lastPoint]
            });
          }
        }
        
        onPositionChanged: {
          if (!annotationCanvas.drawing) return;
          
          if (annotationContainer.currentTool === "freehand") {
            // Add point to the current freehand path
            var currentPath = annotationCanvas.temporaryPaths[annotationCanvas.temporaryPaths.length - 1];
            currentPath.points.push(Qt.point(mouseX, mouseY));
            annotationCanvas.lastPoint = Qt.point(mouseX, mouseY);
            annotationCanvas.requestPaint();
          } 
          else {
            // For shapes, update the preview
            annotationCanvas.temporaryPaths = []; // Clear any existing previews
            
            var newPath = {
              type: annotationContainer.currentTool,
              start: annotationCanvas.startPoint,
              end: Qt.point(mouseX, mouseY)
            };
            
            annotationCanvas.addTemporaryPath(newPath);
          }
        }
        
        onReleased: {
          if (!annotationCanvas.drawing) return;
          
          if (annotationContainer.currentTool !== "freehand") {
            // For shapes, finalize the shape when released
            var finalPath = {
              type: annotationContainer.currentTool,
              start: annotationCanvas.startPoint,
              end: Qt.point(mouseX, mouseY)
            };
            
            annotationCanvas.temporaryPaths = [finalPath];
          }
          
          // Commit all temporary paths to the canvas
          annotationCanvas.commitTemporaryPaths();
          annotationCanvas.drawing = false;
        }
      }
    }
    
    // Annotation toolbar
    Rectangle {
      id: annotationToolbar
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.topMargin: 60 // Leave space for back button
      anchors.rightMargin: 4
      width: 60
      color: "#80000000"
      
      property bool drawingMode: annotationContainer.currentTool !== "text"
      
      Column {
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        
        // Freehand tool button
        Rectangle {
          width: 50
          height: 50
          radius: 25
          color: annotationContainer.currentTool === "freehand" ? Theme.mainColor : "#555555"
          
          Image {
            anchors.centerIn: parent
            source: Theme.getThemeVectorIcon("ic_create_white_24dp")
            width: 30
            height: 30
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "freehand";
              annotationContainer.textInputActive = false;
              arrowStyleSelector.visible = false;
            }
          }
        }
        
        // Arrow tool button
        Rectangle {
          id: arrowToolButton
          width: 50
          height: 50
          radius: 25
          color: annotationContainer.currentTool === "arrow" ? Theme.mainColor : "#555555"
          
          Canvas {
            anchors.centerIn: parent
            width: 30
            height: 30
            
            onPaint: {
              var ctx = getContext("2d");
              ctx.strokeStyle = "white";
              ctx.fillStyle = "white";
              ctx.lineWidth = 2;
              
              // Draw arrow shaft
              ctx.beginPath();
              ctx.moveTo(5, 15);
              ctx.lineTo(25, 15);
              ctx.stroke();
              
              // Draw arrowhead
              ctx.beginPath();
              ctx.moveTo(25, 15);
              ctx.lineTo(19, 9);
              ctx.lineTo(19, 21);
              ctx.closePath();
              ctx.fill();
            }
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "arrow";
              annotationContainer.textInputActive = false;
              // Toggle arrow style selector visibility
              arrowStyleSelector.visible = !arrowStyleSelector.visible;
              
              // Show instruction
              instructionText.text = "Tap and drag to draw an arrow. Tap the arrow button again to change arrow style.";
              instructionText.visible = true;
              instructionTimer.restart();
            }
          }
        }
        
        // Arrow style selector popup
        Rectangle {
          id: arrowStyleSelector
          visible: false
          width: 180
          height: 50
          radius: 5
          color: "#80000000"
          anchors.right: arrowToolButton.left
          anchors.verticalCenter: arrowToolButton.verticalCenter
          anchors.rightMargin: 10
          
          Row {
            anchors.centerIn: parent
            spacing: 10
            
            // Standard arrow style
            Rectangle {
              width: 50
              height: 40
              radius: 5
              color: annotationContainer.arrowStyle === "standard" ? "#ffffff" : "#40ffffff"
              
              Canvas {
                anchors.centerIn: parent
                width: 30
                height: 20
                onPaint: {
                  var ctx = getContext("2d");
                  ctx.strokeStyle = annotationContainer.arrowStyle === "standard" ? "black" : "white";
                  ctx.lineWidth = 2;
                  
                  // Draw arrow line
                  ctx.beginPath();
                  ctx.moveTo(2, height/2);
                  ctx.lineTo(width-8, height/2);
                  ctx.stroke();
                  
                  // Draw arrowhead outline
                  ctx.beginPath();
                  ctx.moveTo(width-2, height/2);
                  ctx.lineTo(width-8, height/2-4);
                  ctx.lineTo(width-8, height/2+4);
                  ctx.closePath();
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
              width: 50
              height: 40
              radius: 5
              color: annotationContainer.arrowStyle === "filled" ? "#ffffff" : "#40ffffff"
              
              Canvas {
                anchors.centerIn: parent
                width: 30
                height: 20
                onPaint: {
                  var ctx = getContext("2d");
                  ctx.strokeStyle = annotationContainer.arrowStyle === "filled" ? "black" : "white";
                  ctx.fillStyle = annotationContainer.arrowStyle === "filled" ? "black" : "white";
                  ctx.lineWidth = 2;
                  
                  // Draw arrow line
                  ctx.beginPath();
                  ctx.moveTo(2, height/2);
                  ctx.lineTo(width-8, height/2);
                  ctx.stroke();
                  
                  // Draw filled arrowhead
                  ctx.beginPath();
                  ctx.moveTo(width-2, height/2);
                  ctx.lineTo(width-8, height/2-4);
                  ctx.lineTo(width-8, height/2+4);
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
              width: 50
              height: 40
              radius: 5
              color: annotationContainer.arrowStyle === "double" ? "#ffffff" : "#40ffffff"
              
              Canvas {
                anchors.centerIn: parent
                width: 30
                height: 20
                onPaint: {
                  var ctx = getContext("2d");
                  ctx.strokeStyle = annotationContainer.arrowStyle === "double" ? "black" : "white";
                  ctx.fillStyle = annotationContainer.arrowStyle === "double" ? "black" : "white";
                  ctx.lineWidth = 2;
                  
                  // Draw arrow line
                  ctx.beginPath();
                  ctx.moveTo(4, height/2);
                  ctx.lineTo(width-4, height/2);
                  ctx.stroke();
                  
                  // Draw first arrowhead (right)
                  ctx.beginPath();
                  ctx.moveTo(width-2, height/2);
                  ctx.lineTo(width-8, height/2-4);
                  ctx.lineTo(width-8, height/2+4);
                  ctx.closePath();
                  ctx.fill();
                  
                  // Draw second arrowhead (left)
                  ctx.beginPath();
                  ctx.moveTo(2, height/2);
                  ctx.lineTo(8, height/2-4);
                  ctx.lineTo(8, height/2+4);
                  ctx.closePath();
                  ctx.fill();
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
        
        // Rectangle tool button
        Rectangle {
          width: 50
          height: 50
          radius: 25
          color: annotationContainer.currentTool === "rectangle" ? Theme.mainColor : "#555555"
          
          Rectangle {
            anchors.centerIn: parent
            width: 26
            height: 18
            color: "transparent"
            border.color: "white"
            border.width: 2
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "rectangle";
              annotationContainer.textInputActive = false;
              arrowStyleSelector.visible = false;
            }
          }
        }
        
        // Circle tool button
        Rectangle {
          width: 50
          height: 50
          radius: 25
          color: annotationContainer.currentTool === "circle" ? Theme.mainColor : "#555555"
          
          Rectangle {
            anchors.centerIn: parent
            width: 22
            height: 22
            radius: 11
            color: "transparent"
            border.color: "white"
            border.width: 2
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "circle";
              annotationContainer.textInputActive = false;
              arrowStyleSelector.visible = false;
            }
          }
        }
        
        // Text tool button
        Rectangle {
          width: 50
          height: 50
          radius: 25
          color: annotationContainer.currentTool === "text" ? Theme.mainColor : "#555555"
          
          Text {
            anchors.centerIn: parent
            text: "T"
            color: "white"
            font.pixelSize: 30
            font.bold: true
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.currentTool = "text";
              annotationContainer.textInputActive = true;
              arrowStyleSelector.visible = false;
            }
          }
        }
        
        // Color picker button
        Rectangle {
          width: 50
          height: 50
          radius: 25
          color: "#555555"
          
          Rectangle {
            anchors.centerIn: parent
            width: 30
            height: 30
            radius: 15
            color: annotationToolbar.drawingMode ? cameraSettings.brushColor : cameraSettings.textColor
            border.color: "white"
            border.width: 2
          }
          
          MouseArea {
            anchors.fill: parent
            onClicked: {
              annotationContainer.colorPickerVisible = true;
              arrowStyleSelector.visible = false;
            }
          }
        }
      }
    }
    
    // Instruction text for tools
    Rectangle {
      id: instructionText
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 80
      width: parent.width * 0.8
      height: instructionTextLabel.contentHeight + 20
      color: "#80000000"
      radius: 10
      visible: false
      property string text: ""
      
      Text {
        id: instructionTextLabel
        anchors.centerIn: parent
        width: parent.width - 20
        color: "white"
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: instructionText.text
      }
      
      Timer {
        id: instructionTimer
        interval: 4000
        onTriggered: {
          instructionText.visible = false;
        }
      }
    }
  }

  // Text input dialog
  Rectangle {
    id: textInputDialog
    anchors.centerIn: parent
    width: parent.width * 0.8
    height: 150
    color: "#80000000"
    radius: 10
    visible: annotationContainer.textInputActive
    
    Column {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10
      
      Text {
        text: qsTr("Enter Text")
        font.pixelSize: 16
        color: "white"
        anchors.horizontalCenter: parent.horizontalCenter
      }
      
      Rectangle {
        width: parent.width
        height: 40
        color: "#50ffffff"
        radius: 5
        
        TextInput {
          id: textInput
          anchors.fill: parent
          anchors.margins: 5
          color: "white"
          font.pixelSize: cameraSettings.textSize
          horizontalAlignment: TextInput.AlignHCenter
          verticalAlignment: TextInput.AlignVCenter
          focus: true
          
          // Make cursor visible
          cursorVisible: true
          selectByMouse: true
        }
      }
      
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20
        
        Button {
          text: qsTr("Cancel")
          onClicked: {
            annotationContainer.textInputActive = false
            textInput.text = ""
          }
        }
        
        Button {
          text: qsTr("Add")
          onClicked: {
            if (textInput.text.trim() !== "") {
              // Add text at center of screen
              var centerX = annotationCanvas.width / 2
              var centerY = annotationCanvas.height / 2
              
              // Add text as a path
              annotationCanvas.addTemporaryPath({
                type: "text",
                text: textInput.text,
                x: centerX,
                y: centerY
              })
              
              // Commit the path
              annotationCanvas.commitTemporaryPaths()
              
              // Reset
              annotationContainer.textInputActive = false
              textInput.text = ""
            }
          }
        }
      }
    }
  }
  
  // Brush settings panel
  Rectangle {
    id: brushSettingsPanel
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 70
    anchors.bottomMargin: 20
    width: 250
    height: 150
    color: "#80000000"
    radius: 10
    visible: false
    
    Column {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10
      
      Text {
        text: qsTr("Settings")
        font.pixelSize: 16
        color: "white"
        anchors.horizontalCenter: parent.horizontalCenter
      }
      
      // Brush size
      Row {
        width: parent.width
        height: 30
        spacing: 10
        
        Text {
          text: qsTr("Brush Size:")
          color: "white"
          font.pixelSize: 14
          width: 80
          anchors.verticalCenter: parent.verticalCenter
        }
        
        Slider {
          id: brushSizeSlider
          width: parent.width - 100
          height: 30
          from: 1
          to: 30
          value: cameraSettings.brushSize
          stepSize: 1
          anchors.verticalCenter: parent.verticalCenter
          
          onValueChanged: {
            cameraSettings.brushSize = value
          }
        }
        
        Text {
          text: cameraSettings.brushSize
          color: "white"
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }
      }
      
      // Text size
      Row {
        width: parent.width
        height: 30
        spacing: 10
        
        Text {
          text: qsTr("Text Size:")
          color: "white"
          font.pixelSize: 14
          width: 80
          anchors.verticalCenter: parent.verticalCenter
        }
        
        Slider {
          id: textSizeSlider
          width: parent.width - 100
          height: 30
          from: 10
          to: 50
          value: cameraSettings.textSize
          stepSize: 2
          anchors.verticalCenter: parent.verticalCenter
          
          onValueChanged: {
            cameraSettings.textSize = value
          }
        }
        
        Text {
          text: cameraSettings.textSize
          color: "white"
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }
  
  // Settings button to show brush settings panel
  Rectangle {
    id: settingsButton
    width: 50
    height: 50
    radius: 25
    color: "#80000000"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 10
    anchors.bottomMargin: 10
    
    Image {
      anchors.centerIn: parent
      source: Theme.getThemeVectorIcon("ic_settings_white_24dp")
      width: 30
      height: 30
    }
    
    MouseArea {
      anchors.fill: parent
      onClicked: {
        brushSettingsPanel.visible = !brushSettingsPanel.visible
      }
    }
  }
}