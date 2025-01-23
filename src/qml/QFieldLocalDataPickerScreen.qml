import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Page {
  id: qfieldLocalDataPickerScreen

  property bool openedOnce: false
  property bool projectFolderView: false
  property alias model: table.model

  signal finished(var loading)

  focus: visible

  onVisibleChanged: {
    if (visible) {
      openedOnce = true;
    }
  }

  header: QfPageHeader {
    title: projectFolderView ? qsTr("Project Folder") : qsTr("Local Projects & Datasets")

    showBackButton: true
    showApplyButton: false
    showCancelButton: false

    topMargin: mainWindow.sceneTopMargin

    onBack: {
      if (table.model.currentDepth > 1) {
        table.model.moveUp();
      } else {
        parent.finished(false);
      }
    }
  }

  ColumnLayout {
    id: files
    anchors.fill: parent
    spacing: 2

    RowLayout {
      Layout.margins: 10
      spacing: 2

      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        Text {
          Layout.fillWidth: true
          text: table.model.currentTitle
          font.pointSize: Theme.defaultFont.pointSize
          font.bold: true
          color: Theme.mainTextColor
          wrapMode: Text.NoWrap
          elide: Text.ElideMiddle
        }
        Text {
          Layout.fillWidth: true
          visible: text !== ''
          text: table.model.currentPath !== 'root' ? table.model.currentPath : ''
          font: Theme.tipFont
          color: Theme.mainTextColor
          wrapMode: Text.NoWrap
          elide: Text.ElideMiddle
          opacity: 0.35
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.margins: 10
      Layout.topMargin: 0
      Layout.bottomMargin: 10 + mainWindow.sceneBottomMargin
      color: Theme.controlBackgroundColor
      border.color: Theme.controlBorderColor
      border.width: 1

      ListView {
        id: table

        model: LocalFilesModel {
          id: localFilesModel
        }

        anchors.fill: parent
        anchors.margins: 1

        clip: true

        section.property: "ItemMetaType"
        section.labelPositioning: ViewSection.CurrentLabelAtStart | ViewSection.InlineLabels
        section.delegate: Component {
          Rectangle {
            width: parent.width
            height: 30
            color: Theme.controlBorderColor

            Text {
              anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
              }
              font.bold: true
              font.pointSize: Theme.resultFont.pointSize
              color: Theme.mainTextColor
              text: {
                switch (parseInt(section)) {
                case LocalFilesModel.Folder:
                  return qsTr('Folders');
                case LocalFilesModel.Project:
                  return qsTr('Projects');
                case LocalFilesModel.Dataset:
                  return qsTr('Datasets');
                case LocalFilesModel.File:
                  return qsTr('Files');
                case LocalFilesModel.Favorite:
                  return qsTr('Favorites');
                }
                return '';
              }
            }
          }
        }

        delegate: Rectangle {
          id: rectangle

          property int itemMetaType: ItemMetaType
          property int itemType: ItemType
          property string itemTitle: ItemTitle
          property string itemPath: ItemPath
          property bool itemIsFavorite: ItemIsFavorite
          property bool itemMenuLoadable: !projectFolderView && (ItemMetaType === LocalFilesModel.Project || ItemMetaType === LocalFilesModel.Dataset)
          property bool itemMenuVisible: ((ItemType === LocalFilesModel.SimpleFolder || ItemMetaType == LocalFilesModel.File) && table.model.currentPath !== 'root') || ((platformUtilities.capabilities & PlatformUtilities.CustomExport || platformUtilities.capabilities & PlatformUtilities.CustomSend) && (ItemMetaType === LocalFilesModel.Dataset)) || (ItemMetaType === LocalFilesModel.Dataset && ItemType === LocalFilesModel.RasterDataset && cloudProjectsModel.currentProjectId)

          width: parent ? parent.width : undefined
          height: line.height
          color: "transparent"

          RowLayout {
            id: line
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Image {
              id: type
              Layout.alignment: Qt.AlignVCenter
              Layout.topMargin: 5
              Layout.bottomMargin: 5
              Layout.leftMargin: 4
              Layout.preferredWidth: 48
              Layout.preferredHeight: 48
              asynchronous: true
              source: {
                if (ItemHasThumbnail) {
                  return "image://localfiles/" + ItemPath;
                } else {
                  switch (ItemType) {
                  case LocalFilesModel.ApplicationFolder:
                    return Theme.getThemeVectorIcon('ic_folder_qfield_gray_48dp');
                  case LocalFilesModel.ExternalStorage:
                    return Theme.getThemeVectorIcon('ic_sd_card_gray_48dp');
                  case LocalFilesModel.SimpleFolder:
                    return Theme.getThemeVectorIcon(ItemMetaType == LocalFilesModel.Folder && ItemIsFavorite ? 'ic_folder_favorite_gray_48dp' : 'ic_folder_gray_48dp');
                  case LocalFilesModel.ProjectFile:
                    return Theme.getThemeVectorIcon('ic_map_green_48dp');
                  case LocalFilesModel.VectorDataset:
                  case LocalFilesModel.RasterDataset:
                  case LocalFilesModel.OtherFile:
                    return Theme.getThemeVectorIcon('ic_file_green_48dp');
                  }
                }
              }
              sourceSize.width: 92
              sourceSize.height: 92
              fillMode: Image.PreserveAspectFit
              width: 48
              height: 48
            }
            ColumnLayout {
              id: inner
              Layout.alignment: Qt.AlignVCenter
              Layout.fillWidth: true
              Layout.preferredHeight: childrenRect.height
              Layout.topMargin: 5
              Layout.bottomMargin: 5
              Layout.leftMargin: 2
              Layout.rightMargin: 4
              spacing: 1
              Text {
                id: itemTitle
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                clip: true

                text: ItemTitle + (ItemType !== LocalFilesModel.ProjectFile && ItemFormat !== '' ? '.' + ItemFormat : '')

                font.pointSize: Theme.defaultFont.pointSize
                font.underline: itemMenuLoadable
                color: itemMenuLoadable ? Theme.mainColor : Theme.mainTextColor
                wrapMode: Text.WordWrap
              }
              Text {
                id: itemInfo
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight

                text: {
                  var info = '';
                  switch (ItemType) {
                  case LocalFilesModel.ProjectFile:
                    info = qsTr('Project file');
                    break;
                  case LocalFilesModel.VectorDataset:
                    info = qsTr('Vector dataset') + ' (' + FileUtils.representFileSize(ItemSize) + ')';
                    break;
                  case LocalFilesModel.RasterDataset:
                    info = qsTr('Raster dataset') + ' (' + FileUtils.representFileSize(ItemSize) + ')';
                    break;
                  }
                  return info;
                }

                visible: text != ""
                font.pointSize: Theme.tipFont.pointSize - 2
                font.italic: true
                color: Theme.secondaryTextColor
                wrapMode: Text.WordWrap
                opacity: 0.35
              }
            }
            QfToolButton {
              visible: itemMenuVisible
              round: true
              opacity: 0.5

              Layout.topMargin: 5
              Layout.bottomMargin: 5

              bgcolor: "transparent"
              iconSource: Theme.getThemeVectorIcon("ic_dot_menu_black_24dp")
              iconColor: Theme.mainTextColor

              onClicked: {
                var gc = mapToItem(qfieldLocalDataPickerScreen, 0, 0);
                itemMenu.itemMetaType = ItemMetaType;
                itemMenu.itemType = ItemType;
                itemMenu.itemPath = ItemPath;
                itemMenu.itemIsFavorite = ItemIsFavorite;
                itemMenu.itemHasWebdavConfiguration = ItemHasWebdavConfiguration;
                itemMenu.popup(gc.x + width - itemMenu.width, gc.y - height);
              }
            }
          }
        }

        MouseArea {
          property Item pressedItem
          anchors.fill: parent
          anchors.rightMargin: 48
          onClicked: mouse => {
            if (itemMenu.visible) {
              itemMenu.close();
            } else if (importMenu.visible) {
              importMenu.close();
            } else {
              var item = table.itemAt(table.contentX + mouse.x, table.contentY + mouse.y);
              if (item) {
                if (item.itemMetaType === LocalFilesModel.Folder || item.itemMetaType === LocalFilesModel.Favorite) {
                  table.model.currentPath = item.itemPath;
                } else if (!qfieldLocalDataPickerScreen.projectFolderView && (item.itemMetaType === LocalFilesModel.Project || item.itemMetaType === LocalFilesModel.Dataset)) {
                  iface.loadFile(item.itemPath, item.itemTitle);
                  finished(true);
                }
              }
            }
          }
          onPressed: mouse => {
            if (itemMenu.visible || importMenu.visible)
              return;
            var item = table.itemAt(table.contentX + mouse.x, table.contentY + mouse.y);
            if (item && item.itemMenuLoadable) {
              pressedItem = item.children[0].children[1].children[0];
              pressedItem.color = "#5a8725";
            }
          }
          onCanceled: {
            if (pressedItem) {
              pressedItem.color = Theme.mainColor;
              pressedItem = null;
            }
          }
          onReleased: {
            if (pressedItem) {
              pressedItem.color = Theme.mainColor;
              pressedItem = null;
            }
          }

          onPressAndHold: mouse => {
            var item = table.itemAt(table.contentX + mouse.x, table.contentY + mouse.y);
            if (item && item.itemMenuVisible) {
              itemMenu.itemMetaType = item.itemMetaType;
              itemMenu.itemType = item.itemType;
              itemMenu.itemPath = item.itemPath;
              itemMenu.itemIsFavorite = item.itemIsFavorite;
              itemMenu.popup(mouse.x, mouse.y);
            }
          }
        }
      }

      Connections {
        target: nativeLocalDataPickerButton.__projectSource

        function onProjectOpened(path) {
          finished(true);
          iface.loadFile(path);
        }
      }

      QfToolButton {
        id: nativeLocalDataPickerButton
        round: true

        property ProjectSource __projectSource

        visible: platformUtilities.capabilities & PlatformUtilities.NativeLocalDataPicker && table.model.currentPath === 'root'

        anchors.bottom: actionButton.top
        anchors.right: parent.right
        anchors.bottomMargin: 4
        anchors.rightMargin: 10

        bgcolor: Theme.mainColor
        iconSource: Theme.getThemeVectorIcon("ic_open_black_24dp")
        iconColor: Theme.toolButtonColor

        onClicked: {
          __projectSource = platformUtilities.openProject(this);
        }
      }

      QfToolButton {
        id: actionButton
        round: true

        // Since the project menu only has one action for now, hide if PlatformUtilities.UpdateProjectFromArchive is missing
        property bool isLocalProject: qgisProject && QFieldCloudUtils.getProjectId(qgisProject.fileName) === '' && (projectInfo.filePath.endsWith('.qgs') || projectInfo.filePath.endsWith('.qgz'))
        property bool isLocalProjectActionAvailable: updateProjectFromArchive.enabled || uploadProjectToWebdav.enabled
        visible: (projectFolderView && isLocalProject && table.model.currentDepth === 1) || table.model.currentPath === 'root'

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 10

        bgcolor: Theme.mainColor
        iconSource: Theme.getThemeVectorIcon("ic_add_white_24dp")
        iconColor: Theme.toolButtonColor

        onClicked: {
          var xy = mapToItem(mainWindow.contentItem, actionButton.width, actionButton.height);
          if (projectFolderView) {
            projectMenu.popup(xy.x - projectMenu.width, xy.y - projectMenu.height - header.height);
          } else {
            importMenu.popup(xy.x - importMenu.width, xy.y - importMenu.height - header.height);
          }
        }
      }
    }

    Menu {
      id: itemMenu

      property int itemMetaType: 0
      property int itemType: 0
      property string itemPath: ''
      property bool itemIsFavorite: false
      property bool itemHasWebdavConfiguration: false

      title: qsTr('Item Actions')

      width: {
        let result = 50;
        let padding = 0;
        for (let i = 0; i < count; ++i) {
          let item = itemAt(i);
          result = Math.max(item.contentItem.implicitWidth, result);
          padding = Math.max(item.leftPadding + item.rightPadding, padding);
        }
        return mainWindow.width > 0 ? Math.min(result + padding * 2, mainWindow.width - 20) : result + padding;
      }

      topMargin: sceneTopMargin
      bottomMargin: sceneBottomMargin

      // File items
      MenuItem {
        id: sendDatasetTo
        enabled: itemMenu.itemMetaType === LocalFilesModel.File || (platformUtilities.capabilities & PlatformUtilities.CustomSend && itemMenu.itemMetaType == LocalFilesModel.Dataset)
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Send to...")
        onTriggered: {
          platformUtilities.sendDatasetTo(itemMenu.itemPath);
        }
      }

      MenuItem {
        id: pushDatasetToCloud
        enabled: itemMenu.itemMetaType == LocalFilesModel.Dataset && itemMenu.itemType == LocalFilesModel.RasterDataset && cloudProjectsModel.currentProjectId
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Push to QFieldCloud")
        onTriggered: {
          QFieldCloudUtils.addPendingAttachment(cloudProjectsModel.currentProjectId, itemMenu.itemPath);
          platformUtilities.uploadPendingAttachments(cloudConnection);
          displayToast(qsTr("‘%1’ is being uploaded to QFieldCloud").arg(FileUtils.fileName(itemMenu.itemPath)));
        }
      }

      MenuItem {
        id: exportDatasetTo
        enabled: platformUtilities.capabilities & PlatformUtilities.CustomExport && itemMenu.itemMetaType == LocalFilesModel.Dataset
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Export to folder...")
        onTriggered: {
          platformUtilities.exportDatasetTo(itemMenu.itemPath);
        }
      }

      // Folder items
      MenuItem {
        id: toggleFavoriteState
        enabled: itemMenu.itemMetaType == LocalFilesModel.Folder && localFilesModel.isPathFavoriteEditable(itemMenu.itemPath)
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: !itemMenu.itemIsFavorite ? qsTr("Add to favorites") : qsTr("Remove from favorites")
        onTriggered: {
          if (!itemMenu.itemIsFavorite) {
            localFilesModel.addToFavorites(itemMenu.itemPath);
          } else {
            localFilesModel.removeFromFavorites(itemMenu.itemPath);
          }
        }
      }

      MenuSeparator {
        enabled: toggleFavoriteState.visible
        visible: enabled
        width: parent.width
        height: enabled ? undefined : 0
      }

      MenuItem {
        id: exportFolderTo
        enabled: platformUtilities.capabilities & PlatformUtilities.CustomExport && itemMenu.itemMetaType == LocalFilesModel.Folder
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Export to folder...")
        onTriggered: {
          platformUtilities.exportFolderTo(itemMenu.itemPath);
        }
      }

      MenuItem {
        id: sendCompressedFolderTo
        enabled: platformUtilities.capabilities & PlatformUtilities.CustomSend && itemMenu.itemMetaType == LocalFilesModel.Folder
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Send compressed folder to...")
        onTriggered: {
          platformUtilities.sendCompressedFolderTo(itemMenu.itemPath);
        }
      }

      MenuItem {
        id: uploadFolderToWebdav
        enabled: itemMenu.itemHasWebdavConfiguration
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Upload folder to WebDAV server")
        onTriggered: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.uploadPath(itemMenu.itemPath);
          }
        }
      }

      MenuItem {
        id: downloadFolderFromWebdav
        enabled: itemMenu.itemHasWebdavConfiguration
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Download folder from WebDAV server")
        onTriggered: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.downloadPath(itemMenu.itemPath);
          }
        }
      }

      MenuSeparator {
        enabled: removeProjectFolder.visible
        visible: enabled
        width: parent.width
        height: enabled ? undefined : 0
      }

      MenuItem {
        id: removeDataset
        enabled: itemMenu.itemMetaType == LocalFilesModel.Dataset && !qfieldLocalDataPickerScreen.projectFolderView && table.model.isDeletedAllowedInCurrentPath
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Remove dataset")
        onTriggered: {
          platformUtilities.removeDataset(itemMenu.itemPath);
        }
      }

      MenuItem {
        id: removeProjectFolder
        enabled: itemMenu.itemMetaType == LocalFilesModel.Folder && !qfieldLocalDataPickerScreen.projectFolderView && table.model.isDeletedAllowedInCurrentPath
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Remove folder")
        onTriggered: {
          platformUtilities.removeFolder(itemMenu.itemPath);
        }
      }
    }

    Menu {
      id: importMenu

      title: qsTr('Import Actions')

      width: {
        let result = 50;
        let padding = 0;
        for (let i = 0; i < count; ++i) {
          let item = itemAt(i);
          result = Math.max(item.contentItem.implicitWidth, result);
          padding = Math.max(item.leftPadding + item.rightPadding, padding);
        }
        return mainWindow.width > 0 ? Math.min(result + padding * 2, mainWindow.width - 20) : result + padding;
      }

      topMargin: sceneTopMargin
      bottomMargin: sceneBottomMargin

      MenuItem {
        id: importProjectFromFolder

        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Import project from folder")
        onTriggered: {
          platformUtilities.importProjectFolder();
        }
      }

      MenuItem {
        id: importProjectFromZIP

        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Import project from ZIP")
        onTriggered: {
          platformUtilities.importProjectArchive();
        }
      }

      MenuItem {
        id: importDataset

        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Import dataset(s)")
        onTriggered: {
          platformUtilities.importDatasets();
        }
      }

      MenuSeparator {
        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport
        visible: enabled
        width: parent.width
        height: enabled ? undefined : 0
      }

      MenuItem {
        id: importUrl

        font: Theme.defaultFont
        width: parent.width
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Import URL")
        onTriggered: {
          importUrlDialog.open();
          importUrlInput.focus = true;
        }
      }

      MenuItem {
        id: importWebdav

        font: Theme.defaultFont
        width: parent.width
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Import WebDAV folder")
        onTriggered: {
          importWebdavDialog.open();
          importWebdavUrlInput.focus = true;
        }
      }

      MenuSeparator {
        width: parent.width
      }

      MenuItem {
        id: storageHelp

        font: Theme.defaultFont
        width: parent.width
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Storage management help")
        onTriggered: {
          Qt.openUrlExternally("https://docs.qfield.org/get-started/storage/");
        }
      }
    }

    Menu {
      id: projectMenu

      title: qsTr('Project Actions')

      width: {
        let result = 50;
        let padding = 0;
        for (let i = 0; i < count; ++i) {
          let item = itemAt(i);
          result = Math.max(item.contentItem.implicitWidth, result);
          padding = Math.max(item.leftPadding + item.rightPadding, padding);
        }
        return mainWindow.width > 0 ? Math.min(result + padding * 2, mainWindow.width - 20) : result + padding;
      }

      topMargin: sceneTopMargin
      bottomMargin: sceneBottomMargin

      MenuItem {
        id: updateProjectFromArchive

        enabled: platformUtilities.capabilities & PlatformUtilities.UpdateProjectFromArchive
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Update project from ZIP")
        onTriggered: {
          platformUtilities.updateProjectFromArchive(projectInfo.filePath);
        }
      }

      MenuItem {
        id: uploadProjectToWebdav

        enabled: webdavConnectionLoader.item ? webdavConnectionLoader.item.hasWebdavConfiguration(FileUtils.absolutePath(projectInfo.filePath)) : false
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Upload project to WebDAV")
        onTriggered: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.uploadPath(FileUtils.absolutePath(projectInfo.filePath));
          }
        }
      }

      MenuItem {
        id: downloadProjectToWebdav

        enabled: uploadProjectToWebdav.enabled
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? undefined : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Download project from WebDAV")
        onTriggered: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.openedProjectPath = projectInfo.filePath;
            iface.clearProject();
            webdavConnectionLoader.item.downloadPath(FileUtils.absolutePath(projectInfo.filePath));
          }
        }
      }
    }
  }

  QfDialog {
    id: importUrlDialog
    title: qsTr("Import URL")
    focus: visible
    y: (mainWindow.height - height - 80) / 2

    onAboutToShow: {
      importUrlInput.text = '';
    }

    Column {
      width: childrenRect.width
      height: childrenRect.height
      spacing: 10

      TextMetrics {
        id: importUrlLabelMetrics
        font: importUrlLabel.font
        text: importUrlLabel.text
      }

      Label {
        id: importUrlLabel
        width: mainWindow.width - 60 < importUrlLabelMetrics.width ? mainWindow.width - 60 : importUrlLabelMetrics.width
        text: qsTr("Type a URL below to download and import the project or dataset:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      QfTextField {
        id: importUrlInput
        width: importUrlLabel.width
      }
    }

    onAccepted: {
      iface.importUrl(importUrlInput.text);
    }
  }

  Loader {
    id: webdavConnectionLoader
    active: qfieldLocalDataPickerScreen.openedOnce
    sourceComponent: Component {
      WebdavConnection {
        id: webdavConnection

        property string openedProjectPath: ""

        onIsImportingPathChanged: {
          if (isImportingPath) {
            busyOverlay.text = qsTr("Importing WebDAV folder");
            busyOverlay.progress = 0;
            busyOverlay.state = "visible";
          } else {
            busyOverlay.state = "hidden";
          }
        }

        onIsDownloadingPathChanged: {
          if (isDownloadingPath) {
            busyOverlay.text = qsTr("Downloading WebDAV folder");
            busyOverlay.progress = 0;
            busyOverlay.state = "visible";
          } else {
            busyOverlay.state = "hidden";
            if (openedProjectPath) {
              iface.loadFile(openedProjectPath);
              openedProjectPath = "";
            }
          }
        }

        onIsUploadingPathChanged: {
          if (isUploadingPath) {
            busyOverlay.text = qsTr("Uploading WebDAV folder");
            busyOverlay.progress = 0;
            busyOverlay.state = "visible";
          } else {
            busyOverlay.state = "hidden";
          }
        }

        onProgressChanged: {
          if (isImportingPath || isDownloadingPath || isUploadingPath) {
            busyOverlay.progress = progress;
          }
        }

        onLastErrorChanged: {
          displayToast(qsTr("WebDAV error: ") + lastError);
        }

        onConfirmationRequested: (host, username) => {
          downloadUploadWebdavDialog.isUploadingPath = isUploadingPath;
          downloadUploadWebdavDialog.host = host;
          downloadUploadWebdavDialog.username = username;
          downloadUploadWebdavDialog.open();
        }

        onImportSuccessful: path => {
          table.model.currentPath = path;
        }
      }
    }
  }

  QfDialog {
    id: downloadUploadWebdavDialog
    title: isUploadingPath ? qsTr("WebDAV upload") : qsTr("WebDAV download")
    focus: true
    y: (mainWindow.height - height - 80) / 2

    property bool isUploadingPath: false
    property string host: ""
    property string username: ""

    onAboutToShow: {
      if (webdavConnectionLoader.item) {
        webdavConnectionLoader.item.password = downloadUploadWebdavPasswordInput.text;
        webdavConnectionLoader.item.storePassword = downloadUploadWebdavPasswordCheck.checked;
      }
    }

    Column {
      width: childrenRect.width
      height: childrenRect.height
      spacing: 10

      TextMetrics {
        id: downloadUploadWebdavIntroMetrics
        font: downloadUploadWebdavIntroLabel.font
        text: downloadUploadWebdavIntroLabel.text
      }

      Label {
        id: downloadUploadWebdavIntroLabel
        width: mainWindow.width - 60 < downloadUploadWebdavIntroMetrics.width ? mainWindow.width - 60 : downloadUploadWebdavIntroMetrics.width
        text: downloadUploadWebdavDialog.isUploadingPath ? qsTr("You are about to upload modified content into <b>%1</b> using user <b>%2</b>.<br><br>This operation will overwrite data stored remotely, make sure this is what you want to do.").arg(downloadUploadWebdavDialog.host).arg(downloadUploadWebdavDialog.username) : qsTr("You are about to download modified content from <b>%1</b> using user <b>%2</b>.<br><br>This operation will overwrite data stored locally, make sure this is what you want to do.").arg(downloadUploadWebdavDialog.host).arg(downloadUploadWebdavDialog.username)
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      TextField {
        id: downloadUploadWebdavPasswordInput
        enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
        width: downloadUploadWebdavIntroLabel.width
        rightPadding: leftPadding + (downloadUploadWebdavShowPasswordInput.width - leftPadding)
        placeholderText: text === "" && webdavConnectionLoader.item && webdavConnectionLoader.item.isPasswordStored ? qsTr("Password (leave empty to use remembered)") : qsTr("Password")
        echoMode: TextInput.Password

        onDisplayTextChanged: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.password = text;
          }
        }

        QfToolButton {
          id: downloadUploadWebdavShowPasswordInput

          property int originalEchoMode: TextInput.Normal

          visible: (!!parent.echoMode && parent.echoMode !== TextInput.Normal) || originalEchoMode !== TextInput.Normal
          iconSource: parent.echoMode === TextInput.Normal ? Theme.getThemeVectorIcon('ic_hide_green_48dp') : Theme.getThemeVectorIcon('ic_show_green_48dp')
          iconColor: Theme.mainColor
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          opacity: parent.text.length > 0 ? 1 : 0.25
          z: 1

          onClicked: {
            if (parent.echoMode !== TextInput.Normal) {
              originalEchoMode = parent.echoMode;
              parent.echoMode = TextInput.Normal;
            } else {
              parent.echoMode = originalEchoMode;
            }
          }
        }
      }

      CheckBox {
        id: downloadUploadWebdavPasswordCheck
        width: downloadUploadWebdavIntroLabel.width
        enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
        text: qsTr('Remember password')
        font: Theme.defaultFont
        checked: true
      }
    }

    onAccepted: {
      if (webdavConnectionLoader.item) {
        webdavConnectionLoader.item.confirmRequest();
      }
    }

    onRejected: {
      if (webdavConnectionLoader.item) {
        webdavConnectionLoader.item.cancelRequest();
      }
    }
  }

  QfDialog {
    id: importWebdavDialog
    title: qsTr("Import WebDAV folder")
    focus: visible
    y: (mainWindow.height - height - 80) / 2

    onAboutToShow: {
      if (webdavConnectionLoader.item) {
        webdavConnectionLoader.item.url = importWebdavUrlInput.text;
        webdavConnectionLoader.item.username = importWebdavUserInput.text;
        webdavConnectionLoader.item.password = importWebdavPasswordInput.text;
        webdavConnectionLoader.item.storePassword = importWebdavStorePasswordCheck.checked;
      }
    }

    Column {
      width: childrenRect.width
      height: childrenRect.height
      spacing: 10

      TextMetrics {
        id: importWebdavUrlLabelMetrics
        font: importWebdavUrlLabel.font
        text: importWebdavUrlLabel.text
      }

      Label {
        id: importWebdavUrlLabel
        width: mainWindow.width - 60 < importWebdavUrlLabelMetrics.width ? mainWindow.width - 60 : importWebdavUrlLabelMetrics.width
        text: qsTr("Type the WebDAV details below to import a remote folder:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      TextField {
        id: importWebdavUrlInput
        enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
        width: importWebdavUrlLabel.width
        placeholderText: qsTr("WebDAV server URL")

        onDisplayTextChanged: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.url = displayText;
          }
        }
      }

      TextField {
        id: importWebdavUserInput
        enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
        width: importWebdavUrlLabel.width
        placeholderText: qsTr("User")

        onDisplayTextChanged: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.username = displayText;
          }
        }
      }

      TextField {
        id: importWebdavPasswordInput
        enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
        width: importWebdavUrlLabel.width
        rightPadding: leftPadding + (importWebdavShowPasswordInput.width - leftPadding)
        placeholderText: text === "" && webdavConnectionLoader.item && webdavConnectionLoader.item.isPasswordStored ? qsTr("Password (leave empty to use remembered)") : qsTr("Password")
        echoMode: TextInput.Password

        onDisplayTextChanged: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.password = text;
          }
        }

        QfToolButton {
          id: importWebdavShowPasswordInput

          property int originalEchoMode: TextInput.Normal

          visible: (!!parent.echoMode && parent.echoMode !== TextInput.Normal) || originalEchoMode !== TextInput.Normal
          iconSource: parent.echoMode === TextInput.Normal ? Theme.getThemeVectorIcon('ic_hide_green_48dp') : Theme.getThemeVectorIcon('ic_show_green_48dp')
          iconColor: Theme.mainColor
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          opacity: parent.text.length > 0 ? 1 : 0.25
          z: 1

          onClicked: {
            if (parent.echoMode !== TextInput.Normal) {
              originalEchoMode = parent.echoMode;
              parent.echoMode = TextInput.Normal;
            } else {
              parent.echoMode = originalEchoMode;
            }
          }
        }
      }

      CheckBox {
        id: importWebdavStorePasswordCheck
        width: importWebdavUrlLabel.width
        enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
        text: qsTr('Remember password')
        font: Theme.defaultFont
        checked: true
      }

      Label {
        width: importWebdavUrlLabel.width
        visible: importWebdavPathInput.visible
        text: qsTr("Select the remote folder to import:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      Row {
        spacing: 5

        QfButton {
          id: importWebdavFetchFoldersButton
          anchors.verticalCenter: importWebdavPathInput.verticalCenter
          visible: !webdavConnectionLoader.item || webdavConnectionLoader.item.availablePaths.length === 0
          enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
          width: importWebdavUrlLabel.width - (importWebdavFetchFoldersIndicator.visible ? importWebdavFetchFoldersIndicator.width + 5 : 0)
          text: !enabled ? qsTr("Fetching remote folders") : qsTr("Fetch remote folders")

          onClicked: {
            webdavConnectionLoader.item.fetchAvailablePaths();
          }
        }

        ComboBox {
          id: importWebdavPathInput
          width: importWebdavUrlLabel.width - (importWebdavRefetchFoldersButton.width + 5) - (importWebdavFetchFoldersIndicator.visible ? importWebdavFetchFoldersIndicator.width + 5 : 0)
          visible: webdavConnectionLoader.item && webdavConnectionLoader.item.availablePaths.length > 0
          enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
          model: [''].concat(webdavConnectionLoader.item ? webdavConnectionLoader.item.availablePaths : [])
        }

        QfToolButton {
          id: importWebdavRefetchFoldersButton
          anchors.verticalCenter: importWebdavPathInput.verticalCenter
          visible: importWebdavPathInput.visible
          enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
          bgcolor: "transparent"
          iconSource: Theme.getThemeVectorIcon("refresh_24dp")
          iconColor: enabled ? Theme.mainTextColor : Theme.mainTextDisabledColor

          onClicked: {
            webdavConnectionLoader.item.fetchAvailablePaths();
          }
        }

        BusyIndicator {
          id: importWebdavFetchFoldersIndicator
          anchors.verticalCenter: importWebdavPathInput.verticalCenter
          width: 48
          height: 48
          visible: webdavConnectionLoader.item && webdavConnectionLoader.item.isFetchingAvailablePaths
          running: visible
        }
      }
    }

    onAccepted: {
      if (importWebdavPathInput.displayText !== '' && webdavConnectionLoader.item) {
        webdavConnectionLoader.item.url = importWebdavUrlInput.text;
        webdavConnectionLoader.item.username = importWebdavUserInput.text;
        webdavConnectionLoader.item.password = importWebdavPasswordInput.text;
        webdavConnectionLoader.item.storePassword = importWebdavStorePasswordCheck.checked;
        webdavConnectionLoader.item.importPath(importWebdavPathInput.displayText, platformUtilities.applicationDirectory() + "Imported Projects/");
      }
    }
  }

  Connections {
    target: iface

    function onOpenPath(path) {
      if (visible) {
        table.model.currentPath = path;
      }
    }
  }

  Keys.onReleased: event => {
    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
      event.accepted = true;
      if (table.model.currentDepth > 1) {
        table.model.moveUp();
      } else {
        finished(false);
      }
    }
  }
}
