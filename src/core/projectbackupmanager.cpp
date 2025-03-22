#include "projectbackupmanager.h"
#include <QStandardPaths>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QDebug>
#include <QTextStream>
#include <QRegularExpression>

ProjectBackupManager::ProjectBackupManager(QObject *parent)
    : QObject(parent)
{
    // Set up backup directory in app's data location
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    mBackupDirectory = appDataPath + QStringLiteral("/backups");
    
    // Ensure backup directory exists
    QDir dir;
    if (!dir.exists(mBackupDirectory))
    {
        dir.mkpath(mBackupDirectory);
    }
}

bool ProjectBackupManager::createBackup(const QString &projectPath, BackupMode mode)
{
    QFileInfo projectInfo(projectPath);
    if (!projectInfo.exists())
    {
        emit backupError(tr("Project file does not exist: %1").arg(projectPath));
        return false;
    }
    
    // Create backup name with timestamp
    QString backupName = createBackupName(projectPath);
    QString backupPath = mBackupDirectory + "/" + backupName;
    
    // Create backup directory
    QDir backupDir(backupPath);
    if (!backupDir.exists() && !backupDir.mkpath("."))
    {
        emit backupError(tr("Could not create backup directory: %1").arg(backupPath));
        return false;
    }

    // Always copy the project file
    QString projectFileName = projectInfo.fileName();
    QString destProjectPath = backupPath + "/" + projectFileName;
    
    emit backupProgress(tr("Copying project file..."), 0);
    if (!copyFile(projectPath, destProjectPath))
    {
        emit backupError(tr("Failed to copy project file"));
        return false;
    }

    // If mode is ProjectAndGpkg, also backup GPKG files
    if (mode == ProjectAndGpkg)
    {
        QStringList gpkgFiles = findAssociatedGpkgFiles(projectPath);
        if (!gpkgFiles.isEmpty())
        {
            QString dataDir = backupPath + "/data";
            if (!QDir().mkpath(dataDir))
            {
                emit backupError(tr("Could not create data directory for GPKG files"));
                return false;
            }

            int total = gpkgFiles.size();
            for (int i = 0; i < gpkgFiles.size(); ++i)
            {
                QString gpkgFile = gpkgFiles[i];
                QFileInfo gpkgInfo(gpkgFile);
                QString destGpkgPath = dataDir + "/" + gpkgInfo.fileName();
                
                emit backupProgress(tr("Copying GPKG file %1 of %2...").arg(i + 1).arg(total), (i * 100) / total);
                
                if (!copyFile(gpkgFile, destGpkgPath))
                {
                    emit backupError(tr("Failed to copy GPKG file: %1").arg(gpkgFile));
                    return false;
                }
            }
        }
    }
    
    emit backupProgress(tr("Backup completed"), 100);
    emit backupCreated(backupPath);
    return true;
}

bool ProjectBackupManager::restoreBackup(const QString &backupPath, const QString &destinationPath)
{
    QDir backupDir(backupPath);
    if (!backupDir.exists())
    {
        emit backupError(tr("Backup directory does not exist: %1").arg(backupPath));
        return false;
    }
    
    QDir destDir(destinationPath);
    if (destDir.exists())
    {
        // Remove existing project directory
        if (!removeDirectory(destinationPath))
        {
            emit backupError(tr("Could not remove existing project directory: %1").arg(destinationPath));
            return false;
        }
    }
    
    // Create destination directory
    if (!destDir.mkpath("."))
    {
        emit backupError(tr("Could not create destination directory: %1").arg(destinationPath));
        return false;
    }
    
    // Copy backup to destination
    if (!copyDirectory(backupPath, destinationPath))
    {
        emit backupError(tr("Failed to restore backup files"));
        return false;
    }
    
    emit backupRestored(destinationPath);
    return true;
}

QStringList ProjectBackupManager::listBackups(const QString &projectName)
{
    QDir backupDir(mBackupDirectory);
    QStringList nameFilters;
    nameFilters << projectName + "_*";
    
    return backupDir.entryList(nameFilters, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Time);
}

bool ProjectBackupManager::deleteBackup(const QString &backupPath)
{
    return removeDirectory(backupPath);
}

QString ProjectBackupManager::createBackupName(const QString &projectPath) const
{
    QFileInfo projectInfo(projectPath);
    QString projectName = projectInfo.baseName();
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
    
    return QString("%1_%2").arg(projectName, timestamp);
}

bool ProjectBackupManager::copyDirectory(const QString &source, const QString &destination) const
{
    QDir sourceDir(source);
    QDir destDir(destination);
    
    // Create the destination directory if it doesn't exist
    if (!destDir.exists() && !destDir.mkpath("."))
    {
        return false;
    }
    
    // Copy all files and subdirectories
    foreach(const QFileInfo &info, sourceDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot))
    {
        QString srcPath = info.absoluteFilePath();
        QString destPath = destDir.absolutePath() + "/" + info.fileName();
        
        if (info.isDir())
        {
            if (!copyDirectory(srcPath, destPath))
            {
                return false;
            }
        }
        else
        {
            if (QFile::exists(destPath))
            {
                QFile::remove(destPath);
            }
            if (!QFile::copy(srcPath, destPath))
            {
                return false;
            }
        }
    }
    
    return true;
}

bool ProjectBackupManager::removeDirectory(const QString &path) const
{
    QDir dir(path);
    if (!dir.exists())
        return true;
    
    bool success = true;
    foreach(const QFileInfo &info, dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot))
    {
        if (info.isDir())
        {
            success = removeDirectory(info.absoluteFilePath());
        }
        else
        {
            success = QFile::remove(info.absoluteFilePath());
        }
        
        if (!success)
            return false;
    }
    
    return dir.rmdir(path);
}

bool ProjectBackupManager::copyFile(const QString &source, const QString &destination) const
{
    if (QFile::exists(destination))
    {
        QFile::remove(destination);
    }
    return QFile::copy(source, destination);
}

QStringList ProjectBackupManager::findAssociatedGpkgFiles(const QString &projectPath) const
{
    QStringList gpkgFiles;
    QFile projectFile(projectPath);
    if (!projectFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return gpkgFiles;

    QTextStream in(&projectFile);
    QString content = in.readAll();
    projectFile.close();

    // Look for GPKG files in the project content
    QRegularExpression re("source=\"([^\"]*\\.gpkg)\"");
    QRegularExpressionMatchIterator i = re.globalMatch(content);
    
    QDir projectDir(QFileInfo(projectPath).absolutePath());
    while (i.hasNext()) {
        QRegularExpressionMatch match = i.next();
        QString gpkgPath = match.captured(1);
        
        // Handle relative paths
        if (QFileInfo(gpkgPath).isRelative()) {
            gpkgPath = projectDir.absoluteFilePath(gpkgPath);
        }
        
        if (!gpkgFiles.contains(gpkgPath) && QFile::exists(gpkgPath)) {
            gpkgFiles << gpkgPath;
        }
    }
    
    return gpkgFiles;
} 