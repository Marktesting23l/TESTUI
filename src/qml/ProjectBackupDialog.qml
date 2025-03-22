import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import Theme

Dialog {
    id: backupDialog
    title: qsTr("Project Backups")
    width: Math.min(600, parent.width * 0.9)
    height: Math.min(800, parent.height * 0.9)
    modal: true
    standardButtons: Dialog.Close
    
    property string currentProjectPath: ""
    property string currentProjectName: {
        var parts = currentProjectPath.split("/");
        return parts[parts.length - 1].replace(".qgz", "");
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        // Backup options
        GroupBox {
            title: qsTr("Backup Options")
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                
                RadioButton {
                    id: projectOnlyMode
                    text: qsTr("Project file only")
                    checked: true
                }
                
                RadioButton {
                    id: fullBackupMode
                    text: qsTr("Project file and GPKG data (may be large)")
                }
            }
        }
        
        // Progress bar
        ProgressBar {
            id: backupProgress
            Layout.fillWidth: true
            visible: false
            from: 0
            to: 100
            value: 0
        }
        
        Label {
            id: progressLabel
            Layout.fillWidth: true
            visible: false
            wrapMode: Text.WordWrap
        }
        
        // Backup button
        Button {
            text: qsTr("Create Backup")
            icon.source: "qrc:/themes/sigpacgo/nodpi/ic_backup_white_24dp.svg"
            Layout.fillWidth: true
            enabled: !backupProgress.visible
            onClicked: {
                backupProgress.visible = true;
                progressLabel.visible = true;
                if (projectBackupManager.createBackup(
                    currentProjectPath, 
                    fullBackupMode.checked ? 1 : 0  // ProjectAndGpkg : ProjectOnly
                )) {
                    backupListModel.reload();
                }
            }
        }
        
        // List of backups
        ListView {
            id: backupListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: ListModel {
                id: backupListModel
                
                function reload() {
                    clear();
                    var backups = projectBackupManager.listBackups(backupDialog.currentProjectName);
                    for (var i = 0; i < backups.length; i++) {
                        append({
                            name: backups[i],
                            path: projectBackupManager.getBackupDirectory() + "/" + backups[i]
                        });
                    }
                }
                
                Component.onCompleted: reload()
            }
            
            delegate: ItemDelegate {
                width: parent.width
                height: 72
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Label {
                            text: {
                                var parts = name.split("_");
                                var date = parts[parts.length - 2];
                                var time = parts[parts.length - 1];
                                return qsTr("Backup from %1 at %2").arg(date).arg(time);
                            }
                            font.bold: true
                        }
                        
                        Label {
                            text: path
                            font.pixelSize: 12
                            color: Material.color(Material.Grey)
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                    
                    // Restore button
                    Button {
                        text: qsTr("Restore")
                        icon.source: "qrc:/themes/sigpacgo/nodpi/ic_restore_white_24dp.svg"
                        onClicked: {
                            confirmDialog.open();
                            confirmDialog.backupPath = path;
                        }
                    }
                    
                    // Delete button
                    Button {
                        text: qsTr("Delete")
                        icon.source: "qrc:/themes/sigpacgo/nodpi/ic_delete_white_24dp.svg"
                        onClicked: {
                            if (projectBackupManager.deleteBackup(path)) {
                                backupListModel.reload();
                                showToast(qsTr("Backup deleted"));
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Confirmation dialog for restore
    Dialog {
        id: confirmDialog
        title: qsTr("Restore Backup")
        standardButtons: Dialog.Yes | Dialog.No
        modal: true
        
        property string backupPath: ""
        
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: qsTr("Are you sure you want to restore this backup? This will replace your current project with the backup version.")
        }
        
        onAccepted: {
            if (projectBackupManager.restoreBackup(backupPath, currentProjectPath)) {
                showToast(qsTr("Backup restored successfully"));
                backupDialog.close();
                // Reload the project
                qgisProject.read(currentProjectPath);
            }
        }
    }
    
    // Toast message
    function showToast(message) {
        toast.show(message);
    }
    
    Connections {
        target: projectBackupManager
        
        function onBackupProgress(message, progress) {
            progressLabel.text = message;
            backupProgress.value = progress;
            if (progress === 100) {
                // Hide progress after a delay
                hideProgressTimer.start();
            }
        }
        
        function onBackupError(error) {
            toast.show(error);
            backupProgress.visible = false;
            progressLabel.visible = false;
        }
    }
    
    Timer {
        id: hideProgressTimer
        interval: 2000
        onTriggered: {
            backupProgress.visible = false;
            progressLabel.visible = false;
        }
    }
} 