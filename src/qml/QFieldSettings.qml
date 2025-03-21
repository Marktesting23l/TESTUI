import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Page {
  signal finished

  property alias currentPanel: bar.currentIndex

  property alias showScaleBar: registry.showScaleBar
  property alias fullScreenIdentifyView: registry.fullScreenIdentifyView
  property alias locatorKeepScale: registry.locatorKeepScale
  property alias numericalDigitizingInformation: registry.numericalDigitizingInformation
  property alias showBookmarks: registry.showBookmarks
  property alias nativeCamera2: registry.nativeCamera2
  property alias digitizingVolumeKeys: registry.digitizingVolumeKeys
  property alias autoSave: registry.autoSave
  property alias fingerTapDigitizing: registry.fingerTapDigitizing
  property alias mouseAsTouchScreen: registry.mouseAsTouchScreen
  property alias enableInfoCollection: registry.enableInfoCollection
  property alias enableMapRotation: registry.enableMapRotation
  property alias quality: registry.quality
  property alias snapToCommonAngleIsEnabled: registry.snapToCommonAngleIsEnabled
  property alias snapToCommonAngleIsRelative: registry.snapToCommonAngleIsRelative
  property alias snapToCommonAngleDegrees: registry.snapToCommonAngleDegrees
  property alias snapToCommonAngleTolerance: registry.snapToCommonAngleTolerance
  property alias sentinelInstanceId: registry.sentinelInstanceId
  property alias enableSentinelLayers: registry.enableSentinelLayers

  visible: false
  focus: visible

  Component.onCompleted: {
    if (settings.valueBool('nativeCameraLaunched', false)) {
      // a crash occured while the native camera was launched, disable it
      nativeCamera2 = false;
    }
  }

  function reset() {
    variableEditor.reset();
  }

  function openSentinelConfig() {
    var component = Qt.createComponent("SentinelConfigScreen.qml");
    if (component.status === Component.Ready) {
      var sentinelConfig = component.createObject(mainWindow, {
        "instanceId": registry.sentinelInstanceId
      });
      sentinelConfig.open();
      sentinelConfig.onInstanceIdChanged.connect(function() {
        registry.sentinelInstanceId = sentinelConfig.instanceId;
      });
    } else {
      console.error("Error loading SentinelConfigScreen.qml:", component.errorString());
    }
  }

  Settings {
    id: registry
    property bool showScaleBar: true
    property bool fullScreenIdentifyView: false
    property bool locatorKeepScale: false
    property bool numericalDigitizingInformation: false
    property bool showBookmarks: true
    property bool nativeCamera2: false
    property bool digitizingVolumeKeys: platformUtilities.capabilities & PlatformUtilities.VolumeKeys
    property bool autoSave: false
    property bool fingerTapDigitizing: false
    property bool mouseAsTouchScreen: false
    property bool enableInfoCollection: false
    property bool enableMapRotation: true
    property double quality: 1.0
    property string sentinelInstanceId: settings ? settings.value("SIGPACGO/Sentinel/InstanceId", "") : ""
    property bool enableSentinelLayers: settings ? settings.valueBool("SIGPACGO/Sentinel/EnableLayers", true) : true

    property bool snapToCommonAngleIsEnabled: false
    property bool snapToCommonAngleIsRelative: true
    property double snapToCommonAngleDegrees: 45.0// = settings.valueInt("/SIGPACGO/Digitizing/SnapToCommonAngleDegrees", 45);
    property int snapToCommonAngleTolerance: 1// = settings.valueInt("/SIGPACGO/Digitizing/SnappingTolerance", 1);
    onDigitizingVolumeKeysChanged: {
      platformUtilities.setHandleVolumeKeys(digitizingVolumeKeys && stateMachine.state != 'browse');
    }

    onFingerTapDigitizingChanged: {
      coordinateLocator.sourceLocation = undefined;
    }

    onSentinelInstanceIdChanged: {
      settings.setValue("SIGPACGO/Sentinel/InstanceId", sentinelInstanceId);
    }

    onEnableSentinelLayersChanged: {
      settings.setValue("SIGPACGO/Sentinel/EnableLayers", enableSentinelLayers);
    }
  }

  ListModel {
    id: canvasSettingsModel
    ListElement {
      title: qsTr("Mostrar barra de escala")
      description: ''
      settingAlias: "showScaleBar"
      isVisible: true
    }
    ListElement {
      title: qsTr("Mostrar marcadores")
      description: qsTr("Muestra los marcadores guardados y del proyecto en el mapa.")
      settingAlias: "showBookmarks"
      isVisible: true
    }
    ListElement {
      title: qsTr("Habilitar rotación del mapa")
      description: qsTr("Permite rotar el mapa.")
      settingAlias: "enableMapRotation"
      isVisible: true
    }
  }

  ListModel {
    id: digitizingEditingSettingsModel
    ListElement {
      title: qsTr("Mostrar información de digitalización")
      description: qsTr("Muestra las coordenadas en el mapa mientras se digitaliza o mide.")
      settingAlias: "numericalDigitizingInformation"
      isVisible: true
    }
    ListElement {
      title: qsTr("Modo de edición rápida")
      description: qsTr("Guarda automáticamente las entidades cuando la geometría es válida y se cumplen las restricciones.")
      settingAlias: "autoSave"
      isVisible: true
    }
    ListElement {
      title: qsTr("Usar las teclas de volumen para digitalizar")
      description: qsTr("Subir volumen añade un vértice, bajar volumen elimina el último vértice.")
      settingAlias: "digitizingVolumeKeys"
      isVisible: true
    }
    ListElement {
      title: qsTr("Permitir tocar la pantalla para añadir vértices")
      description: qsTr("Tocar en el mapa para añadir un vértice.")
      settingAlias: "fingerTapDigitizing"
      isVisible: true
    }
    ListElement {
      title: qsTr("Considerar el ratón como un dispositivo de pantalla táctil")
      description: qsTr("El ratón actúa como un dedo. Cuando está desactivado, el ratón actúa como un lápiz.")
      settingAlias: "mouseAsTouchScreen"
      isVisible: true
    }
    Component.onCompleted: {
      for (var i = 0; i < count; i++) {
        if (get(i).settingAlias === 'digitizingVolumeKeys') {
          setProperty(i, 'isVisible', platformUtilities.capabilities & PlatformUtilities.VolumeKeys ? true : false);
        } else {
          setProperty(i, 'isVisible', true);
        }
      }
    }
  }

  ListModel {
    id: interfaceSettingsModel
    ListElement {
      title: qsTr("Formulario de atributos maximizado")
      description: ''
      settingAlias: "fullScreenIdentifyView"
      isVisible: true
    }
    ListElement {
      title: qsTr("Navegación a escala fija")
      description: qsTr("Los resultados de búsqueda solo se desplazan a la entidad sin hacer zoom.")
      settingAlias: "locatorKeepScale"
      isVisible: true
    }
  }
  ListModel {
    id: advancedSettingsModel
    ListElement {
      title: qsTr("Usar cámara nativa")
      description: qsTr("Usa la aplicación de cámara del dispositivo en lugar de la cámara integrada. Bueno para fotos geoetiquetadas.")
      settingAlias: "nativeCamera2"
      isVisible: true
    }
    Component.onCompleted: {
      for (var i = 0; i < count; i++) {
        if (get(i).settingAlias === 'nativeCamera2') {
          setProperty(i, 'isVisible', platformUtilities.capabilities & PlatformUtilities.NativeCamera ? true : false);
        }
      }
    }
  }

  ListModel {
    id: sentinelSettingsModel
    ListElement {
      title: qsTr("Habilitar capas WMS de Sentinel")
      description: qsTr("Añadir capas de imágenes de satélite Sentinel a todos los proyectos.")
      settingAlias: "enableSentinelLayers"
      isVisible: true
    }
  }

  Rectangle {
    color: Theme.mainBackgroundColor
    anchors.fill: parent
  }

  ColumnLayout {
    id: barColumn
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      bottom: parent.bottom
    }

    QfTabBar {
          id: bar
          model: [qsTr("General"), qsTr("Posicionamiento"), qsTr("Variables")]
          Layout.fillWidth: true
          Layout.preferredHeight: defaultHeight
        }

    Component {
      id: listItem

      Rectangle {
        width: parent ? parent.width - 16 : undefined
        height: isVisible ? line.height : 0
        color: "transparent"
        clip: true

        Row {
          id: line
          width: parent.width

          Column {
            width: parent.width - toggle.width

            Label {
              width: parent.width
              padding: 8
              leftPadding: 20
              text: title
              font: Theme.defaultFont
              color: Theme.mainTextColor
              wrapMode: Text.WordWrap
              MouseArea {
                anchors.fill: parent
                onClicked: toggle.toggle()
              }
            }

            Label {
              width: parent.width
              visible: description !== ''
              padding: description !== '' ? 8 : 0
              topPadding: 0
              leftPadding: 20
              text: description
              font: Theme.tipFont
              color: Theme.secondaryTextColor
              wrapMode: Text.WordWrap
            }
          }

          QfSwitch {
            id: toggle
            width: implicitContentWidth
            checked: registry[settingAlias]
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            onCheckedChanged: registry[settingAlias] = checked
          }
        }
      }
    }

    SwipeView {
      id: swipeView
      width: mainWindow.width
      currentIndex: bar.currentIndex
      Layout.fillHeight: true
      Layout.fillWidth: true
      onCurrentIndexChanged: bar.currentIndex = swipeView.currentIndex

      Item {
        ScrollView {
          topPadding: 5
          leftPadding: 0
          rightPadding: 0
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
          ScrollBar.vertical: QfScrollBar {
          }
          contentWidth: generalSettingsGrid.width
          contentHeight: generalSettingsGrid.height
          anchors.fill: parent
          clip: true

          ColumnLayout {
            id: generalSettingsGrid
            width: parent.parent.width

            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20

              columns: 2
              columnSpacing: 0
              rowSpacing: 5

              Label {
                text: qsTr('Lienzo del mapa')
                font: Theme.strongFont
                color: Theme.mainColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.columnSpan: 2
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                height: 1
                color: Theme.mainColor
              }
            }

            ListView {
              Layout.preferredWidth: mainWindow.width
              Layout.preferredHeight: childrenRect.height
              interactive: false

              model: canvasSettingsModel

              delegate: listItem
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20

              columns: 2
              columnSpacing: 0
              rowSpacing: 5

              Label {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                text: qsTr("Calidad de renderizado del lienzo del mapa:")
                font: Theme.defaultFont
                color: Theme.mainTextColor

                wrapMode: Text.WordWrap
              }

              ComboBox {
                id: renderingQualityComboBox
                enabled: true
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignVCenter
                font: Theme.defaultFont

                popup.font: Theme.defaultFont
                popup.topMargin: mainWindow.sceneTopMargin
                popup.bottomMargin: mainWindow.sceneTopMargin

                model: ListModel {
                  ListElement {
                    name: qsTr('Mejor calidad')
                    value: 1.0
                  }
                  ListElement {
                    name: qsTr('Menor calidad')
                    value: 0.75
                  }
                  ListElement {
                    name: qsTr('Calidad más baja')
                    value: 0.5
                  }
                }
                textRole: "name"
                valueRole: "value"

                property bool initialized: false

                onCurrentValueChanged: {
                  if (initialized) {
                    quality = currentValue;
                  }
                }

                Component.onCompleted: {
                  currentIndex = indexOfValue(quality);
                  initialized = true;
                }
              }

              Label {
                text: qsTr("Una calidad más baja reduce el uso de memoria y mejora el rendimiento.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.columnSpan: 2

                onLinkActivated: link => {
                  Qt.openUrlExternally(link);
                }
              }

              Label {
                text: qsTr('Digitalización y edición')
                font: Theme.strongFont
                color: Theme.mainColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.columnSpan: 2
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                height: 1
                color: Theme.mainColor
              }
            }

            ListView {
              Layout.preferredWidth: mainWindow.width
              Layout.preferredHeight: childrenRect.height
              interactive: false

              model: digitizingEditingSettingsModel

              delegate: listItem
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20

              columns: 2
              columnSpacing: 0
              rowSpacing: 5

              Label {
                text: qsTr('Interfaz de usuario')
                font: Theme.strongFont
                color: Theme.mainColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.columnSpan: 2
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                height: 1
                color: Theme.mainColor
              }

              Label {
                text: qsTr("Personalizar la barra de búsqueda")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 5

                MouseArea {
                  anchors.fill: parent
                  onClicked: showSearchBarSettings.clicked()
                }
              }

              QfToolButton {
                id: showSearchBarSettings
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                clip: true

                iconSource: Theme.getThemeVectorIcon("ic_ellipsis_black_24dp")
                iconColor: Theme.mainColor
                bgcolor: "transparent"

                onClicked: {
                  locatorSettings.open();
                  locatorSettings.focus = true;
                }
              }

              Label {
                text: qsTr("Administrar plugins")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true

                MouseArea {
                  anchors.fill: parent
                  onClicked: showPluginManagerSettings.clicked()
                }
              }

              QfToolButton {
                id: showPluginManagerSettings
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                clip: true

                iconSource: Theme.getThemeVectorIcon("ic_ellipsis_black_24dp")
                iconColor: Theme.mainColor
                bgcolor: "transparent"

                onClicked: {
                  pluginManagerSettings.open();
                }
              }
            }

            ListView {
              Layout.preferredWidth: mainWindow.width
              Layout.preferredHeight: childrenRect.height
              interactive: false

              model: interfaceSettingsModel

              delegate: listItem
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.topMargin: 5
              Layout.bottomMargin: 5

              columns: 1
              columnSpacing: 0
              rowSpacing: 0

              visible: platformUtilities.capabilities & PlatformUtilities.AdjustBrightness

              Label {
                Layout.fillWidth: true

                text: qsTr('Atenuar la pantalla cuando esté inactiva')
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
              }

              QfSlider {
                id: slider
                Layout.fillWidth: true
                value: settings ? settings.value('dimTimeoutSeconds', 40) : 40
                from: 0
                to: 180
                stepSize: 10
                suffixText: " s"
                implicitHeight: 40

                onMoved: function () {
                  iface.setScreenDimmerTimeout(value);
                  settings.setValue('dimTimeoutSeconds', value);
                }
              }

              Label {
                Layout.fillWidth: true
                text: qsTr('Segundos de inactividad antes de atenuar la pantalla para ahorrar batería.')

                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
              }
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20
              Layout.topMargin: 5
              Layout.bottomMargin: 40

              columns: 1
              columnSpacing: 0
              rowSpacing: 5

              Label {
                Layout.fillWidth: true
                text: qsTr("Apariencia:")
                font: Theme.defaultFont
                color: Theme.mainTextColor

                wrapMode: Text.WordWrap
              }

              ComboBox {
                id: appearanceComboBox
                enabled: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                font: Theme.defaultFont

                popup.font: Theme.defaultFont
                popup.topMargin: mainWindow.sceneTopMargin
                popup.bottomMargin: mainWindow.sceneTopMargin

                model: ListModel {
                  ListElement {
                    name: qsTr('Seguir la apariencia del sistema')
                    value: 'system'
                  }
                  ListElement {
                    name: qsTr('Tema claro')
                    value: 'light'
                  }
                  ListElement {
                    name: qsTr('Tema oscuro')
                    value: 'dark'
                  }
                }
                textRole: "name"
                valueRole: "value"

                property bool initialized: false

                onCurrentValueChanged: {
                  if (initialized) {
                    settings.setValue("appearance", currentValue);
                    Theme.applyAppearance();
                  }
                }

                Component.onCompleted: {
                  var appearance = settings.value("appearance", 'system');
                  currentIndex = indexOfValue(appearance);
                  initialized = true;
                }
              }

              Label {
                Layout.fillWidth: true
                text: qsTr("Tamaño de fuente:")
                font: Theme.defaultFont
                color: Theme.mainTextColor

                wrapMode: Text.WordWrap
              }

              ComboBox {
                id: fontScaleComboBox
                enabled: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                font: Theme.defaultFont

                popup.font: Theme.defaultFont
                popup.topMargin: mainWindow.sceneTopMargin
                popup.bottomMargin: mainWindow.sceneTopMargin

                model: ListModel {
                  ListElement {
                    name: qsTr('Diminuto')
                    value: 0.75
                  }
                  ListElement {
                    name: qsTr('Normal')
                    value: 1.0
                  }
                  ListElement {
                    name: qsTr('Grande')
                    value: 1.5
                  }
                  ListElement {
                    name: qsTr('Extragrande')
                    value: 2.0
                  }
                }
                textRole: "name"
                valueRole: "value"

                property bool initialized: false

                onCurrentValueChanged: {
                  if (initialized) {
                    settings.setValue("fontScale", currentValue);
                    Theme.applyFontScale();
                  }
                }

                Component.onCompleted: {
                  var fontScale = settings.value("fontScale", 1.0);
                  currentIndex = indexOfValue(fontScale);
                  initialized = true;
                }
              }

              Label {
                Layout.fillWidth: true
                text: qsTr("Idioma:")
                font: Theme.defaultFont
                color: Theme.mainTextColor

                wrapMode: Text.WordWrap
              }

              Label {
                id: languageTip
                visible: false

                Layout.fillWidth: true
                text: qsTr("Reinicie SIGPAC-Go para aplicar el cambio de idioma.")
                font: Theme.tipFont
                color: Theme.warningColor

                wrapMode: Text.WordWrap
              }

              ComboBox {
                id: languageComboBox
                enabled: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                font: Theme.defaultFont

                popup.font: Theme.defaultFont
                popup.topMargin: mainWindow.sceneTopMargin
                popup.bottomMargin: mainWindow.sceneBottomMargin

                property variant languageCodes: undefined
                property string currentLanguageCode: undefined

                onCurrentIndexChanged: {
                  if (currentLanguageCode != undefined) {
                    settings.setValue("customLanguage", languageCodes[currentIndex]);
                    languageTip.visible = languageCodes[currentIndex] !== currentLanguageCode;
                  }
                }

                Component.onCompleted: {
                  var customLanguageCode = settings.value('customLanguage', 'es');
                  var languages = iface.availableLanguages();
                  languageCodes = [""].concat(Object.keys(languages));
                  var systemLanguage = qsTr("sistema");
                  var systemLanguageSuffix = systemLanguage !== 'system' ? ' (system)' : '';
                  var items = [systemLanguage + systemLanguageSuffix];
                  languageComboBox.model = items.concat(Object.values(languages));
                  languageComboBox.currentIndex = languageCodes.indexOf(customLanguageCode);
                  currentLanguageCode = customLanguageCode || 'es';
                  languageTip.visible = false;
                }
              }

              Label {
                text: qsTr("Español dispoible, Inglés en proceso")
                font: Theme.tipFont
                color: Theme.mainTextColor
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true

                onLinkActivated: link => {
                  Qt.openUrlExternally(link);
                }
              }
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20

              columns: 2
              columnSpacing: 0
              rowSpacing: 5

              visible: platformUtilities.capabilities & PlatformUtilities.NativeCamera || platformUtilities.capabilities & PlatformUtilities.SentryFramework

              Label {
                text: qsTr('Avanzado')
                font: Theme.strongFont
                color: Theme.mainColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.columnSpan: 2
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                height: 1
                color: Theme.mainColor
              }
            }

            ListView {
              Layout.preferredWidth: mainWindow.width
              Layout.preferredHeight: childrenRect.height
              interactive: false

              model: advancedSettingsModel

              delegate: listItem
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.leftMargin: 20
              Layout.rightMargin: 20

              columns: 2
              columnSpacing: 0
              rowSpacing: 5

              Label {
                text: qsTr('Configuración de Sentinel WMS')
                font: Theme.strongFont
                color: Theme.mainColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 5
                Layout.columnSpan: 2
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                height: 1
                color: Theme.mainColor
              }

              QfToolButton {
                id: openSentinelConfigButton
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                Layout.topMargin: 10
                Layout.columnSpan: 2
                Layout.fillWidth: true
                
                text: qsTr("Configuración avanzada de Sentinel")
                iconSource: Theme.getThemeVectorIcon("ic_settings_white_24dp")
                iconColor: Theme.mainColor
                bgcolor: Theme.toolButtonBackgroundColor
                
                onClicked: openSentinelConfig()
              }

              Label {
                text: qsTr("Configurar capas y parámetros de Sentinel Copernicus Hub WMS")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.columnSpan: 2
              }

              Label {
                text: qsTr("Nota: Debe reiniciar SIGPACGO o volver a cargar su proyecto para que la configuración de Sentinel surta efecto.")
                font: Theme.tipFont
                color: Theme.warningColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.topMargin: 10
              }
            }

            ListView {
              Layout.preferredWidth: mainWindow.width
              Layout.preferredHeight: childrenRect.height
              interactive: false

              model: sentinelSettingsModel

              delegate: listItem
            }

            Item {
              // spacer item
              Layout.fillWidth: true
              Layout.fillHeight: true
              Layout.minimumHeight: mainWindow.sceneBottomMargin + 20
            }
          }
        }
      }

      Item {
        ScrollView {
          topPadding: 5
          leftPadding: 20
          rightPadding: 20
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
          ScrollBar.vertical: QfScrollBar {
          }
          contentWidth: positioningGrid.width
          contentHeight: positioningGrid.height
          anchors.fill: parent
          clip: true

          ColumnLayout {
            id: positioningGrid
            width: parent.parent.width
            spacing: 10

            GridLayout {
              Layout.fillWidth: true

              columns: 2
              columnSpacing: 0
              rowSpacing: 5

              Label {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                text: qsTr("Dispositivo de posicionamiento en uso:")
                font: Theme.defaultFont
                color: Theme.mainTextColor

                wrapMode: Text.WordWrap
              }

              RowLayout {
                Layout.fillWidth: true
                Layout.columnSpan: 2

                ComboBox {
                  id: positioningDeviceComboBox
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  font: Theme.defaultFont

                  popup.font: Theme.defaultFont
                  popup.topMargin: mainWindow.sceneTopMargin
                  popup.bottomMargin: mainWindow.sceneTopMargin

                  textRole: 'DeviceName'
                  valueRole: 'DeviceType'
                  model: PositioningDeviceModel {
                    id: positioningDeviceModel
                  }

                  delegate: ItemDelegate {
                    width: positioningDeviceComboBox.width
                    height: 36
                    icon.source: {
                      switch (DeviceType) {
                      case PositioningDeviceModel.InternalDevice:
                        return Theme.getThemeVectorIcon('ic_internal_receiver_black_24dp');
                      case PositioningDeviceModel.BluetoothDevice:
                        return Theme.getThemeVectorIcon('ic_bluetooth_receiver_black_24dp');
                      case PositioningDeviceModel.TcpDevice:
                        return Theme.getThemeVectorIcon('ic_tcp_receiver_black_24dp');
                      case PositioningDeviceModel.UdpDevice:
                        return Theme.getThemeVectorIcon('ic_udp_receiver_black_24dp');
                      case PositioningDeviceModel.SerialPortDevice:
                        return Theme.getThemeVectorIcon('ic_serial_port_receiver_black_24dp');
                      case PositioningDeviceModel.EgenioussDevice:
                        return Theme.getThemeVectorIcon('ic_egeniouss_receiver_black_24dp');
                      }
                      return '';
                    }
                    icon.width: 24
                    icon.height: 24
                    text: DeviceName
                    font: Theme.defaultFont
                    highlighted: positioningDeviceComboBox.highlightedIndex === index
                  }

                  contentItem: MenuItem {
                    width: positioningDeviceComboBox.width
                    height: 36

                    icon.source: {
                      switch (positioningDeviceComboBox.currentValue) {
                      case PositioningDeviceModel.InternalDevice:
                        return Theme.getThemeVectorIcon('ic_internal_receiver_black_24dp');
                      case PositioningDeviceModel.BluetoothDevice:
                        return Theme.getThemeVectorIcon('ic_bluetooth_receiver_black_24dp');
                      case PositioningDeviceModel.TcpDevice:
                        return Theme.getThemeVectorIcon('ic_tcp_receiver_black_24dp');
                      case PositioningDeviceModel.UdpDevice:
                        return Theme.getThemeVectorIcon('ic_udp_receiver_black_24dp');
                      case PositioningDeviceModel.SerialPortDevice:
                        return Theme.getThemeVectorIcon('ic_serial_port_receiver_black_24dp');
                      case PositioningDeviceModel.EgenioussDevice:
                        return Theme.getThemeVectorIcon('ic_egeniouss_receiver_black_24dp');
                      }
                      return '';
                    }
                    icon.width: 24
                    icon.height: 24

                    text: positioningDeviceComboBox.currentText
                    font: Theme.defaultFont

                    onClicked: positioningDeviceComboBox.popup.open()
                  }

                  onCurrentIndexChanged: {
                    var modelIndex = positioningDeviceModel.index(currentIndex, 0);
                    positioningSettings.positioningDevice = positioningDeviceModel.data(modelIndex, PositioningDeviceModel.DeviceId);
                    positioningSettings.positioningDeviceName = positioningDeviceModel.data(modelIndex, PositioningDeviceModel.DeviceName);
                    verticalGridShiftComboBox.reload();
                  }

                  Component.onCompleted: {
                    currentIndex = positioningDeviceModel.findIndexFromDeviceId(settings.value('positioningDevice', ''));
                  }
                }
              }

              RowLayout {
                Layout.fillWidth: true
                Layout.columnSpan: 2

                QfButton {
                  leftPadding: 10
                  rightPadding: 10
                  text: qsTr('Añadir')

                  onClicked: {
                    positioningDeviceSettings.originalName = '';
                    positioningDeviceSettings.name = '';
                    positioningDeviceSettings.open();
                  }
                }

                Item {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                }

                QfButton {
                  leftPadding: 10
                  rightPadding: 10
                  text: qsTr('Editar')
                  enabled: positioningDeviceComboBox.currentIndex > 0

                  onClicked: {
                    var modelIndex = positioningDeviceModel.index(positioningDeviceComboBox.currentIndex, 0);
                    var name = positioningDeviceModel.data(modelIndex, PositioningDeviceModel.DeviceName);
                    positioningDeviceSettings.originalName = name;
                    positioningDeviceSettings.name = name;
                    positioningDeviceSettings.setType(positioningDeviceModel.data(modelIndex, PositioningDeviceModel.DeviceType));
                    positioningDeviceSettings.setSettings(positioningDeviceModel.data(modelIndex, PositioningDeviceModel.DeviceSettings));
                    positioningDeviceSettings.open();
                  }
                }

                QfButton {
                  leftPadding: 10
                  rightPadding: 10
                  text: qsTr('Eliminar')
                  enabled: positioningDeviceComboBox.currentIndex > 0

                  onClicked: {
                    var modelIndex = positioningDeviceModel.index(positioningDeviceComboBox.currentIndex, 0);
                    positioningDeviceComboBox.currentIndex = 0;
                    positioningDeviceModel.removeDevice(positioningDeviceModel.data(modelIndex, PositioningDeviceModel.DeviceName));
                  }
                }
              }

              QfButton {
                id: connectButton
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.topMargin: 5
                text: {
                  switch (positionSource.deviceSocketState) {
                  case QAbstractSocket.ConnectedState:
                  case QAbstractSocket.BoundState:
                    return qsTr('Conectado a %1').arg(positioningSettings.positioningDeviceName);
                  case QAbstractSocket.UnconnectedState:
                    return qsTr('Conectar a %1').arg(positioningSettings.positioningDeviceName);
                  default:
                    return qsTr('Conectando a %1').arg(positioningSettings.positioningDeviceName);
                  }
                }
                enabled: positionSource.deviceSocketState === QAbstractSocket.UnconnectedState
                visible: positionSource.deviceId !== ''

                onClicked: {
                  // make sure positioning is active when connecting to the bluetooth device
                  if (!positioningSettings.positioningActivated) {
                    positioningSettings.positioningActivated = true;
                  } else {
                    positionSource.triggerConnectDevice();
                  }
                }
              }
            }

            GridLayout {
              Layout.fillWidth: true

              columns: 2
              columnSpacing: 0
              rowSpacing: 5

              Label {
                text: qsTr("Mostrar información de posición")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true

                MouseArea {
                  anchors.fill: parent
                  onClicked: showPositionInformation.toggle()
                }
              }

              QfSwitch {
                id: showPositionInformation
                Layout.preferredWidth: implicitContentWidth
                Layout.alignment: Qt.AlignTop
                checked: positioningSettings.showPositionInformation
                onCheckedChanged: {
                  positioningSettings.showPositionInformation = checked;
                }
              }

              Label {
                id: measureLabel
                Layout.fillWidth: true
                Layout.columnSpan: 2
                text: qsTr("Valor de medición (M) adjunto a vértices:")
                font: Theme.defaultFont
                color: Theme.mainTextColor

                wrapMode: Text.WordWrap
              }

              ComboBox {
                id: measureComboBox
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignVCenter
                font: Theme.defaultFont

                popup.font: Theme.defaultFont
                popup.topMargin: mainWindow.sceneTopMargin
                popup.bottomMargin: mainWindow.sceneTopMargin

                property bool loaded: false
                Component.onCompleted: {
                  // This list matches the Tracker::MeasureType enum, with SecondsSinceStart removed
                  var measurements = [qsTr("Marca de tiempo (ms desde época)"), qsTr("Velocidad"), qsTr("Dirección"), qsTr("Precisión horizontal"), qsTr("Precisión vertical"), qsTr("PDOP"), qsTr("HDOP"), qsTr("VDOP")];
                  measureComboBox.model = measurements;
                  measureComboBox.currentIndex = positioningSettings.digitizingMeasureType - 1;
                  loaded = true;
                }

                onCurrentIndexChanged: {
                  if (loaded) {
                    positioningSettings.digitizingMeasureType = currentIndex + 1;
                  }
                }
              }

              Label {
                id: measureTipLabel
                Layout.fillWidth: true
                text: qsTr("Al digitalizar con el cursor bloqueado a la posición actual, esta medición se añadirá a la geometría si tiene dimensión M.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor

                wrapMode: Text.WordWrap
              }

              Item {
                // spacer item
                Layout.fillWidth: true
                Layout.fillHeight: true
              }

              Label {
                text: qsTr("Activar indicador de precisión")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true

                MouseArea {
                  anchors.fill: parent
                  onClicked: accuracyIndicator.toggle()
                }
              }

              QfSwitch {
                id: accuracyIndicator
                Layout.preferredWidth: implicitContentWidth
                Layout.alignment: Qt.AlignTop
                checked: positioningSettings.accuracyIndicator
                onCheckedChanged: {
                  positioningSettings.accuracyIndicator = checked;
                }
                Component.onCompleted: {
                  if (!positioningSettings.accuracyIndicator) {
                    positioningSettings.accuracyIndicator = true;
                  }
                }
              }

              Label {
                text: qsTr("Umbral de precisión mala [m]")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                enabled: accuracyIndicator.checked
                visible: accuracyIndicator.checked
                Layout.leftMargin: 8
              }

              QfTextField {
                id: accuracyBadInput
                width: antennaHeightActivated.width
                font: Theme.defaultFont
                enabled: accuracyIndicator.checked
                visible: accuracyIndicator.checked
                horizontalAlignment: TextInput.AlignHCenter
                Layout.preferredWidth: 60
                Layout.preferredHeight: font.height + 20

                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator {
                  locale: 'C'
                }

                Component.onCompleted: {
                  text = isNaN(positioningSettings.accuracyBad) ? '' : positioningSettings.accuracyBad;
                }

                onTextChanged: {
                  if (text.length === 0 || isNaN(text)) {
                    positioningSettings.accuracyBad = NaN;
                  } else {
                    positioningSettings.accuracyBad = parseFloat(text);
                  }
                }
              }

              Label {
                text: qsTr("Umbral de precisión excelente [m]")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                enabled: accuracyIndicator.checked
                visible: accuracyIndicator.checked
                Layout.leftMargin: 8
              }

              QfTextField {
                id: accuracyExcellentInput
                width: antennaHeightActivated.width
                font: Theme.defaultFont
                enabled: accuracyIndicator.checked
                visible: accuracyIndicator.checked
                horizontalAlignment: TextInput.AlignHCenter
                Layout.preferredWidth: 60
                Layout.preferredHeight: font.height + 20

                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator {
                  locale: 'C'
                }

                Component.onCompleted: {
                  text = isNaN(positioningSettings.accuracyExcellent) ? '' : positioningSettings.accuracyExcellent;
                }

                onTextChanged: {
                  if (text.length === 0 || isNaN(text)) {
                    positioningSettings.accuracyExcellent = NaN;
                  } else {
                    positioningSettings.accuracyExcellent = parseFloat(text);
                  }
                }
              }

              Label {
                text: qsTr("Aplicar requisito de precisión")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                enabled: accuracyIndicator.checked
                visible: accuracyIndicator.checked
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 8

                MouseArea {
                  anchors.fill: parent
                  onClicked: accuracyIndicator.toggle()
                }
              }

              QfSwitch {
                id: accuracyRequirement
                Layout.preferredWidth: implicitContentWidth
                Layout.alignment: Qt.AlignTop
                enabled: accuracyIndicator.checked
                visible: accuracyIndicator.checked
                checked: positioningSettings.accuracyRequirement
                onCheckedChanged: {
                  positioningSettings.accuracyRequirement = checked;
                }
              }

              Label {
                text: qsTr("Con el indicador activado, se muestra un distintivo de color <span %1>rojo</span> si la precisión es peor que <i>mala</i>, <span %2>amarillo</span> si no alcanza <i>excelente</i>, o <span %3>verde</span>.<br><br>El modo de restricción limita agregar vértices con precisión peor que el umbral malo.").arg("style='%1'".arg(Theme.toInlineStyles({
                        "color": Theme.accuracyBad
                      }))).arg("style='%1'".arg(Theme.toInlineStyles({
                        "color": Theme.accuracyTolerated
                      }))).arg("style='%1'".arg(Theme.toInlineStyles({
                        "color": Theme.accuracyExcellent
                      })))
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }

              Item {
                // empty cell in grid layout
                width: 1
              }

              Label {
                text: qsTr("Activar requisito de posición promediada")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true

                MouseArea {
                  anchors.fill: parent
                  onClicked: averagedPositioning.toggle()
                }
              }

              QfSwitch {
                id: averagedPositioning
                Layout.preferredWidth: implicitContentWidth
                Layout.alignment: Qt.AlignTop
                checked: positioningSettings.averagedPositioning
                onCheckedChanged: {
                  positioningSettings.averagedPositioning = checked;
                }
              }

              Label {
                text: qsTr("Número mínimo de posiciones")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                enabled: averagedPositioning.checked
                visible: averagedPositioning.checked
                Layout.leftMargin: 8
              }

              QfTextField {
                id: averagedPositioningMinimumCount
                width: averagedPositioning.width
                font: Theme.defaultFont
                enabled: averagedPositioning.checked
                visible: averagedPositioning.checked
                horizontalAlignment: TextInput.AlignHCenter
                Layout.preferredWidth: 60
                Layout.preferredHeight: font.height + 20

                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: IntValidator {
                  locale: 'C'
                }

                Component.onCompleted: {
                  text = isNaN(positioningSettings.averagedPositioningMinimumCount) ? '' : positioningSettings.averagedPositioningMinimumCount;
                }

                onTextChanged: {
                  if (text.length === 0 || isNaN(text)) {
                    positioningSettings.averagedPositioningMinimumCount = NaN;
                  } else {
                    positioningSettings.averagedPositioningMinimumCount = parseInt(text);
                  }
                }
              }

              Label {
                text: qsTr("Finalizar automáticamente al alcanzar mínimo")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                enabled: averagedPositioning.checked
                visible: averagedPositioning.checked
                Layout.leftMargin: 8

                MouseArea {
                  anchors.fill: parent
                  onClicked: averagedPositioningAutomaticEnd.toggle()
                }
              }

              QfSwitch {
                id: averagedPositioningAutomaticEnd
                Layout.preferredWidth: implicitContentWidth
                Layout.alignment: Qt.AlignTop
                enabled: averagedPositioning.checked
                visible: averagedPositioning.checked
                checked: positioningSettings.averagedPositioningAutomaticStop
                onCheckedChanged: {
                  positioningSettings.averagedPositioningAutomaticStop = checked;
                }
              }

              Label {
                text: qsTr("Con posición promediada, al digitalizar vértices solo se aceptará un promedio de posiciones recolectadas. Mantenga presionado el botón para recolectar posiciones.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }

              Item {
                // empty cell in grid layout
                width: 1
              }

              Label {
                text: qsTr("Compensación de altura de antena")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true

                MouseArea {
                  anchors.fill: parent
                  onClicked: antennaHeightActivated.toggle()
                }
              }

              QfSwitch {
                id: antennaHeightActivated
                Layout.preferredWidth: implicitContentWidth
                Layout.alignment: Qt.AlignTop
                checked: positioningSettings.antennaHeightActivated
                onCheckedChanged: {
                  positioningSettings.antennaHeightActivated = checked;
                }
              }

              Label {
                text: qsTr("Altura de antena [m]")
                enabled: antennaHeightActivated.checked
                visible: antennaHeightActivated.checked
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                textFormat: Text.RichText
                Layout.leftMargin: 8
              }

              QfTextField {
                id: antennaHeightInput
                enabled: antennaHeightActivated.checked
                visible: antennaHeightActivated.checked
                width: antennaHeightActivated.width
                font: Theme.defaultFont
                horizontalAlignment: TextInput.AlignHCenter
                Layout.preferredWidth: 60
                Layout.preferredHeight: font.height + 20

                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator {
                  locale: 'C'
                }

                Component.onCompleted: {
                  text = isNaN(positioningSettings.antennaHeight) ? '' : positioningSettings.antennaHeight;
                }

                onTextChanged: {
                  if (text.length === 0 || isNaN(text)) {
                    positioningSettings.antennaHeight = NaN;
                  } else {
                    positioningSettings.antennaHeight = parseFloat(text);
                  }
                }
              }

              Label {
                text: qsTr("Este valor corregirá las alturas registradas. Si se ingresa 1.6, se restará automáticamente de cada valor registrado. Considere longitud del poste + offset del centro de fase.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor

                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }

              Item {
                // empty cell in grid layout
                width: 1
              }

              Label {
                text: qsTr("Omitir corrección de altitud")
                font: Theme.defaultFont
                color: Theme.mainTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true

                MouseArea {
                  anchors.fill: parent
                  onClicked: skipAltitudeCorrectionSwitch.toggle()
                }
              }

              QfSwitch {
                id: skipAltitudeCorrectionSwitch
                Layout.preferredWidth: implicitContentWidth
                Layout.alignment: Qt.AlignTop
                checked: positioningSettings.skipAltitudeCorrection
                onCheckedChanged: {
                  positioningSettings.skipAltitudeCorrection = checked;
                }
              }

              Label {
                topPadding: 0
                text: qsTr("Usar la altitud reportada por el dispositivo. Omite cualquier corrección implícita en la transformación de coordenadas.")
                font: Theme.tipFont
                color: Theme.secondaryTextColor

                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }

              Item {
                // empty cell in grid layout
                width: 1
              }

              Label {
                text: qsTr("Cambio de cuadrícula vertical en uso:")
                font: Theme.defaultFont
                color: Theme.mainTextColor

                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.columnSpan: 2
              }

              ComboBox {
                id: verticalGridShiftComboBox
                Layout.fillWidth: true
                Layout.columnSpan: 2
                font: Theme.defaultFont

                popup.font: Theme.defaultFont
                popup.topMargin: mainWindow.sceneTopMargin
                popup.bottomMargin: mainWindow.sceneTopMargin

                textRole: "text"
                valueRole: "value"

                model: ListModel {
                  id: verticalGridShiftModel
                }

                onCurrentValueChanged: {
                  if (reloading || currentValue == undefined) {
                    return;
                  }
                  positioningSettings.elevationCorrectionMode = currentValue;
                  if (positioningSettings.elevationCorrectionMode === Positioning.ElevationCorrectionMode.OrthometricFromGeoidFile) {
                    positioningSettings.verticalGrid = currentText;
                  } else {
                    positioningSettings.verticalGrid = "";
                  }
                }

                Component.onCompleted: reload()

                property bool reloading: false
                function reload() {
                  reloading = true;
                  verticalGridShiftComboBox.model.clear();
                  verticalGridShiftComboBox.model.append({
                      "text": qsTr("Ninguno"),
                      "value": Positioning.ElevationCorrectionMode.None
                    });
                  if (positionSource.deviceCapabilities & AbstractGnssReceiver.OrthometricAltitude)
                    verticalGridShiftComboBox.model.append({
                        "text": qsTr("Ortométrica desde dispositivo"),
                        "value": Positioning.ElevationCorrectionMode.OrthometricFromDevice
                      });

                  // Add geoid files to combobox
                  var geoidFiles = platformUtilities.availableGrids();
                  for (var i = 0; i < geoidFiles.length; i++)
                    verticalGridShiftComboBox.model.append({
                        "text": geoidFiles[i],
                        "value": Positioning.ElevationCorrectionMode.OrthometricFromGeoidFile
                      });
                  if (positioningSettings.elevationCorrectionMode === Positioning.ElevationCorrectionMode.None) {
                    verticalGridShiftComboBox.currentIndex = indexOfValue(positioningSettings.elevationCorrectionMode);
                    positioningSettings.verticalGrid = "";
                  } else if (positioningSettings.elevationCorrectionMode === Positioning.ElevationCorrectionMode.OrthometricFromDevice) {
                    if (positionSource.deviceCapabilities & AbstractGnssReceiver.OrthometricAltitude)
                      verticalGridShiftComboBox.currentIndex = verticalGridShiftComboBox.indexOfValue(positioningSettings.elevationCorrectionMode);
                    else
                      // Orthometric not available -> fallback to None
                      verticalGridShiftComboBox.currentIndex = verticalGridShiftComboBox.indexOfValue(Positioning.ElevationCorrectionMode.None);
                    positioningSettings.verticalGrid = "";
                  } else if (positioningSettings.elevationCorrectionMode === Positioning.ElevationCorrectionMode.OrthometricFromGeoidFile) {
                    var currentVerticalGridFileIndex = verticalGridShiftComboBox.find(positioningSettings.verticalGrid);
                    if (currentVerticalGridFileIndex < 1)
                      // Vertical index file not found -> fallback to None
                      verticalGridShiftComboBox.currentIndex = verticalGridShiftComboBox.indexOfValue(Positioning.ElevationCorrectionMode.None);
                    else
                      verticalGridShiftComboBox.currentIndex = currentVerticalGridFileIndex;
                  } else {
                    console.log("Warning unknown elevationCorrectionMode: '%1'".arg(positioningSettings.elevationCorrectionMode));

                    // Unknown mode -> fallback to None
                    verticalGridShiftComboBox.currentIndex = verticalGridShiftComboBox.indexOfValue(Positioning.ElevationCorrectionMode.None);
                  }
                  reloading = false;
                }
              }
            }

            Label {
              topPadding: 0
              rightPadding: antennaHeightActivated.width
              text: qsTr("El cambio de cuadrícula vertical se usa para aumentar la precisión de altitud.")
              font: Theme.tipFont
              color: Theme.secondaryTextColor

              wrapMode: Text.WordWrap
              Layout.fillWidth: true
              Layout.columnSpan: 2
            }

            Label {
              text: qsTr("Registrar sentencias NMEA en archivo")
              font: Theme.defaultFont
              color: Theme.mainTextColor
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
              visible: positionSource.deviceCapabilities & AbstractGnssReceiver.Logging

              MouseArea {
                anchors.fill: parent
                onClicked: positionLogging.toggle()
              }
            }

            QfSwitch {
              id: positionLogging
              Layout.preferredWidth: implicitContentWidth
              Layout.alignment: Qt.AlignTop
              visible: positionSource.deviceCapabilities & AbstractGnssReceiver.Logging
              checked: positioningSettings.logging
              onCheckedChanged: {
                positioningSettings.logging = checked;
              }
            }

            Item {
              // spacer item
              Layout.fillWidth: true
              Layout.fillHeight: true
              Layout.minimumHeight: mainWindow.sceneBottomMargin + 20
            }
          }
        }
      }

      Item {
        VariableEditor {
          id: variableEditor
          anchors.fill: parent
          anchors.margins: 4
          anchors.bottomMargin: 4 + mainWindow.sceneBottomMargin
        }
      }
    }
  }

  PositioningDeviceSettings {
    id: positioningDeviceSettings

    property string originalName: ''

    onApply: {
      if (originalName != '') {
        positioningDeviceModel.removeDevice(originalName);
      }
      var name = positioningDeviceSettings.name;
      var type = positioningDeviceSettings.type;
      var settings = positioningDeviceSettings.getSettings();
      if (name === '') {
        name = positioningDeviceSettings.generateName();
      }
      var index = positioningDeviceModel.addDevice(type, name, settings);
      positioningDeviceComboBox.currentIndex = index;
      positioningDeviceComboBox.onCurrentIndexChanged();
    }
  }

  header: Rectangle {
    color: Theme.mainColor
    height: 50
    
    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      
      Label {
        text: qsTr("Configuraciones")
        font: Theme.strongFont
        color: Theme.light
        Layout.fillWidth: true
      }
      
      ToolButton {
        text: qsTr("Close")
        font: Theme.defaultFont
        onClicked: finished()
        contentItem: Text {
          text: parent.text
          font: parent.font
          color: Theme.light
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }
    }
  }

  Keys.onReleased: event => {
    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
      event.accepted = true;
      variableEditor.apply();
      finished();
    }
  }
}


