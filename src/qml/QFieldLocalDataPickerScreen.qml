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
  property bool storeCurrentPathOnClose: true
  property bool showImportDialog: false
  property QtObject toolBarActions
  property var screenTitle: qsTr("Archivos")
  property alias model: table.model
  property bool gpkgLayerDeleted: false // Track if a GPKG layer was deleted
  property var files: [] // Add property for files

  signal finished(var loading)
  signal projectHasBeenOpened()
  signal projectHasBeenClosed()
  signal openProjectTabClicked()

  focus: visible

  onVisibleChanged: {
    if (visible) {
      openedOnce = true;
    }
  }

  // Initialize variables for tracking layer deletion reloads
  Component.onCompleted: {
    // Make sure we initialize our variables
    if (!model) {
      model = localFilesModel;
    }
    // No need to initialize gpkgLayerDeleted as it's already declared in mainWindow
  }

  header: QfPageHeader {
    title: projectFolderView ? qsTr("Carpeta del proyecto") : qsTr("Proyectos y conjuntos de datos locales")

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
                  return qsTr('Carpetas');
                case LocalFilesModel.Project:
                  return qsTr('Proyectos');
                case LocalFilesModel.Dataset:
                  return qsTr('Conjuntos de datos');
                case LocalFilesModel.File:
                  return qsTr('Archivos');
                case LocalFilesModel.Favorite:
                  return qsTr('Favoritos');
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
          property bool itemMenuVisible: ((ItemType === LocalFilesModel.SimpleFolder || ItemMetaType == LocalFilesModel.Dataset || ItemMetaType == LocalFilesModel.File) && table.model.currentPath !== 'root') || ((platformUtilities.capabilities & PlatformUtilities.CustomExport || platformUtilities.capabilities & PlatformUtilities.CustomSend) && (ItemMetaType === LocalFilesModel.Dataset)) || (ItemMetaType === LocalFilesModel.Dataset && ItemType === LocalFilesModel.RasterDataset && cloudProjectsModel.currentProjectId)

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
                    return Theme.getThemeVectorIcon('ic_folder_sigpacgo_gray_48dp');
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
                    info = qsTr('Archivo de proyecto');
                    break;
                  case LocalFilesModel.VectorDataset:
                    info = qsTr('Conjunto de datos vectorial') + ' (' + FileUtils.representFileSize(ItemSize) + ')';
                    break;
                  case LocalFilesModel.RasterDataset:
                    info = qsTr('Conjunto de datos ráster') + ' (' + FileUtils.representFileSize(ItemSize) + ')';
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
              round: false
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
                console.log("Clicked item:", item.itemTitle, "Path:", item.itemPath, "Type:", item.itemMetaType, "ItemType:", item.itemType);
                if (item.itemMetaType === LocalFilesModel.Folder || item.itemMetaType === LocalFilesModel.Favorite) {
                  console.log("Setting current path to:", item.itemPath);
                  table.model.currentPath = item.itemPath;
                } else if (!qfieldLocalDataPickerScreen.projectFolderView && (item.itemMetaType === LocalFilesModel.Project || item.itemMetaType === LocalFilesModel.Dataset)) {
                  // Check if we have a global variable set for reloading after layer deletion
                  var loadPath = item.itemPath;
                  if (mainWindow.gpkgLayerDeleted) {
                    console.log("Layer removal requiring reload detected - GPKG layer has been deleted");
                    console.log("Setting #nohardcoded flag for project path: " + loadPath);
                    loadPath += "#nohardcoded";
                    console.log("Final project path with flag: " + loadPath);
                    mainWindow.gpkgLayerDeleted = false;
                  }
                  iface.loadFile(loadPath, item.itemTitle);
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
        round: false

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
        round: false
        // Since the project menu only has one action for now, hide if PlatformUtilities.UpdateProjectFromArchive is missing
        property bool isLocalProject: qgisProject && QFieldCloudUtils.getProjectId(qgisProject.fileName) === '' && (projectInfo.filePath.endsWith('.qgs') || projectInfo.filePath.endsWith('.qgz'))
        property bool isLocalProjectActionAvailable: updateProjectFromArchive.enabled || uploadProjectToWebdav.enabled
        visible: projectFolderView || table.model.currentPath === 'root'

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
            if (isLocalProject && table.model.currentDepth === 1) {
              projectMenu.popup(xy.x - projectMenu.width, xy.y - projectMenu.height - header.height);
            } else {
              importMenu.popup(xy.x - importMenu.width, xy.y - importMenu.height - header.height);
            }
          } else {
            importMenu.popup(xy.x - importMenu.width, xy.y - importMenu.height - header.height);
          }
        }
      }
      
      // Layer management button
      QfToolButton {
        id: layerManagementButton
        round: false
        visible: qgisProject

        anchors.bottom: parent.bottom
        anchors.right: actionButton.left
        anchors.bottomMargin: 10
        anchors.rightMargin: 10

        bgcolor: Theme.accentColor
        iconSource: Theme.getThemeVectorIcon("ic_layers_white_24dp")
        iconColor: Theme.toolButtonColor

        onClicked: {
          layerManagementDialog.open()
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

      title: qsTr('Acciones del elemento')

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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Enviar a...")
        onTriggered: {
          platformUtilities.sendDatasetTo(itemMenu.itemPath);
        }
      }

      MenuItem {
        id: exportDatasetTo
        enabled: platformUtilities.capabilities & PlatformUtilities.CustomExport && itemMenu.itemMetaType == LocalFilesModel.Dataset
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Exportar a la carpeta...")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: !itemMenu.itemIsFavorite ? qsTr("Añadir a favoritos") : qsTr("Eliminar de favoritos")
        onTriggered: {
          if (!itemMenu.itemIsFavorite) {
            localFilesModel.addToFavorites(itemMenu.itemPath);
          } else {
            localFilesModel.removeFromFavorites(itemMenu.itemPath);
          }
        }
      }

      MenuItem {
        id: createBackupMenuItem
        enabled: itemMenu.itemMetaType == LocalFilesModel.Folder
        visible: enabled
        
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding
        
        text: qsTr("Crear copia de seguridad")
        onTriggered: {
          createBackupDialog.folderPath = itemMenu.itemPath
          createBackupDialog.folderName = itemMenu.itemPath.split('/').pop()
          createBackupDialog.open()
        }
      }

      MenuSeparator {
        enabled: toggleFavoriteState.visible && (exportFolderTo.visible || sendCompressedFolderTo.visible || uploadFolderToWebdav.visible || downloadFolderFromWebdav.visible)
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Exportar a la carpeta...")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Enviar carpeta comprimida a...")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Subir carpeta al servidor WebDAV")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Descargar carpeta del servidor WebDAV")
        onTriggered: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.downloadPath(itemMenu.itemPath);
          }
        }
      }

      MenuSeparator {
        enabled: removeDataset.visible || removeProjectFolder.visible
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Eliminar conjunto de datos")
        onTriggered: {
          platformUtilities.removeDataset(itemMenu.itemPath);
          table.model.resetToPath(table.model.currentPath);
        }
      }

      MenuItem {
        id: removeProjectFolder
        enabled: itemMenu.itemMetaType == LocalFilesModel.Folder && !qfieldLocalDataPickerScreen.projectFolderView && table.model.isDeletedAllowedInCurrentPath
        visible: enabled

        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Eliminar carpeta")
        onTriggered: {
          platformUtilities.removeFolder(itemMenu.itemPath);
          table.model.resetToPath(table.model.currentPath);
        }
      }
    }

    Menu {
      id: importMenu

      title: qsTr('Acciones de importación')

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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar proyecto desde la carpeta")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar proyecto desde ZIP")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar conjunto(s) de datos")
        onTriggered: {
          platformUtilities.importDatasets();
        }
      }

      MenuItem {
        id: importSingleFile

        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar archivo único")
        onTriggered: {
          platformUtilities.importSingleFile(table.model.currentPath);
        }
      }

      MenuItem {
        id: importDatasetToProjectFolder

        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport && qfieldLocalDataPickerScreen.projectFolderView
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar archivo a carpeta del proyecto")
        onTriggered: {
          platformUtilities.importDatasetsToCurrentProject(table.model.currentPath);
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
        height: 48
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar URL")
        onTriggered: {
          importUrlDialog.open();
          importUrlInput.focus = true;
        }
      }

      MenuItem {
        id: importWebdav

        font: Theme.defaultFont
        width: parent.width
        height: 48
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar carpeta WebDAV")
        onTriggered: {
          importWebdavDialog.open();
          importWebdavUrlInput.focus = true;
        }
      }
      
      MenuSeparator {
        enabled: qfieldLocalDataPickerScreen.projectFolderView && qgisProject
        visible: enabled
        width: parent.width
        height: enabled ? undefined : 0
      }
      
      MenuItem {
        id: layerManagementMenu
        
        enabled: qgisProject
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Gestionar capas")
        onTriggered: {
          layerManagementDialog.open()
        }
      }
      
      MenuItem {
        id: addLayerMenu
        
        enabled: qfieldLocalDataPickerScreen.projectFolderView && qgisProject
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Añadir capa al proyecto")
        onTriggered: {
          addLayerFromFileDialog.open()
        }
      }
      
      MenuItem {
        id: removeLayerFromProjectMenu
        
        enabled: qfieldLocalDataPickerScreen.projectFolderView && qgisProject
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Eliminar capa del proyecto")
        onTriggered: {
          removeLayerDialog.open()
        }
      }
      
     
    }

    Menu {
      id: projectMenu

      title: qsTr('Acciones del proyecto')

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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Actualizar proyecto desde ZIP")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Subir proyecto a WebDAV")
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
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Descargar proyecto desde WebDAV")
        onTriggered: {
          if (webdavConnectionLoader.item) {
            webdavConnectionLoader.item.openedProjectPath = projectInfo.filePath;
            iface.clearProject();
            webdavConnectionLoader.item.downloadPath(FileUtils.absolutePath(projectInfo.filePath));
          }
        }
      }

      MenuSeparator {
        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport
        visible: enabled
        width: parent.width
        height: enabled ? undefined : 0
      }
      
      MenuItem {
        id: importFileToProject

        enabled: platformUtilities.capabilities & PlatformUtilities.CustomImport && qfieldLocalDataPickerScreen.projectFolderView
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Importar archivo a este proyecto")
        onTriggered: {
          platformUtilities.importDatasetsToCurrentProject(table.model.currentPath);
        }
      }
      
      MenuItem {
        id: addLayerFromFile

        enabled: qfieldLocalDataPickerScreen.projectFolderView && qgisProject
        visible: enabled
        font: Theme.defaultFont
        width: parent.width
        height: enabled ? 48 : 0
        leftPadding: Theme.menuItemLeftPadding

        text: qsTr("Añadir capa al proyecto")
        onTriggered: {
          addLayerFromFileDialog.open()
        }
      }
    }
  }

  QfDialog {
    id: importUrlDialog
    title: qsTr("Importar URL")
    focus: visible
    parent: mainWindow.contentItem

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
        text: qsTr("Escriba una URL a continuación para descargar e importar el proyecto o el conjunto de datos:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      TextField {
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
            busyOverlay.text = qsTr("Importando carpeta WebDAV");
            busyOverlay.progress = 0;
            busyOverlay.state = "visible";
          } else {
            busyOverlay.state = "hidden";
          }
        }

        onIsDownloadingPathChanged: {
          if (isDownloadingPath) {
            busyOverlay.text = qsTr("Descargando carpeta WebDAV");
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
            busyOverlay.text = qsTr("Subiendo carpeta WebDAV");
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
          displayToast(qsTr("Error de WebDAV: ") + lastError);
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

        onIsFetchingAvailablePathsChanged: {
          if (!isFetchingAvailablePaths && importWebdavDialog.visible) {
            swipeDialog.currentIndex = 1;
            importWebdavPathInput.currentIndex = -1;
            importWebdavPathInput.model = availablePaths;
          }
        }
      }
    }
  }

  QfDialog {
    id: downloadUploadWebdavDialog
    title: isUploadingPath ? qsTr("Subida WebDAV") : qsTr("Descarga WebDAV")
    focus: visible
    parent: mainWindow.contentItem

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
        text: downloadUploadWebdavDialog.isUploadingPath ? qsTr("Está a punto de subir contenido modificado a <b>%1</b> utilizando el usuario <b>%2</b>.<br><br>Esta operación sobrescribirá los datos almacenados de forma remota, asegúrese de que esto es lo que quiere hacer.").arg(downloadUploadWebdavDialog.host).arg(downloadUploadWebdavDialog.username) : qsTr("Está a punto de descargar contenido modificado de <b>%1</b> utilizando el usuario <b>%2</b>.<br><br>Esta operación sobrescribirá los datos almacenados localmente, asegúrese de que esto es lo que quiere hacer.").arg(downloadUploadWebdavDialog.host).arg(downloadUploadWebdavDialog.username)
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      TextField {
        id: downloadUploadWebdavPasswordInput
        enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
        width: downloadUploadWebdavIntroLabel.width
        rightPadding: leftPadding + (downloadUploadWebdavShowPasswordInput.width - leftPadding)
        placeholderText: text === "" && webdavConnectionLoader.item && webdavConnectionLoader.item.isPasswordStored ? qsTr("Contraseña (dejar vacío para usar la recordada)") : qsTr("Contraseña")
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
        text: qsTr("Recordar la contraseña")
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
    title: qsTr("Importar carpeta WebDAV")
    focus: visible
    parent: mainWindow.contentItem

    property var importHistory: undefined

    onAboutToShow: {
      swipeDialog.currentIndex = 0;
      if (webdavConnectionLoader.item) {
        importHistory = webdavConnectionLoader.item.importHistory();
        importWebdavUrlInput.model = [""].concat(Object.keys(importHistory["urls"]));
        if (importHistory["lastUrl"] !== "") {
          importWebdavUrlInput.editText = importHistory["lastUrl"];
          importWebdavUserInput.model = [""].concat(Object.keys(importHistory["urls"][importHistory["lastUrl"]]["users"]));
          importWebdavUserInput.editText = importHistory["urls"][importHistory["lastUrl"]]["lastUser"];
        } else {
          importWebdavUserInput.model = [];
        }
        webdavConnectionLoader.item.url = importWebdavUrlInput.editText;
        webdavConnectionLoader.item.username = importWebdavUserInput.editText;
        webdavConnectionLoader.item.password = importWebdavPasswordInput.text;
        webdavConnectionLoader.item.storePassword = importWebdavStorePasswordCheck.checked;
      }
    }

    SwipeView {
      id: swipeDialog
      width: mainWindow.width - 60 < importWebdavUrlLabelMetrics.width ? mainWindow.width - 60 : importWebdavUrlLabelMetrics.width
      clip: true

      Column {
        id: firstPage
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
          text: qsTr("Escriba los detalles de WebDAV a continuación para importar una carpeta remota:")
          wrapMode: Text.WordWrap
          font: Theme.defaultFont
          color: Theme.mainTextColor
        }

        Label {
          width: importWebdavUrlLabel.width
          text: qsTr("URL del servidor WebDAV")
          wrapMode: Text.WordWrap
          font: Theme.defaultFont
          color: Theme.secondaryTextColor
        }

        ComboBox {
          id: importWebdavUrlInput
          enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
          width: importWebdavUrlLabel.width
          editable: true

          Connections {
            target: importWebdavUrlInput.contentItem
            ignoreUnknownSignals: true

            function onDisplayTextChanged() {
              if (webdavConnectionLoader.item && webdavConnectionLoader.item.url !== importWebdavUrlInput.editText) {
                webdavConnectionLoader.item.url = importWebdavUrlInput.editText;
                if (importWebdavDialog.importHistory["urls"][importWebdavUrlInput.editText] !== undefined) {
                  importWebdavUserInput.model = [""].concat(Object.keys(importWebdavDialog.importHistory["urls"][importWebdavUrlInput.editText]["users"]));
                  importWebdavUserInput.editText = importWebdavDialog.importHistory["urls"][importWebdavUrlInput.editText]["lastUser"];
                } else {
                  importWebdavUserInput.model = [];
                }
              }
            }
          }
        }

        Label {
          width: importWebdavUrlLabel.width
          text: qsTr("Usuario y contraseña")
          wrapMode: Text.WordWrap
          font: Theme.defaultFont
          color: Theme.secondaryTextColor
        }

        ComboBox {
          id: importWebdavUserInput
          enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
          width: importWebdavUrlLabel.width
          editable: true

          Connections {
            target: importWebdavUserInput.contentItem
            ignoreUnknownSignals: true

            function onDisplayTextChanged() {
              if (webdavConnectionLoader.item) {
                webdavConnectionLoader.item.username = importWebdavUserInput.editText;
              }
            }
          }
        }

        TextField {
          id: importWebdavPasswordInput
          enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
          width: importWebdavUrlLabel.width
          rightPadding: leftPadding + (importWebdavShowPasswordInput.width - leftPadding)
          placeholderText: text === "" && webdavConnectionLoader.item && webdavConnectionLoader.item.isPasswordStored ? qsTr("dejar vacío para usar la recordada") : ""
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

        Row {
          QfButton {
            id: importWebdavFetchFoldersButton
            anchors.verticalCenter: importWebdavFetchFoldersIndicator.verticalCenter
            enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
            width: importWebdavUrlLabel.width - (importWebdavFetchFoldersIndicator.visible ? importWebdavFetchFoldersIndicator.width : 0)
            text: !enabled ? qsTr("Buscando carpetas remotas") : qsTr("Buscar carpetas remotas")

            onClicked: {
              webdavConnectionLoader.item.fetchAvailablePaths();
            }
          }

          BusyIndicator {
            id: importWebdavFetchFoldersIndicator
            anchors.verticalCenter: importWebdavFetchFoldersButton.verticalCenter
            width: 48
            height: 48
            visible: webdavConnectionLoader.item && webdavConnectionLoader.item.isFetchingAvailablePaths
            running: visible
          }
        }
      }

      Column {
        Label {
          width: importWebdavUrlLabel.width
          visible: importWebdavPathInput.visible
          text: qsTr("Seleccione la carpeta remota para importar:")
          wrapMode: Text.WordWrap
          font: Theme.defaultFont
          color: Theme.mainTextColor
        }

        Rectangle {
          id: importWebdavPathContainer
          width: importWebdavUrlLabel.width
          height: 340
          color: Theme.controlBackgroundColor
          border.color: Theme.controlBorderColor
          border.width: 1

          ListView {
            id: importWebdavPathInput
            anchors.fill: parent
            anchors.margins: 1
            enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
            ScrollBar.vertical: QfScrollBar {
            }
            clip: true
            model: []

            property var expandedPaths: []
            property int expandedPathsClicks: 0

            delegate: Rectangle {
              id: rectangleDialog

              anchors.margins: 10
              width: parent ? parent.width : undefined
              height: lineDialog.isVisible ? lineDialog.height + 20 : 0
              color: importWebdavPathInput.currentIndex == index ? Theme.mainColor : Theme.mainBackgroundColor
              clip: true

              Row {
                id: lineDialog
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                property string label: {
                  let parts = modelData.split('/');
                  if (parts.length > 1) {
                    return parts[parts.length - 2];
                  }
                  return "";
                }
                property int level: Math.max(0, modelData.split('/').length - 2)
                property bool isVisible: {
                  let parts = modelData.split('/').slice(1, -2);
                  while (parts.length > 0) {
                    if (importWebdavPathInput.expandedPaths.indexOf("/" + parts.join("/") + "/") == -1) {
                      return false;
                    }
                    parts = parts.slice(0, -1);
                  }
                  return true;
                }
                property bool hasChildren: {
                  for (const availablePath of importWebdavPathInput.model) {
                    if (availablePath.indexOf(modelData) === 0 && availablePath !== modelData) {
                      return true;
                    }
                  }
                  return false;
                }
                property bool isImported: {
                  if (importWebdavDialog.importHistory["urls"][importWebdavUrlInput.editText] !== undefined && importWebdavDialog.importHistory["urls"][importWebdavUrlInput.editText]["users"][importWebdavUserInput.editText] !== undefined) {
                    console.log(importWebdavDialog.importHistory["urls"][importWebdavUrlInput.editText]["users"][importWebdavUserInput.editText]["importPaths"]);
                    return importWebdavDialog.importHistory["urls"][importWebdavUrlInput.editText]["users"][importWebdavUserInput.editText]["importPaths"].indexOf(modelData) >= 0;
                  }
                  return false;
                }

                Item {
                  id: expandSpacing
                  height: 35
                  width: 20 * Math.max(1, lineDialog.level) - 1
                }

                QfToolButton {
                  id: epxandButton
                  height: 35
                  width: height
                  anchors.verticalCenter: parent.verticalCenter
                  iconSource: Theme.getThemeVectorIcon('ic_legend_collapsed_state_24dp')
                  iconColor: Theme.mainTextColor
                  bgcolor: "transparent"
                  enabled: false
                  opacity: lineDialog.level > 0 && lineDialog.hasChildren && !lineDialog.isImported ? 1 : 0
                  rotation: importWebdavPathInput.expandedPaths.indexOf(modelData) > -1 ? 90 : 0

                  Behavior on rotation  {
                    NumberAnimation {
                      duration: 100
                    }
                  }
                }

                Column {
                  width: rectangleDialog.width - epxandButton.width - expandSpacing.width - 10
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    id: contentTextDialog
                    width: parent.width
                    leftPadding: 5
                    font: Theme.defaultFont
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    color: !lineDialog.isImported ? Theme.mainTextColor : Theme.secondaryTextColor
                    text: lineDialog.label !== "" ? lineDialog.label : qsTr("(carpeta raíz)")
                  }
                  Text {
                    id: noteTextDialog
                    width: parent.width
                    visible: lineDialog.isImported
                    leftPadding: 5
                    font: Theme.tipFont
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    color: Theme.secondaryTextColor
                    text: qsTr("Importado y disponible localmente")
                  }
                }
              }

              /* bottom border */
              Rectangle {
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.controlBorderColor
                width: parent.width
                visible: lineDialog.isVisible
              }

              MouseArea {
                enabled: !lineDialog.isImported
                anchors.fill: parent
                anchors.rightMargin: 48
                onClicked: mouse => {
                  importWebdavPathInput.currentIndex = index;
                }
                onDoubleClicked: mouse => {
                  const index = importWebdavPathInput.expandedPaths.indexOf(modelData);
                  if (importWebdavPathInput.expandedPaths.indexOf(modelData) == -1) {
                    importWebdavPathInput.expandedPaths.push(modelData);
                  } else {
                    importWebdavPathInput.expandedPaths.splice(index, 1);
                  }
                  importWebdavPathInput.expandedPathsChanged();
                }
              }
            }
          }
        }

        Row {
          spacing: 5

          QfButton {
            id: importWebdavRefetchFoldersButton
            width: importWebdavUrlLabel.width - (importWebdavRefreshFoldersIndicator.visible ? importWebdavRefreshFoldersIndicator.width : 0)
            enabled: !webdavConnectionLoader.item || !webdavConnectionLoader.item.isFetchingAvailablePaths
            bgcolor: "transparent"
            text: !enabled ? qsTr("Actualizando carpetas remotas") : qsTr("Actualizar carpetas remotas")

            onClicked: {
              importWebdavPathInput.currentIndex = -1;
              webdavConnectionLoader.item.fetchAvailablePaths();
            }
          }

          BusyIndicator {
            id: importWebdavRefreshFoldersIndicator
            anchors.verticalCenter: importWebdavRefetchFoldersButton.verticalCenter
            width: 48
            height: 48
            visible: webdavConnectionLoader.item && webdavConnectionLoader.item.isFetchingAvailablePaths
            running: visible
          }
        }
      }
    }

    onAccepted: {
      if (importWebdavPathInput.currentIndex > -1 && webdavConnectionLoader.item) {
        webdavConnectionLoader.item.url = importWebdavUrlInput.editText;
        webdavConnectionLoader.item.username = importWebdavUserInput.editText;
        webdavConnectionLoader.item.password = importWebdavPasswordInput.text;
        webdavConnectionLoader.item.storePassword = importWebdavStorePasswordCheck.checked;
        webdavConnectionLoader.item.importPath(importWebdavPathInput.model[importWebdavPathInput.currentIndex], platformUtilities.applicationDirectory() + "/Imported Projects/");
      }
    }
  }

  QfDialog {
    id: addLayerFromFileDialog
    title: qsTr("Añadir capa al proyecto")
    focus: visible
    parent: mainWindow.contentItem
    
    property bool canAccept: false
    
    standardButtons: Dialog.Ok | Dialog.Cancel
    
    onCanAcceptChanged: {
      if (standardButton(Dialog.Ok)) {
        standardButton(Dialog.Ok).enabled = canAccept
      }
    }
    
    onAboutToShow: {
      // Reset states
      qfieldLocalDataPickerScreen.files = []
      
      // Get the current directory path
      let currentDir = table.model.currentPath
      console.log("Current directory:", currentDir)
      
      // Get GPKG files from the current directory
      qfieldLocalDataPickerScreen.files = getGpkgFiles(currentDir)
      console.log("Found GPKG files:", qfieldLocalDataPickerScreen.files)
      
      filesList.model = qfieldLocalDataPickerScreen.files
      filesList.currentIndex = -1
      layerList.model = []
      layerList.currentIndex = -1
      
      // Reset acceptance state
      addLayerFromFileDialog.canAccept = false
      
      // Check if we have an active project
      if (!qgisProject) {
        noProjectMessage.visible = true
        noFilesMessage.visible = false
      } else if (qfieldLocalDataPickerScreen.files.length === 0) {
        noProjectMessage.visible = false
        noFilesMessage.visible = true
      } else {
        noProjectMessage.visible = false
        noFilesMessage.visible = false
      }
    }

    Column {
      width: Math.min(600, mainWindow.width - 60)
      height: childrenRect.height
      spacing: 10
      
      Label {
        id: noProjectMessage
        width: parent.width
        text: qsTr("No hay un proyecto activo. Primero debe abrir un proyecto QGIS.")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: "red"
        visible: false
      }
      
      Label {
        id: noFilesMessage
        width: parent.width
        text: qsTr("No se han encontrado archivos GPKG en el directorio actual.")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: "orange"
        visible: false
      }

      Label {
        width: parent.width
        text: qsTr("Seleccione un archivo GPKG:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }

      Rectangle {
        width: parent.width
        height: Math.min(150, mainWindow.height / 4)
        color: Theme.controlBackgroundColor
        border.color: Theme.controlBorderColor
        border.width: 1

        ListView {
          id: filesList
          anchors.fill: parent
          anchors.margins: 2
          clip: true
          focus: true
          model: []  // Initialize with empty model
          
          delegate: Rectangle {
            width: filesList.width
            height: 40
            color: filesList.currentIndex === index ? Theme.mainColor : "transparent"
            
            MouseArea {
              anchors.fill: parent
              onClicked: {
                filesList.currentIndex = index
                // Get layers in the selected GPKG file
                if (modelData) {
                  let layers = iface.getLayersInGeoPackage(modelData)
                  layerList.model = layers || []  // Ensure we always set a valid model
                  layerList.currentIndex = -1
                  // Always reset acceptance state when file selection changes
                  addLayerFromFileDialog.canAccept = false
                }
              }
            }
            
            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 5
              text: modelData ? modelData.split('/').pop() : ""  // Only show filename, not path
              font: Theme.defaultFont
              color: filesList.currentIndex === index ? Theme.toolButtonColor : Theme.mainTextColor
            }
          }
        }
      }
      
      Label {
        width: parent.width
        text: qsTr("Seleccione una capa para añadir:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
        visible: layerList.model.length > 0
      }
      
      Rectangle {
        width: parent.width
        height: Math.min(150, mainWindow.height / 4)
        color: Theme.controlBackgroundColor
        border.color: Theme.controlBorderColor
        border.width: 1
        visible: layerList.model.length > 0
        
        ListView {
          id: layerList
          anchors.fill: parent
          anchors.margins: 2
          clip: true
          model: []  // Initialize with empty model
          
          delegate: Rectangle {
            width: layerList.width
            height: 40
            color: layerList.currentIndex === index ? Theme.mainColor : "transparent"
            
            MouseArea {
              anchors.fill: parent
              onClicked: {
                layerList.currentIndex = index
                // Enable acceptance when both a file and layer are selected and we have an active project
                addLayerFromFileDialog.canAccept = filesList.currentIndex >= 0 && 
                                                 layerList.currentIndex >= 0 &&
                                                 qgisProject !== null
              }
            }
            
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 5
              anchors.rightMargin: 5
              spacing: 5
              
              // Layer icon based on type
              Text {
                text: modelData.type === "vector" ? "▢" : 
                     modelData.type === "raster" ? "▣" : "◈"
                font.pointSize: Theme.defaultFont.pointSize * 1.2
                color: layerList.currentIndex === index ? Theme.toolButtonColor : Theme.mainTextColor
              }
              
              // Layer name
              Text {
                Layout.fillWidth: true
                text: modelData ? modelData.name : ""
                font: Theme.defaultFont
                elide: Text.ElideRight
                color: layerList.currentIndex === index ? Theme.toolButtonColor : Theme.mainTextColor
              }
            }
          }
        }
      }
      

    }
    
    onAccepted: {
      if (filesList.currentIndex >= 0 && layerList.currentIndex >= 0) {
        let gpkgPath = filesList.model[filesList.currentIndex]
        let layerInfo = layerList.model[layerList.currentIndex]
        let success = false
        
        // Add the layer to the root level (no group)
        success = iface.addLayerToProject(gpkgPath, layerInfo.name, layerInfo.type)
        
        if (success) {
          displayToast(qsTr("Capa añadida correctamente"));
        }
      }
    }
  }

  QfDialog {
    id: removeLayerDialog
    title: qsTr("Eliminar capa del proyecto")
    focus: visible
    parent: mainWindow.contentItem
    
    property bool canAccept: false
    
    standardButtons: Dialog.Ok | Dialog.Cancel
    
    onCanAcceptChanged: {
      if (standardButton(Dialog.Ok)) {
        standardButton(Dialog.Ok).enabled = canAccept
      }
    }
    
    onAboutToShow: {
      // Reset states
      canAccept = false
      
      // Get all layers from the current project
      if (qgisProject) {
        removeLayersList.model = iface.getProjectLayers()
        removeLayerNoProjectMessage.visible = false
        removeLayerNoLayersMessage.visible = removeLayersList.model.length === 0
      } else {
        removeLayersList.model = []
        removeLayerNoProjectMessage.visible = true
        removeLayerNoLayersMessage.visible = false
      }
      
      // Reset selection
      removeLayersList.currentIndex = -1
    }

    Column {
      width: Math.min(600, mainWindow.width - 60)
      height: childrenRect.height
      spacing: 10
      
      Label {
        id: removeLayerNoProjectMessage
        width: parent.width
        text: qsTr("No hay un proyecto activo. Primero debe abrir un proyecto QGIS.")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: "red"
        visible: false
      }
      
      Label {
        id: removeLayerNoLayersMessage
        width: parent.width
        text: qsTr("No hay capas en el proyecto actual.")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: "orange"
        visible: false
      }

      Label {
        width: parent.width
        text: qsTr("Seleccione una capa para eliminar:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
        visible: removeLayersList.model.length > 0
      }

      Rectangle {
        width: parent.width
        height: Math.min(300, mainWindow.height / 3)
        color: Theme.controlBackgroundColor
        border.color: Theme.controlBorderColor
        border.width: 1
        visible: removeLayersList.model.length > 0

        ListView {
          id: removeLayersList
          anchors.fill: parent
          anchors.margins: 2
          clip: true
          focus: true
          
          delegate: Rectangle {
            width: removeLayersList.width
            height: 40
            color: removeLayersList.currentIndex === index ? Theme.mainColor : "transparent"
            
            MouseArea {
              anchors.fill: parent
              onClicked: {
                removeLayersList.currentIndex = index
                // Enable acceptance when a layer is selected
                removeLayerDialog.canAccept = true
              }
            }
            
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 5
              anchors.rightMargin: 5
              spacing: 5
              
              // Layer icon based on type
              Text {
                text: modelData.type === "vector" ? "▢" : 
                     modelData.type === "raster" ? "▣" : "◈"
                font.pointSize: Theme.defaultFont.pointSize * 1.2
                color: removeLayersList.currentIndex === index ? Theme.toolButtonColor : Theme.mainTextColor
              }
              
              // Layer name
              Text {
                Layout.fillWidth: true
                text: modelData.name
                font: Theme.defaultFont
                elide: Text.ElideRight
                color: removeLayersList.currentIndex === index ? Theme.toolButtonColor : Theme.mainTextColor
              }
            }
          }
        }
      }
    }
    
    onAccepted: {
      if (removeLayersList.currentIndex >= 0) {
        let layerInfo = removeLayersList.model[removeLayersList.currentIndex]
        let success = iface.removeLayerFromProject(layerInfo.id)
        
        if (success) {
          displayToast(qsTr("Capa eliminada correctamente"));
          
          // Set flag to indicate we're reloading after layer deletion
          // This will be checked when the project reloads to prevent hardcoded layer duplication
          mainWindow.gpkgLayerDeleted = true;
        } else {
          displayToast(qsTr("No se pudo eliminar la capa"));
        }
      }
    }
  }

  
  
  QfDialog {
    id: confirmRemoveGroupDialog
    title: qsTr("Confirmar eliminación")
    focus: visible
    parent: mainWindow.contentItem
    
    property string groupId: ""
    property string groupName: ""
    
    standardButtons: Dialog.Yes | Dialog.No
    
    Label {
      width: Math.min(400, mainWindow.width - 60)
      text: qsTr("¿Está seguro de que desea eliminar el grupo '%1'?\n\nATENCIÓN: Todas las capas dentro del grupo también serán eliminadas permanentemente.").arg(confirmRemoveGroupDialog.groupName)
      wrapMode: Text.WordWrap
      font: Theme.defaultFont
      color: "red"
    }
    
    onAccepted: {
      let success = iface.removeLayerGroup(confirmRemoveGroupDialog.groupId)
      if (success) {
        displayToast(qsTr("Grupo y sus capas eliminados correctamente"));
        // Refresh the groups list
        manageGroupsDialog.onAboutToShow()
      } else {
        displayToast(qsTr("Error al eliminar el grupo"));
      }
    }
  }

  QfDialog {
    id: layerManagementDialog
    title: qsTr("Gestión de capas del proyecto")
    focus: visible
    parent: mainWindow.contentItem
    
    standardButtons: Dialog.Close
    
    Column {
      width: Math.min(600, mainWindow.width - 60)
      height: childrenRect.height
      spacing: 20
      
      Label {
        width: parent.width
        text: qsTr("Seleccione una acción:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }
      
      Column {
        width: parent.width
        spacing: 10
        
        Button {
          width: parent.width
          height: 50
          text: qsTr("Añadir capa al proyecto")
          enabled: qgisProject !== null
          
          onClicked: {
            layerManagementDialog.close()
            addLayerFromFileDialog.open()
          }
        }
        
        Button {
          width: parent.width
          height: 50
          text: qsTr("Eliminar capa del proyecto")
          enabled: qgisProject !== null
          
          onClicked: {
            layerManagementDialog.close()
            removeLayerDialog.open()
          }
        }
        
        
      }
    }
  }

  QfDialog {
    id: createBackupDialog
    title: qsTr("Crear copia de seguridad")
    focus: visible
    parent: mainWindow.contentItem
    
    property string folderPath: ""
    property string folderName: ""
    property bool backupInProgress: false
    
    standardButtons: backupInProgress ? Dialog.NoButton : (Dialog.Ok | Dialog.Cancel)
    
    Column {
      width: Math.min(600, mainWindow.width - 60)
      spacing: 10
      
      Label {
        width: parent.width
        text: qsTr("Crear una copia de seguridad de la carpeta: <b>%1</b>").arg(createBackupDialog.folderName)
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }
      
      Rectangle {
        width: parent.width
        height: 1
        color: Theme.secondaryBackgroundColor
      }
      
      Label {
        width: parent.width
        text: qsTr("Destino de la copia de seguridad:")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
      }
      
      Column {
        width: parent.width
        spacing: 5
        
        RadioButton {
          id: defaultLocationRadio
          text: qsTr("Ubicación predeterminada (Documentos/SIGPACGO_Backups)")
          checked: true
        }
        
        RadioButton {
          id: customLocationRadio
          text: qsTr("Seleccionar ubicación")
        }
        
        Row {
          width: parent.width
          visible: customLocationRadio.checked
          spacing: 10
          
          TextField {
            id: customLocationField
            width: parent.width - selectFolderButton.width - 10
            placeholderText: qsTr("Ruta de destino")
            readOnly: true
          }
          
          Button {
            id: selectFolderButton
            text: qsTr("Explorar")
            onClicked: {
              // Implementation depends on platform capabilities
              // For now, we'll use a simple folder picker
              selectFolderDialog.open()
            }
          }
        }
      }
      
      Rectangle {
        width: parent.width
        height: 1
        color: Theme.secondaryBackgroundColor
        visible: createBackupDialog.backupInProgress
      }
      
      ProgressBar {
        width: parent.width
        indeterminate: true
        visible: createBackupDialog.backupInProgress
      }
      
      Label {
        width: parent.width
        text: qsTr("Creando copia de seguridad, por favor espere...")
        wrapMode: Text.WordWrap
        font: Theme.defaultFont
        color: Theme.mainTextColor
        visible: createBackupDialog.backupInProgress
      }
    }
    
    onAccepted: {
      // Show backup in progress state
      createBackupDialog.backupInProgress = true
      standardButtons = Dialog.NoButton
      
      // Determine destination path
      let destinationPath = ""
      if (customLocationRadio.checked && customLocationField.text) {
        destinationPath = customLocationField.text
      }
      
      // Use a timer to allow the UI to update before starting the backup process
      createBackupTimer.destinationPath = destinationPath
      createBackupTimer.start()
    }
    
    // Timer to delay the backup process slightly to allow the UI to update
    Timer {
      id: createBackupTimer
      interval: 100
      repeat: false
      property string destinationPath: ""
      
      onTriggered: {
        // Call the backup function
        let backupPath = iface.createFolderBackup(createBackupDialog.folderPath, destinationPath)
        
        // Update UI based on result
        createBackupDialog.backupInProgress = false
        createBackupDialog.standardButtons = Dialog.Close
        
        if (backupPath && backupPath.length > 0) {
          displayToast(qsTr("Copia de seguridad creada correctamente: %1").arg(backupPath));
        } else {
          displayToast(qsTr("Error al crear la copia de seguridad"));
        }
      }
    }
    
    // Dialog to select a custom destination folder
    QfDialog {
      id: selectFolderDialog
      title: qsTr("Seleccionar carpeta de destino")
      
      onAccepted: {
        // In a real implementation, this would use the platform's folder picker
        // For now, we'll use a simple simulation
        customLocationField.text = platformUtilities.applicationDirectory + "/backups"
      }
      
      Label {
        text: qsTr("En esta versión, las copias de seguridad se guardarán en: %1/backups").arg(platformUtilities.applicationDirectory)
        wrapMode: Text.WordWrap
        width: Math.min(500, mainWindow.width - 60)
      }
      
      standardButtons: Dialog.Ok | Dialog.Cancel
    }
  }

  Connections {
    target: iface

    function onOpenPath(path) {
      if (visible && table && table.model) {
        table.model.currentPath = path;
      }
    }

    function onLayerRemovalRequiringReload() {
      console.log("Layer removal detected that requires special reload handling");
      mainWindow.gpkgLayerDeleted = true;
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

  function getGpkgFiles(directory) {
    let result = []
    if (directory) {
      console.log("Searching for GPKG files in directory:", directory)
      
      // Make sure we have a valid directory path
      let dirPath = directory
      if (!dirPath.endsWith('/')) {
        dirPath += '/'
      }
      
      // Get all GPKG files
      let files = platformUtilities.getDirectoryContents(dirPath, "*.gpkg")
      console.log("Found GPKG files:", files)
      
      for (let i = 0; i < files.length; i++) {
        result.push(files[i])
      }
      
      // If no files found, try without trailing slash
      if (result.length === 0) {
        console.log("Retrying without trailing slash")
        files = platformUtilities.getDirectoryContents(directory, "*.gpkg")
        console.log("Found GPKG files (without slash):", files)
        for (let i = 0; i < files.length; i++) {
          result.push(files[i])
        }
      }
    } else {
      console.log("No directory provided to search for GPKG files")
    }
    return result
  }
}
