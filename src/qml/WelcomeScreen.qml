import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material.impl
import QtQuick.Layouts
import QtQuick.Particles
import QtCore
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Page {
  id: welcomeScreen

  property bool firstShown: false

  property alias model: table.model
  signal openLocalDataPicker
  signal showQFieldCloudScreen
  signal showSettings

  visible: false
  focus: visible

  Settings {
    id: registry
    category: 'QField'

    property string baseMapProject: ''
    property string defaultProject: ''
    property bool loadProjectOnLaunch: false
  }

  Rectangle {
    id: welcomeBackground
    anchors.fill: parent
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: Theme.darkTheme ? "#37474F" : "#E3F2FD"
      }
      GradientStop {
        position: 0.50
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
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        Layout.preferredWidth: Math.min(150, mainWindow.height / 3)
        Layout.preferredHeight: Math.min(150, mainWindow.height / 3)

        source: "qrc:/images/sigpacgo_logo.svg"
        rotationOffset: 220
      }

      
      Text {
        id: welcomeText
        visible: !feedbackView.visible
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

          QfButton {
            id: cloudProjectButton
            Layout.fillWidth: true
            text: qsTr("QFieldCloud projects")
            onClicked: {
              showQFieldCloudScreen();
            }
          }
          QfButton {
            id: localProjectButton
            Layout.fillWidth: true
            text: qsTr("Open local file")
            onClicked: {
              platformUtilities.requestStoragePermission();
              openLocalDataPicker();
            }
          }

          Text {
            id: recentText
            text: qsTr("Recent Projects")
            font.pointSize: Theme.tipFont.pointSize
            font.bold: true
            color: Theme.mainTextColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: table.height
            color: "transparent"
            border.color: "transparent"
            border.width: 1

            ListView {
              id: table
              ScrollBar.vertical: QfScrollBar {
              }
              flickableDirection: Flickable.AutoFlickIfNeeded
              boundsBehavior: Flickable.StopAtBounds
              clip: true
              width: parent.width
              height: contentItem.childrenRect.height

              delegate: Rectangle {
                id: rectangle
                objectName: "loadProjectItem_1" // todo, suffix with e.g. ProjectTitle

                property bool isPressed: false
                property string path: ProjectPath
                property string title: ProjectTitle
                property var type: ProjectType

                width: parent ? parent.width : undefined
                height: line.height + 8
                color: "transparent"

                Rectangle {
                  id: lineMask
                  width: line.width
                  height: line.height
                  radius: 10
                  color: "white"
                  visible: false
                  layer.enabled: true
                }

                Rectangle {
                  id: line
                  width: parent.width
                  height: previewImage.status === Image.Ready ? 120 : detailsContainer.height
                  anchors.verticalCenter: parent.verticalCenter
                  color: "transparent"
                  clip: true

                  layer.enabled: true
                  layer.effect: QfOpacityMask {
                    maskSource: lineMask
                  }

                  Image {
                    id: previewImage
                    width: parent.width
                    height: parent.height
                    source: welcomeScreen.visible ? 'image://projects/' + ProjectPath : ''
                    fillMode: Image.PreserveAspectCrop
                  }

                  Ripple {
                    clip: true
                    width: line.width
                    height: line.height
                    pressed: rectangle.isPressed
                    active: rectangle.isPressed
                    color: Qt.hsla(Theme.mainColor.hslHue, Theme.mainColor.hslSaturation, Theme.mainColor.hslLightness, 0.15)
                  }

                  Rectangle {
                    id: detailsContainer
                    color: Qt.hsla(Theme.mainBackgroundColor.hslHue, Theme.mainBackgroundColor.hslSaturation, Theme.mainBackgroundColor.hslLightness, Theme.darkTheme ? 0.75 : 0.9)
                    width: parent.width
                    height: details.childrenRect.height + details.topPadding + details.bottomPadding
                    anchors.bottom: parent.bottom

                    RowLayout {
                      id: details
                      width: parent.width
                      topPadding: 4
                      bottomPadding: 4
                      spacing: 0
                      Layout.alignment: Qt.AlignHCenter

                      Image {
                        Layout.alignment: Qt.AlignVCenter
                        id: type
                        anchors.verticalCenter: parent.verticalCenter
                        source: switch (ProjectType) {
                        case 0:
                          return Theme.getThemeVectorIcon('ic_map_green_48dp');     // local project
                        case 1:
                          return Theme.getThemeVectorIcon('ic_cloud_project_48dp'); // cloud project
                        case 2:
                          return Theme.getThemeVectorIcon('ic_file_green_48dp');    // local dataset
                        default:
                          return '';
                        }
                        sourceSize.width: 80
                        sourceSize.height: 80
                        width: 40
                        height: 60
                      }
                      ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        id: inner
                        anchors.verticalCenter: parent.verticalCenter
                        width: rectangle.width - type.width - 20
                        spacing: 2
                        clip: true

                        Text {
                          id: projectTitle
                          topPadding: 4
                          leftPadding: 3
                          bottomPadding: projectNote.visible ? 0 : 5
                          text: ProjectTitle
                          font.pointSize: Theme.tipFont.pointSize
                          font.underline: true
                          color: Theme.mainColor
                          opacity: rectangle.isPressed ? 0.8 : 1
                          wrapMode: Text.WordWrap
                          Layout.fillWidth: true
                        }
                        Text {
                          id: projectNote
                          leftPadding: 3
                          bottomPadding: 4
                          text: {
                            var notes = [];
                            if (index == 0) {
                              var firstRun = settings && !settings.value("/QField/FirstRunFlag", false);
                              if (!firstRun && firstShown === false)
                                notes.push(qsTr("Last session"));
                            }
                            if (ProjectPath === registry.defaultProject) {
                              notes.push(qsTr("Default project"));
                            }
                            if (ProjectPath === registry.baseMapProject) {
                              notes.push(qsTr("Base map"));
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
                          wrapMode: Text.WordWrap
                          Layout.fillWidth: true
                        }
                      }
                    }
                  }
                }
              }

              MouseArea {
                property Item pressedItem
                anchors.fill: parent
                onClicked: mouse => {
                  var item = table.itemAt(mouse.x, mouse.y);
                  if (item) {
                    if (item.type == 1 && cloudConnection.hasToken && cloudConnection.status !== QFieldCloudConnection.LoggedIn) {
                      cloudConnection.login();
                    }
                    iface.loadFile(item.path, item.title);
                  }
                }
                onPressed: mouse => {
                  var item = table.itemAt(mouse.x, mouse.y);
                  if (item) {
                    pressedItem = item;
                    pressedItem.isPressed = true;
                  }
                }
                onCanceled: {
                  if (pressedItem) {
                    pressedItem.isPressed = false;
                    pressedItem = null;
                  }
                }
                onReleased: {
                  if (pressedItem) {
                    pressedItem.isPressed = false;
                    pressedItem = null;
                  }
                }
                onPressAndHold: mouse => {
                  var item = table.itemAt(mouse.x, mouse.y);
                  if (item) {
                    recentProjectActions.recentProjectPath = item.path;
                    recentProjectActions.recentProjectType = item.type;
                    recentProjectActions.popup(mouse.x, mouse.y);
                  }
                }
              }

              Menu {
                id: recentProjectActions

                property string recentProjectPath: ''
                property int recentProjectType: 0

                title: qsTr('Recent Project Actions')

                width: {
                  let result = 50;
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
                  visible: recentProjectActions.recentProjectType != 2

                  font: Theme.defaultFont
                  width: parent.width
                  height: visible ? 48 : 0
                  leftPadding: Theme.menuItemCheckLeftPadding
                  checkable: true
                  checked: recentProjectActions.recentProjectPath === registry.defaultProject

                  text: qsTr("Default Project")
                  onTriggered: {
                    registry.defaultProject = recentProjectActions.recentProjectPath === registry.defaultProject ? '' : recentProjectActions.recentProjectPath;
                  }
                }

                MenuItem {
                  id: baseMapProject
                  visible: recentProjectActions.recentProjectType != 2

                  font: Theme.defaultFont
                  width: parent.width
                  height: visible ? 48 : 0
                  leftPadding: Theme.menuItemCheckLeftPadding
                  checkable: true
                  checked: recentProjectActions.recentProjectPath === registry.baseMapProject

                  text: qsTr("Individual Datasets Base Map")
                  onTriggered: {
                    registry.baseMapProject = recentProjectActions.recentProjectPath === registry.baseMapProject ? '' : recentProjectActions.recentProjectPath;
                  }
                }

                MenuSeparator {
                  visible: baseMapProject.visible
                  width: parent.width
                  height: visible ? undefined : 0
                }

                MenuItem {
                  id: removeProject

                  font: Theme.defaultFont
                  width: parent.width
                  height: visible ? 48 : 0
                  leftPadding: Theme.menuItemIconlessLeftPadding

                  text: qsTr("Remove from Recent Projects")
                  onTriggered: {
                    iface.removeRecentProject(recentProjectActions.recentProjectPath);
                    model.reloadModel();
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: mainWindow.sceneBottomMargin
            Label {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              topPadding: 10
              bottomPadding: 10
              font: Theme.tipFont
              wrapMode: Text.WordWrap
              color: reloadOnLaunch.checked ? Theme.mainTextColor : Theme.secondaryTextColor

              text: registry.defaultProject != '' ? qsTr('Load default project on launch') : qsTr('Load last opened project on launch')

              MouseArea {
                anchors.fill: parent
                onClicked: reloadOnLaunch.checked = !reloadOnLaunch.checked
              }
            }

            QfSwitch {
              id: reloadOnLaunch
              Layout.preferredWidth: implicitContentWidth
              Layout.alignment: Qt.AlignVCenter
              width: implicitContentWidth
              small: true

              checked: registry.loadProjectOnLaunch
              onCheckedChanged: {
                registry.loadProjectOnLaunch = checked;
              }
            }
          }
        }
      }
    }
  }

  Column {
    id: topButtons
    spacing: 4
    anchors {
      top: parent.top
      left: parent.left
      topMargin: mainWindow.sceneTopMargin + 4
      leftMargin: 4
    }

    QfToolButton {
      id: currentProjectButton
      toolImage: Theme.getThemeVectorIcon('ic_arrow_left_white_24dp')
      toolText: welcomeScreen.width > 420 ? qsTr('Return to map') : ""
      visible: qgisProject && !!qgisProject.homePath
      innerActionIcon.visible: false

      onClicked: {
        welcomeScreen.visible = false;
      }
    }

    QfActionButton {
      id: settingsButton
      iconSource: Theme.getThemeVectorIcon('ic_tune_white_24dp')
      toolImage: Theme.getThemeVectorIcon('ic_tune_white_24dp')
      toolText: ""
      toolTextVisible: false
      innerActionIcon.visible: true

      onClicked: {
        showSettings();
      }
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
    iconColor: Theme.toolButtonColor
    bgcolor: Theme.toolButtonBackgroundColor
    round: true

    onClicked: {
      mainWindow.closeAlreadyRequested = true;
      mainWindow.close();
    }
    Connections {
      target: Theme
      onThemeChanged: {
        iconColor = Theme.toolButtonColor;
        bgcolor = Theme.toolButtonBackgroundColor;
        round = false;
      }
    }
  }


    function adjustWelcomeScreen() {
    if (visible) {
      if (firstShown) {
        welcomeText.text = " ";
      } else {
        var firstRun = !settings.valueBool("/QField/FirstRunDone", false);
        if (firstRun) {
          welcomeText.text = qsTr("Welcome to SIGOPAC-Go");
          settings.setValue("/QField/FirstRunDone", true);
          settings.setValue("/QField/showMapCanvasGuide", true);
        } else {
          welcomeText.text = qsTr("SIGPAC-Go SIG para el campo");
        }
      }
    }
  }

  
  Keys.onReleased: event => {
    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
      if (qgisProject.fileName != '') {
        event.accepted = true;
        visible = false;
      } else {
        event.accepted = false;
      }
    }
  }
}
