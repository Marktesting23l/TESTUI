// createBackup.js
// This worker script handles the backup process in the background

.pragma library
.import QtQuick.LocalStorage 2.0 as LS

WorkerScript.onMessage = function(message) {
    var sourcePath = message.sourcePath;
    var destinationPath = message.destinationPath || "";
    
    // Use a try-catch to handle any potential errors
    try {
        // Call the C++ method to create the backup
        var backupPath = iface.createFolderBackup(sourcePath, destinationPath);
        
        if (backupPath && backupPath.length > 0) {
            // Success
            WorkerScript.sendMessage({
                "success": true, 
                "backupPath": backupPath
            });
        } else {
            // Failure
            WorkerScript.sendMessage({
                "success": false, 
                "error": "Failed to create backup"
            });
        }
    } catch (e) {
        // Exception occurred
        WorkerScript.sendMessage({
            "success": false, 
            "error": "Exception: " + e.toString()
        });
    }
} 