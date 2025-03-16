import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import org.qgis
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Drawer {
  id: dashBoard
  objectName: "dashBoard"

  signal showMainMenu(point p)
  signal showPrintLayouts(point p)
  signal showProjectFolder
  signal toggleMeasurementTool
  signal showweatherDataPanel
  signal returnHome

  property bool allowInteractive: true
  property alias allowActiveLayerChange: legend.allowActiveLayerChange
  property alias activeLayer: legend.activeLayer
  property alias layerTree: legend.model
  property MapSettings mapSettings
  property bool shouldReturnHome: false

  property color mainColor: Theme.mainColor

  Component.onCompleted: {
    if (Material.roundedScale) {
      Material.roundedScale = Material.NotRounded;
    }
  }

  width: Math.min(Math.max(280, closeButton.width + buttonsRow.width + menuButton.width), mainWindow.width)
  height: parent.height
  edge: Qt.LeftEdge
  dragMargin: 10
  padding: 0
  interactive: allowInteractive && buttonsRowContainer.width >= buttonsRow.width

  property bool preventFromOpening: overlayFeatureFormDrawer.visible

  position: 0
  focus: visible
  clip: true

  onActiveLayerChanged: {
    if (activeLayer && activeLayer.readOnly && stateMachine.state == "digitize")
      displayToast(qsTr("The layer %1 is read only.").arg(activeLayer.name));
  }

  Connections {
    target: stateMachine

    function onStateChanged() {
      if (stateMachine.state === "measure") {
        return;
      }
      modeSwitch.checked = stateMachine.state === "digitize";
    }
  }

  ColumnLayout {
    anchors.fill: parent

    Rectangle {
      height: mainWindow.sceneTopMargin + Math.max(buttonsRow.height + 8, buttonsRow.childrenRect.height)
      Layout.fillWidth: true
      Layout.preferredHeight: height

      color: mainColor

      QfToolButton {
        id: closeButton
        anchors.left: parent.left
        anchors.verticalCenter: buttonsRowContainer.verticalCenter
        iconSource: Theme.getThemeVectorIcon('ic_arrow_left_white_24dp')
        iconColor: Theme.mainOverlayColor
        bgcolor: "transparent"
        onClicked: close()
      }

      Flickable {
        id: buttonsRowContainer
        anchors.left: closeButton.right
        anchors.right: menuButton.left
        anchors.top: parent.top
        anchors.topMargin: mainWindow.sceneTopMargin + 4
        anchors.bottomMargin: 4
        height: buttonsRow.height
        contentWidth: buttonsRow.width
        contentHeight: buttonsRow.height
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        ScrollBar.horizontal: QfScrollBar {
          visible: !dashBoard.interactive
          color: Theme.mainOverlayColor
          backgroundColor: Theme.mainColor
          _minSize: 2
          _maxSize: 2
        }

        Row {
          id: buttonsRow
          objectName: "dashboardActionsToolbar"
          height: 48
          spacing: 1

          QfToolButton {
            id: measurementButton
            anchors.verticalCenter: parent.verticalCenter
            round: true
            iconSource: Theme.getThemeVectorIcon("ic_measurement_black_24dp")
            iconColor: Theme.mainOverlayColor
            bgcolor: "transparent"
            onClicked: {
              toggleMeasurementTool();
              highlighted = false;
            }
          }

          QfToolButton {
            id: printItemButton
            anchors.verticalCenter: parent.verticalCenter
            round: true
            iconSource: Theme.getThemeVectorIcon("ic_print_black_24dp")
            iconColor: Theme.mainOverlayColor
            onClicked: {
              const p = mapToItem(mainWindow.contentItem, 0, 0);
              showPrintLayouts(p);
              highlighted = false;
            }
          }

          QfToolButton {
            id: projectFolderButton
            anchors.verticalCenter: parent.verticalCenter
            font: Theme.defaultFont
            iconSource: Theme.getThemeVectorIcon("ic_project_folder_black_24dp")
            iconColor: Theme.mainOverlayColor
            round: true
            onClicked: {
              showProjectFolder();
            }
          }

          QfToolButton {
            id: weatherDataButton
            anchors.verticalCenter: parent.verticalCenter
            font: Theme.defaultFont
            iconSource: Theme.getThemeVectorIcon("weather-station")
            iconColor: Theme.mainOverlayColor
            round: true
            onClicked: {
              showweatherDataPanel();
            }
          }
        }
      }

      QfToolButton {
        id: menuButton
        anchors.right: parent.right
        anchors.verticalCenter: buttonsRowContainer.verticalCenter
        iconSource: Theme.getThemeVectorIcon('ic_dot_menu_black_24dp')
        iconColor: Theme.mainOverlayColor
        bgcolor: "transparent"
        onClicked: {
          let p = mapToItem(mainWindow.contentItem, width, 0);
          showMainMenu(p);
        }
      }
    }

    GroupBox {
      id: mapThemeContainer
      Layout.fillWidth: true
      title: qsTr("Map Theme")
      leftPadding: 10
      rightPadding: 10
      topPadding: label.height + 5
      bottomPadding: 5

      property bool isLoading: false

      label: Label {
        x: parent.leftPadding
        y: 2
        width: parent.availableWidth
        text: parent.title
        color: Theme.mainColor
        font: Theme.strongTipFont
        elide: Text.ElideRight
      }

      background: Rectangle {
        y: parent.height - 1
        width: parent.width
        height: 1
        color: Theme.mainColor
      }

      RowLayout {
        width: parent.width
        ComboBox {
          id: mapThemeComboBox
          Layout.fillWidth: true
          font: Theme.defaultFont

          popup.font: Theme.defaultFont
          popup.topMargin: mainWindow.sceneTopMargin
          popup.bottomMargin: mainWindow.sceneTopMargin

          Connections {
            target: iface

            function onLoadProjectTriggered() {
              mapThemeContainer.isLoading = true;
            }

            function onLoadProjectEnded() {
              var themes = qgisProject.mapThemeCollection.mapThemes;
              mapThemeComboBox.model = themes;
              mapThemeComboBox.enabled = themes.length > 1;
              mapThemeComboBox.opacity = themes.length > 1 ? 1 : 0.25;
              mapThemeContainer.visible = themes.length > 1 || flatLayerTree.isTemporal;
              flatLayerTree.updateCurrentMapTheme();
              mapThemeComboBox.currentIndex = flatLayerTree.mapTheme != '' ? mapThemeComboBox.find(flatLayerTree.mapTheme) : -1;
              mapThemeContainer.isLoading = false;
            }
          }

          Connections {
            target: flatLayerTree

            function onMapThemeChanged() {
              if (!mapThemeContainer.isLoading && mapThemeComboBox.currentText != flatLayerTree.mapTheme) {
                mapThemeContainer.isLoading = true;
                mapThemeComboBox.currentIndex = flatLayerTree.mapTheme != '' ? mapThemeComboBox.find(flatLayerTree.mapTheme) : -1;
                mapThemeContainer.isLoading = false;
              }
            }
          }

          onCurrentTextChanged: {
            if (!mapThemeContainer.isLoading && qgisProject.mapThemeCollection.mapThemes.length > 1) {
              flatLayerTree.mapTheme = mapThemeComboBox.currentText;
            }
          }

          delegate: ItemDelegate {
            width: mapThemeComboBox.width
            height: 36
            text: modelData
            font.weight: mapThemeComboBox.currentIndex === index ? Font.DemiBold : Font.Normal
            font.pointSize: Theme.tipFont.pointSize
            highlighted: mapThemeComboBox.highlightedIndex == index
          }

          contentItem: Text {
            height: 36
            leftPadding: 8
            text: mapThemeComboBox.displayText
            font: Theme.tipFont
            color: Theme.mainTextColor
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          background: Item {
            implicitWidth: 120
            implicitHeight: 36

            Rectangle {
              id: backgroundRect
              anchors.fill: parent
              border.color: mapThemeComboBox.pressed ? "#17a81a" : Theme.mainColor
              border.width: mapThemeComboBox.visualFocus ? 2 : 1
              color: "transparent"
              radius: 2
            }
          }
        }

        QfToolButton {
          id: temporalButton
          Layout.alignment: Qt.AlignVCenter
          visible: flatLayerTree.isTemporal
          iconSource: Theme.getThemeVectorIcon('ic_temporal_black_24dp')
          iconColor: mapSettings.isTemporal ? Theme.mainColor : Theme.mainTextColor
          bgcolor: "transparent"
          onClicked: temporalProperties.open()
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: Theme.controlBackgroundColor

      Legend {
        id: legend
        isVisible: position > 0
        anchors.fill: parent
        bottomMargin: bottomRow.height + 4
      }
    }
  }

  Rectangle {
    id: bottomRow
    height: 75+ mainWindow.sceneBottomMargin
    width: parent.width
    anchors.bottom: parent.bottom
    color: Theme.darkTheme ? Theme.mainBackgroundColorSemiOpaque : Theme.lightestGray

    Item {
      width: parent.width
      height: 75
      anchors.bottom: parent.bottom
      anchors.bottomMargin: mainWindow.sceneBottomMargin

      MenuItem {
        id: homeButton
        width: parent.width - modeSwitch.width
        height: 75
        icon.source: Theme.getThemeVectorIcon("ic_home_black_24dp")
        font: Theme.defaultFont
        text: "Return"

        onClicked: returnHome()
      }

      Switch {
        id: modeSwitch
        visible: projectInfo.insertRights
        width: 50 + 100
        height: 75
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        indicator: Rectangle {
          implicitHeight: 50
          implicitWidth: 60 * 2
          x: modeSwitch.leftPadding
          radius: 4
          color: "#24212121"
          border.color: "#14FFFFFF"
          anchors.verticalCenter: parent.verticalCenter
          Image {
            width: 50
            height: 50
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            source: Theme.getThemeVectorIcon('ic_map_white_24dp')
            sourceSize.width: parent.height * screen.devicePixelRatio
            sourceSize.height: parent.width * screen.devicePixelRatio
            opacity: 0.6
          }
          Image {
            width: 50
            height: 50
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            source: Theme.getThemeVectorIcon('ic_create_white_24dp')
            sourceSize.width: parent.height * screen.devicePixelRatio
            sourceSize.height: parent.width * screen.devicePixelRatio
            opacity: 0.6
          }
          Rectangle {
            x: modeSwitch.checked ? parent.width - width : 0
            width: 55
            height: 50
            radius: 4
            color: Theme.mainColor
            border.color: Theme.mainOverlayColor
            Image {
              width: 50
              height: 50
              anchors.centerIn: parent
              source: modeSwitch.checked ? Theme.getThemeVectorIcon('ic_create_white_24dp') : Theme.getThemeVectorIcon('ic_map_white_24dp')
              sourceSize.width: parent.height * screen.devicePixelRatio
              sourceSize.height: parent.width * screen.devicePixelRatio
            }
            Behavior on x  {
              PropertyAnimation {
                duration: 100
                easing.type: Easing.OutQuart
              }
            }
          }
        }

        onClicked: mainWindow.toggleDigitizeMode()
      }
    }
  }

  TemporalProperties {
    id: temporalProperties
    mapSettings: dashBoard.mapSettings
  }

  // Function to ensure an editable layer is selected
  function ensureEditableLayerSelected() {
    if (!activeLayer || activeLayer.readOnly) {
      // Find the first editable layer
      var editableLayers = []
      
      // Iterate through the layer tree to find editable layers
      for (var i = 0; i < layerTree.rowCount(); i++) {
        var index = layerTree.index(i, 0)
        var layer = layerTree.data(index, 0)
        
        // Check if it's a valid vector layer and not read-only
        if (layer && layer.isValid && !layer.readOnly && layer.type === 0) { // type 0 is VectorLayer
          editableLayers.push(layer)
        }
      }
      
      if (editableLayers.length > 0) {
        // Set the first editable layer as active
        legend.activeLayer = editableLayers[0]
        return true
      } else {
        console.log("No editable layers found")
        return false
      }
    }
    return true
  }
}
