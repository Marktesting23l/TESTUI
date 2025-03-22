#ifndef PROJECTBACKUPMANAGER_H
#define PROJECTBACKUPMANAGER_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QDir>

class ProjectBackupManager : public QObject
{
    Q_OBJECT
    
public:
    enum BackupMode {
        ProjectOnly,      // Only backup the project file
        ProjectAndGpkg   // Backup project file and associated GPKG files
    };
    Q_ENUM(BackupMode)

    explicit ProjectBackupManager(QObject *parent = nullptr);
    
    Q_INVOKABLE bool createBackup(const QString &projectPath, BackupMode mode = ProjectOnly);
    Q_INVOKABLE bool restoreBackup(const QString &backupPath, const QString &destinationPath);
    Q_INVOKABLE QStringList listBackups(const QString &projectName);
    Q_INVOKABLE bool deleteBackup(const QString &backupPath);
    
    QString getBackupDirectory() const { return mBackupDirectory; }
    void setBackupDirectory(const QString &path) { mBackupDirectory = path; }
    
private:
    QString mBackupDirectory;
    QString createBackupName(const QString &projectPath) const;
    bool copyDirectory(const QString &source, const QString &destination) const;
    bool removeDirectory(const QString &path) const;
    QStringList findAssociatedGpkgFiles(const QString &projectPath) const;
    bool copyFile(const QString &source, const QString &destination) const;
    
signals:
    void backupCreated(const QString &path);
    void backupRestored(const QString &path);
    void backupError(const QString &error);
    void backupProgress(const QString &message, int progress);
};

#endif // PROJECTBACKUPMANAGER_H 