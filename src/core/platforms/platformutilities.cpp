/***************************************************************************
                            platformutilities.cpp  -  utilities for qfield

                              -------------------
              begin                : Wed Dec 04 10:48:28 CET 2015
              copyright            : (C) 2015 by Marco Bernasocchi
              email                : marco@opengis.ch
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "appinterface.h"
#include "fileutils.h"
#include "platformutilities.h"
#include "projectsource.h"
#include "qfield.h"
#include <QSettings>
#include "qgsmessagelog.h"
#include "resourcesource.h"
#include "stringutils.h"
#include "urlutils.h"
#include <qgsexiftools.h>

#include <QApplication>
#include <QClipboard>
#include <QDebug>
#include <QDesktopServices>
#include <QDir>
#include <QFileDialog>
#include <QMargins>
#include <QMessageBox>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QTimer>
#include <QUrl>
#include <QtGui/qpa/qplatformwindow.h>

#if defined( Q_OS_ANDROID )
#include "androidplatformutilities.h"
Q_GLOBAL_STATIC( AndroidPlatformUtilities, sPlatformUtils )
#elif defined( Q_OS_IOS )
#include "ios/iosplatformutilities.h"
Q_GLOBAL_STATIC( IosPlatformUtilities, sPlatformUtils )
#else
Q_GLOBAL_STATIC( PlatformUtilities, sPlatformUtils )
#endif

PlatformUtilities::~PlatformUtilities()
{
}

PlatformUtilities::Capabilities PlatformUtilities::capabilities() const
{
  PlatformUtilities::Capabilities capabilities = PlatformUtilities::Capabilities() | FilePicker | NativeLocalDataPicker;
#if WITH_SENTRY
  capabilities |= SentryFramework;
#endif
  return capabilities;
}

void PlatformUtilities::copySampleProjects()
{
  const bool success = FileUtils::copyRecursively( systemSharedDataLocation() + QLatin1String( "/resources/sample_projects" ), systemLocalDataLocation( QLatin1String( "sample_projects" ) ) );
  Q_ASSERT( success );
  
  // Also copy the SIGPAC base map
  copySigpacBaseMap();
}

void PlatformUtilities::copySigpacBaseMap()
{
  // For Android and iOS, file copying is already handled by the Java copyAssets method
  // We just need to check if the file exists and create the directory if it doesn't
  QString targetDir;
#if defined( Q_OS_ANDROID ) || defined( Q_OS_IOS )
  // Use the same directory structure as sample_projects but with sigpacgo_base folder
  targetDir = appDataDirs().first() + QStringLiteral( "sigpacgo_base" );
  qDebug() << "Using Android/iOS app data directory for SIGPAC_BASE:" << targetDir;
#else
  // For desktop, keep using the system local data location
  targetDir = systemLocalDataLocation( QLatin1String( "sigpacgo_base" ) );
  qDebug() << "Using desktop app data directory for SIGPAC_BASE:" << targetDir;
  
  // Create the directory if it doesn't exist
  QDir targetDirObj(targetDir);
  if (!targetDirObj.exists())
  {
    targetDirObj.mkpath(".");
    qDebug() << "Created directory:" << targetDir;
  }
  
  // Check if the target already has the file
  QString targetFile = targetDir + QStringLiteral("/SIGPAC_BASE.qgz");
  if (QFile::exists(targetFile))
  {
    qDebug() << "SIGPAC_BASE.qgz already exists at" << targetFile;
  }
  else
  {
    // Try different source locations
    QStringList sourceDirs;
    // Original source directory
    sourceDirs << systemSharedDataLocation() + QLatin1String("/sigpacgo/sigpacgo_base");
    // Resources directory (Android assets)
    sourceDirs << systemSharedDataLocation() + QLatin1String("/resources/sigpacgo_base");
    // Resources directory (development)
    sourceDirs << QStringLiteral("/home/im/Documents/SIGPACGOEDITS/TESTUI-master/resources/sigpacgo_base");
    
    bool success = false;
    
    // Try each source directory
    for (const QString &sourceDir : sourceDirs)
    {
      QString sourceFile = sourceDir + QStringLiteral("/SIGPAC_BASE.qgz");
      if (QFile::exists(sourceFile))
      {
        success = QFile::copy(sourceFile, targetFile);
        if (success)
        {
          qDebug() << "Copied SIGPAC_BASE.qgz from" << sourceFile << "to" << targetFile;
          break;
        }
        else
        {
          qWarning() << "Failed to copy SIGPAC_BASE.qgz from" << sourceFile << "to" << targetFile;
        }
      }
      else
      {
        qDebug() << "Source file does not exist:" << sourceFile;
      }
    }
    
    // If direct file copy failed, try directory copy
    if (!success)
    {
      for (const QString &sourceDir : sourceDirs)
      {
        if (QDir(sourceDir).exists())
        {
          success = FileUtils::copyRecursively(sourceDir, targetDir);
          if (success)
          {
            qDebug() << "Copying SIGPAC base map directory from" << sourceDir << "to" << targetDir << "succeeded";
            break;
          }
          else
          {
            qWarning() << "Copying SIGPAC base map directory from" << sourceDir << "to" << targetDir << "failed";
          }
        }
      }
    }
    
    qDebug() << "Copying SIGPAC base map to" << targetDir << (success ? "succeeded" : "failed");
  }
#endif
  
  // Now handle the SIGPACGO Main Map
  copyMainMapProject();
}

void PlatformUtilities::copyMainMapProject()
{
  // For Android and iOS, file copying is already handled by the Java copyAssets method
  // We just need to check if the file exists and create the directory if it doesn't
  QString targetDir;
#if defined( Q_OS_ANDROID ) || defined( Q_OS_IOS )
  // Use the same directory structure as sigpacgo_base but with sigpacgo_main folder
  targetDir = appDataDirs().first() + QStringLiteral( "sigpacgo_main" );
  qDebug() << "Using Android/iOS app data directory for SIGPACGO Main Map:" << targetDir;
  
  // Create the directory if it doesn't exist
  QDir targetDirObj(targetDir);
  if (!targetDirObj.exists())
  {
    targetDirObj.mkpath(".");
    qDebug() << "Created directory:" << targetDir;
  }
  
  // Define target file name
  QString targetFile = targetDir + QStringLiteral("/SIGPACGO_Mapa_Principal.qgz");
  
  // Check if the target already has the file
  if (QFile::exists(targetFile))
  {
    qDebug() << "SIGPACGO_Mapa_Principal.qgz already exists at" << targetFile;
  }
  else
  {
    qDebug() << "SIGPACGO_Mapa_Principal.qgz does not exist at" << targetFile;
    qDebug() << "Copying should be handled by the Java copyAssets method";
    
    // Verify copy was successful by checking again
    if (QFile::exists(targetFile))
    {
      qDebug() << "Verified SIGPACGO_Mapa_Principal.qgz now exists at" << targetFile;
    }
    else
    {
      qWarning() << "SIGPACGO_Mapa_Principal.qgz still does not exist at" << targetFile;
      // If no file exists after Java tried to copy it, create an empty README file to indicate the issue
      QString noteFile = targetDir + QStringLiteral("/README.txt");
      QFile file(noteFile);
      if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << "SIGPACGO main map file could not be copied.\n";
        out << "Please reinstall the application or contact support.\n";
        file.close();
        qDebug() << "Created README.txt in" << targetDir << "to document the copy failure";
      }
    }
  }
#else
  // For desktop, keep using the system local data location
  targetDir = systemLocalDataLocation( QLatin1String( "sigpacgo_main" ) );
  qDebug() << "Using desktop app data directory for SIGPACGO Main Map:" << targetDir;
  
  // Create the directory if it doesn't exist
  QDir targetDirObj(targetDir);
  if (!targetDirObj.exists())
  {
    targetDirObj.mkpath(".");
    qDebug() << "Created directory:" << targetDir;
  }
  
  // Define target file name
  QString targetFile = targetDir + QStringLiteral("/SIGPACGO_Mapa_Principal.qgz");
  
  // Check if the target already has the file
  if (QFile::exists(targetFile))
  {
    qDebug() << "SIGPACGO_Mapa_Principal.qgz already exists at" << targetFile;
    return;
  }
  
  // Define all possible source directories
  QStringList sourceDirs;
  // Resources directory (standard location)
  sourceDirs << systemSharedDataLocation() + QLatin1String("/resources/SIGPACGO Principal");
  // Resources directory (alternative name)
  sourceDirs << systemSharedDataLocation() + QLatin1String("/resources/SIGPACGO Mapa Principal");
  // Original source directory
  sourceDirs << systemSharedDataLocation() + QLatin1String("/sigpacgo/main_project");
  // Resources directory (development)
  sourceDirs << QStringLiteral("/home/im/Documents/SIGPACGOEDITS/TESTUI-master/resources/SIGPACGO Principal");
  // Alternative development path
  sourceDirs << QStringLiteral("/home/im/Documents/SIGPACGOEDITS/TESTUI-master/resources/SIGPACGO Mapa Principal");
  
  // Log all source directories being checked
  qDebug() << "Checking source directories for SIGPACGO Main Map:";
  for (const QString &dir : sourceDirs) {
    qDebug() << " - " << dir << (QDir(dir).exists() ? "(exists)" : "(not found)");
  }
  
  bool success = false;
  
  // Define all possible file names to look for
  QStringList possibleFiles;
  possibleFiles << QStringLiteral("/SIGPACGO_Principal.qgz");            // Actual file name
  possibleFiles << QStringLiteral("/SIGPACGO_Mapa_Principal.qgz");       // Target file name
  possibleFiles << QStringLiteral("/SIGPACGO Mapa Principal.qgz");       // Alternative with spaces
  possibleFiles << QStringLiteral("/SIGPACGO Principal.qgz");            // Alternative with spaces
  possibleFiles << QStringLiteral("/SIGPACGO Mapa Pincipal.qgz");        // Typo variant
  
  // Try each source directory and file combination
  for (const QString &sourceDir : sourceDirs)
  {
    if (!QDir(sourceDir).exists())
    {
      continue; // Skip non-existent directories
    }
    
    for (const QString &fileName : possibleFiles)
    {
      QString sourceFile = sourceDir + fileName;
      if (QFile::exists(sourceFile))
      {
        qDebug() << "Found source file:" << sourceFile;
        
        // Try to copy the file
        success = QFile::copy(sourceFile, targetFile);
        if (success)
        {
          qDebug() << "Copied SIGPACGO Main Map from" << sourceFile << "to" << targetFile;
          return;
        }
        else
        {
          qWarning() << "Failed to copy SIGPACGO Main Map from" << sourceFile << "to" << targetFile 
                    << "- Error:" << strerror(errno);
        }
      }
    }
    
    // If file copy failed, try to copy entire directory
    success = FileUtils::copyRecursively(sourceDir, targetDir);
    if (success)
    {
      qDebug() << "Copying SIGPACGO Main Map directory from" << sourceDir << "to" << targetDir << "succeeded";
      
      // Ensure the file is properly named in the target directory
      QDir dir(targetDir);
      QStringList files = dir.entryList(QDir::Files);
      qDebug() << "Files in target directory:" << files;
      
      bool fileRenamed = false;
      for (const QString &file : files)
      {
        // Look for project files and rename to the standard name if needed
        if (file.contains("Principal", Qt::CaseInsensitive))
        {
          if (file != "SIGPACGO_Mapa_Principal.qgz")
          {
            bool renameSuccess = dir.rename(file, "SIGPACGO_Mapa_Principal.qgz");
            qDebug() << "Renamed" << file << "to SIGPACGO_Mapa_Principal.qgz" << (renameSuccess ? "succeeded" : "failed");
            if (renameSuccess) {
              fileRenamed = true;
            }
          }
          else
          {
            fileRenamed = true; // File already has the correct name
          }
          break;
        }
      }
      
      // If we couldn't find a file to rename, we need to handle this special case
      if (!fileRenamed && !files.isEmpty())
      {
        // Just take the first project file and rename it
        for (const QString &file : files)
        {
          if (file.endsWith(".qgz"))
          {
            bool renameSuccess = dir.rename(file, "SIGPACGO_Mapa_Principal.qgz");
            qDebug() << "Renamed alternate file" << file << "to SIGPACGO_Mapa_Principal.qgz" 
                     << (renameSuccess ? "succeeded" : "failed");
            break;
          }
        }
      }
      
      // Check if the target file now exists
      if (QFile::exists(targetFile))
      {
        return;
      }
    }
    else
    {
      qWarning() << "Copying SIGPACGO Main Map directory from" << sourceDir << "to" << targetDir << "failed";
    }
  }
  
  // Last resort: try to manually copy the file from sample_projects if available
  QString sampleProjectsDir = systemLocalDataLocation( QLatin1String( "sample_projects" ) );
  if (QDir(sampleProjectsDir).exists())
  {
    qDebug() << "Trying to find a suitable project file in sample_projects...";
    QStringList sampleProjects = QDir(sampleProjectsDir).entryList(QStringList() << "*.qgz", QDir::Files);
    if (!sampleProjects.isEmpty())
    {
      QString sourceSample = sampleProjectsDir + "/" + sampleProjects.first();
      success = QFile::copy(sourceSample, targetFile);
      if (success)
      {
        qDebug() << "Copied sample project" << sourceSample << "as main map to" << targetFile;
        return;
      }
    }
  }
  
  qDebug() << "Copying SIGPACGO Main Map to" << targetDir << (success ? "succeeded" : "failed");
  
  // If all else failed, create a simple text file to indicate the problem
  if (!success) {
    QString noteFile = targetDir + QStringLiteral("/README.txt");
    QFile file(noteFile);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
      QTextStream out(&file);
      out << "Failed to copy the SIGPACGO Main Map.\n";
      out << "Please reinstall the application or contact support.\n";
      out << "Checked directories:\n";
      for (const QString &dir : sourceDirs) {
        out << " - " << dir << "\n";
      }
      file.close();
      qDebug() << "Created README.txt in" << targetDir << "to document the copy failure";
    }
  }
#endif
}

void PlatformUtilities::initSystem()
{
  const QString appDataLocation = QStandardPaths::writableLocation( QStandardPaths::AppDataLocation );
  QFile gitRevFile( appDataLocation + QStringLiteral( "/gitRev" ) );
  QByteArray localGitRev;
  if ( gitRevFile.open( QIODevice::ReadOnly ) )
  {
    localGitRev = gitRevFile.readAll();
  }
  gitRevFile.close();
  QByteArray appGitRev = qfield::gitRev.toUtf8();
  if ( localGitRev != appGitRev )
  {
    afterUpdate();
    copySampleProjects();

    gitRevFile.open( QIODevice::WriteOnly | QIODevice::Truncate );
    gitRevFile.write( appGitRev );
    gitRevFile.close();
  }
}

void PlatformUtilities::afterUpdate()
{
  const QStringList dirs = appDataDirs();
  for ( const QString &dir : dirs )
  {
    QDir appDataDir( dir );
    appDataDir.mkpath( QStringLiteral( "proj" ) );
    appDataDir.mkpath( QStringLiteral( "auth" ) );
    appDataDir.mkpath( QStringLiteral( "fonts" ) );
    appDataDir.mkpath( QStringLiteral( "basemaps" ) );
    appDataDir.mkpath( QStringLiteral( "logs" ) );
    appDataDir.mkpath( QStringLiteral( "plugins" ) );
  }

  QDir applicationDir( applicationDirectory() );
  applicationDir.mkpath( QStringLiteral( "Imported Projects" ) );
  applicationDir.mkpath( QStringLiteral( "Imported Datasets" ) );
}

QString PlatformUtilities::systemSharedDataLocation() const
{
  /**
   * By default, assume that we have a layout like this:
   *
   * [prefix_path]
   * |-- bin
   * |   |-- qfield.exe
   * |-- share
   * |   |-- qfield
   * |   |   |-- sample_projects
   * |   |-- proj
   * |   |   |-- data
   * |   |   |   |--  proj.db
   *
   * systemSharedDataLocation()'s return value will therefore be - relative to qfield.exe - '../share'.
   * However it is possible to override this default logic through a environment variable named
   * QFIELD_SYSTEM_SHARED_DATA_PATH. If present, its value will be used as the return value instead.
  */
  const static QString sharePath = QDir( QFileInfo( !QCoreApplication::applicationFilePath().isEmpty() ? QCoreApplication::applicationFilePath() : QCoreApplication::arguments().value( 0 ) ).canonicalPath()
                                         + QLatin1String( "/../share" ) )
                                     .absolutePath();
  const static QString environmentSharePath = QString( qgetenv( "QFIELD_SYSTEM_SHARED_DATA_PATH" ) );
  return !environmentSharePath.isEmpty() ? QDir( environmentSharePath ).absolutePath() : sharePath;
}

QString PlatformUtilities::systemLocalDataLocation( const QString &subDir ) const
{
  return QStandardPaths::writableLocation( QStandardPaths::AppDataLocation ) + ( !subDir.isEmpty() ? '/' + subDir : QString() );
}

bool PlatformUtilities::hasQgsProject() const
{
  return qApp->arguments().count() > 1 && !qApp->arguments().last().isEmpty();
}

void PlatformUtilities::loadQgsProject() const
{
  if ( hasQgsProject() )
  {
    AppInterface::instance()->loadFile( qApp->arguments().last() );
  }
}

QStringList PlatformUtilities::appDataDirs() const
{
  QString appDataDir = QStandardPaths::standardLocations( QStandardPaths::DocumentsLocation ).first() + QStringLiteral( "/SIGPACGO Documents/SIGPACGO/" );
  
  // Ensure the directory exists
  QDir dir(appDataDir);
  if (!dir.exists())
  {
    dir.mkpath(".");
  }
  
  return QStringList() << appDataDir;
}

QStringList PlatformUtilities::availableGrids() const
{
  QStringList dataDirs = appDataDirs();
  QStringList grids;
  for ( const QString &dataDir : dataDirs )
  {
    QDir gridsDir( dataDir + "proj/" );
    if ( gridsDir.exists() )
    {
      grids << gridsDir.entryList( QStringList() << QStringLiteral( "*.tif" ) << QStringLiteral( "*.gtx" ) << QStringLiteral( "*.gsb" ) << QStringLiteral( "*.byn" ) );
    }
  }
  return grids;
}

bool PlatformUtilities::createDir( const QString &path, const QString &dirname ) const
{
  QDir parentDir( path );
  return parentDir.mkdir( dirname );
}

bool PlatformUtilities::rmFile( const QString &filename ) const
{
  QFile file( filename );
  return file.remove();
}

bool PlatformUtilities::renameFile( const QString &oldFilePath, const QString &newFilePath, bool overwrite ) const
{
  QFileInfo oldFi( oldFilePath );
  QFileInfo newFi( newFilePath );
  if ( oldFi.absoluteFilePath() == newFi.absoluteFilePath() )
  {
    return true;
  }

  // Insure the path exists
  QDir dir( newFi.absolutePath() );
  dir.mkpath( newFi.absolutePath() );

  // If the renamed file exists, overwrite
  if ( newFi.exists() && overwrite )
  {
    QFile newfile( newFilePath );
    newfile.remove();
  }

  return QFile::rename( oldFilePath, newFilePath );
}

QString PlatformUtilities::applicationDirectory() const
{
  QString appDir = QStandardPaths::standardLocations( QStandardPaths::DocumentsLocation ).first() + QStringLiteral( "/SIGPACGO Documents/" );
  
  // Ensure the directory exists
  QDir dir(appDir);
  if (!dir.exists())
  {
    dir.mkpath(".");
  }
  
  // Also ensure the SIGPACGO subdirectory exists
  QDir sigpacgoDir(appDir + "SIGPACGO/");
  if (!sigpacgoDir.exists())
  {
    sigpacgoDir.mkpath(".");
  }
  
  return appDir;
}

QStringList PlatformUtilities::additionalApplicationDirectories() const
{
  return QStringList() << QString();
}

QStringList PlatformUtilities::rootDirectories() const
{
  QStringList rootDirectories;
  rootDirectories << QDir::homePath();
  for ( const QStorageInfo &volume : QStorageInfo::mountedVolumes() )
  {
    if ( volume.isReady() && !volume.isReadOnly() )
    {
      if ( volume.fileSystemType() != QLatin1String( "tmpfs" ) && !volume.rootPath().startsWith( QLatin1String( "/boot" ) ) )
      {
        rootDirectories << volume.rootPath();
      }
    }
  }
  return rootDirectories;
}

void PlatformUtilities::importProjectFolder() const
{}

void PlatformUtilities::importProjectArchive() const
{}

void PlatformUtilities::importDatasets() const
{}

void PlatformUtilities::updateProjectFromArchive( const QString &projectPath ) const
{
  Q_UNUSED( projectPath )
}

void PlatformUtilities::exportFolderTo( const QString &path ) const
{
  Q_UNUSED( path )
}

void PlatformUtilities::exportDatasetTo( const QString &path ) const
{
  Q_UNUSED( path )
}

void PlatformUtilities::sendDatasetTo( const QString &path ) const
{
  Q_UNUSED( path )
}

void PlatformUtilities::sendCompressedFolderTo( const QString &path ) const
{
  Q_UNUSED( path )
}

void PlatformUtilities::removeDataset( const QString &path ) const
{
  bool allowed = false;
  const QStringList allowedDirectories = QStringList() << applicationDirectory() << additionalApplicationDirectories();
  for ( const QString &directory : allowedDirectories )
  {
    if ( path.startsWith( directory ) )
    {
      allowed = true;
      break;
    }
  }
  if ( allowed )
  {
    if ( QMessageBox::warning( nullptr,
                               tr( "Removal Confirmation" ),
                               tr( "The dataset will be deleted, proceed with removal?" ),
                               QMessageBox::StandardButtons() | QMessageBox::Ok | QMessageBox::Abort )
         == QMessageBox::Ok )
    {
      QFile::moveToTrash( path );
    }
  }
}

void PlatformUtilities::removeFolder( const QString &path ) const
{
  bool allowed = false;
  const QStringList allowedDirectories = QStringList() << applicationDirectory() << additionalApplicationDirectories();
  for ( const QString &directory : allowedDirectories )
  {
    if ( path.startsWith( directory ) )
    {
      allowed = true;
      break;
    }
  }
  if ( allowed )
  {
    if ( QMessageBox::warning( nullptr,
                               tr( "Removal Confirmation" ),
                               tr( "The project folder will be deleted, proceed with removal?" ),
                               QMessageBox::StandardButtons() | QMessageBox::Ok | QMessageBox::Abort )
         == QMessageBox::Ok )
    {
      QFile::moveToTrash( path );
    }
  }
}

ResourceSource *PlatformUtilities::getCameraPicture( const QString &, const QString &, const QString &, QObject * )
{
  return nullptr;
}

ResourceSource *PlatformUtilities::getCameraVideo( const QString &, const QString &, const QString &, QObject * )
{
  return nullptr;
}

ResourceSource *PlatformUtilities::createResource( const QString &prefix, const QString &filePath, const QString &fileName, QObject *parent )
{
  QFileInfo fi( fileName );
  if ( fi.exists() )
  {
    // if the file is already in the prefixed path, no need to copy
    if ( fileName.startsWith( prefix ) )
    {
      return new ResourceSource( parent, prefix, fileName );
    }
    else
    {
      QString finalFilePath = StringUtils::replaceFilenameTags( filePath, fi.fileName() );
      QString destinationFile = prefix + finalFilePath;
      QFileInfo destinationInfo( destinationFile );
      QDir prefixDir( prefix );
      if ( prefixDir.mkpath( destinationInfo.absolutePath() ) && QFile::copy( fileName, destinationFile ) )
      {
        return new ResourceSource( parent, prefix, destinationFile );
      }
    }

    QgsMessageLog::logMessage( tr( "Failed to save file resource" ), "QField", Qgis::Critical );
  }

  return new ResourceSource( parent, prefix, QString() );
}

ResourceSource *PlatformUtilities::getGalleryPicture( const QString &prefix, const QString &pictureFilePath, QObject *parent )
{
  QString fileName = QFileDialog::getOpenFileName( nullptr, tr( "Select Image File" ), prefix,
                                                   tr( "All images (*.jpg *.jpeg *.png *.bmp);;JPEG images (*.jpg *.jpeg);;PNG images (*.jpg *.jpeg);;BMP images (*.bmp)" ) );
  return createResource( prefix, pictureFilePath, fileName, parent );
}

ResourceSource *PlatformUtilities::getGalleryVideo( const QString &prefix, const QString &videoFilePath, QObject *parent )
{
  QString fileName = QFileDialog::getOpenFileName( nullptr, tr( "Select Video File" ), prefix,
                                                   tr( "All video (*.mp4 *.mkv *.mov);;MP4 video (*.mp4);;MKV video(*.mkv);;MOV video (*.mov)" ) );
  return createResource( prefix, videoFilePath, fileName, parent );
}

ResourceSource *PlatformUtilities::getFile( const QString &prefix, const QString &filePath, FileType fileType, QObject *parent )
{
  QString filter;
  switch ( fileType )
  {
    case AudioFiles:
      filter = tr( "Audio files (*.mp3 *.aac *.ogg *.m4a *.mp4 *.mov)" );
      break;

    case AllFiles:
    default:
      filter = tr( "All files (*.*)" );
      break;
  }

  QString fileName = QFileDialog::getOpenFileName( nullptr, tr( "Select File" ), prefix, filter );
  return createResource( prefix, filePath, fileName, parent );
}

ViewStatus *PlatformUtilities::open( const QString &uri, bool, QObject * )
{
  QDesktopServices::openUrl( UrlUtils::fromString( uri ) );
  return nullptr;
}

ProjectSource *PlatformUtilities::openProject( QObject * )
{
  QSettings settings;
  ProjectSource *source = new ProjectSource();
  QString fileName { QFileDialog::getOpenFileName( nullptr,
                                                   tr( "Open File" ),
                                                   settings.value( QStringLiteral( "QField/lastOpenDir" ), QString() ).toString(),
                                                   QStringLiteral( "%1 (*.%2);;%3 (*.%4);;%5 (*.%6);;%7 (*.%8)" ).arg( tr( "All Supported Files" ), ( SUPPORTED_PROJECT_EXTENSIONS + SUPPORTED_VECTOR_EXTENSIONS + SUPPORTED_RASTER_EXTENSIONS ).join( QStringLiteral( " *." ) ), tr( "QGIS Project Files" ), SUPPORTED_PROJECT_EXTENSIONS.join( QStringLiteral( " *." ) ), tr( "Vector Datasets" ), SUPPORTED_VECTOR_EXTENSIONS.join( QStringLiteral( " *." ) ), tr( "Raster Datasets" ), SUPPORTED_RASTER_EXTENSIONS.join( QStringLiteral( " *." ) ) ) ) };
  if ( !fileName.isEmpty() )
  {
    settings.setValue( QStringLiteral( "/QField/lastOpenDir" ), QFileInfo( fileName ).absolutePath() );
    QTimer::singleShot( 0, this, [source, fileName]() { emit source->projectOpened( fileName ); } );
  }
  return source;
}

bool PlatformUtilities::checkPositioningPermissions() const
{
  return true;
}

bool PlatformUtilities::checkCameraPermissions() const
{
  return true;
}

bool PlatformUtilities::checkMicrophonePermissions() const
{
  return true;
}

void PlatformUtilities::copyTextToClipboard( const QString &string ) const
{
  QGuiApplication::clipboard()->setText( string );
}

QString PlatformUtilities::getTextFromClipboard() const
{
  return QGuiApplication::clipboard()->text();
}

bool PlatformUtilities::setExifTag(const QString &imagePath, const QString &tag, const QString &value) const
{
  if (!QFileInfo::exists(imagePath))
  {
    return false;
  }
  
  return QgsExifTools::tagImage(imagePath, tag, value);
}

QVariantMap PlatformUtilities::sceneMargins( QQuickWindow *window ) const
{
  QVariantMap margins;
  margins[QLatin1String( "top" )] = 0.0;
  margins[QLatin1String( "right" )] = 0.0;
  margins[QLatin1String( "bottom" )] = 0.0;
  margins[QLatin1String( "left" )] = 0.0;

  QPlatformWindow *platformWindow = static_cast<QPlatformWindow *>( window->handle() );
  if ( platformWindow )
  {
    margins[QLatin1String( "top" )] = platformWindow->safeAreaMargins().top();
    margins[QLatin1String( "bottom" )] = platformWindow->safeAreaMargins().bottom();
  }

  return margins;
}

double PlatformUtilities::systemFontPointSize() const
{
  return QApplication::font().pointSizeF() + 2.0;
}



bool PlatformUtilities::isSystemDarkTheme() const
{
  return false;
}

PlatformUtilities *PlatformUtilities::instance()
{
  return sPlatformUtils;
}

Qt::PermissionStatus PlatformUtilities::checkCameraPermission() const
{
  QCameraPermission cameraPermission;
  return qApp->checkPermission( cameraPermission );
}

void PlatformUtilities::requestCameraPermission( std::function<void( Qt::PermissionStatus )> func )
{
  QCameraPermission cameraPermission;
  qApp->requestPermission( cameraPermission, [=]( const QPermission &permission ) { func( permission.status() ); } );
}

Qt::PermissionStatus PlatformUtilities::checkMicrophonePermission() const
{
  QMicrophonePermission microphonePermission;
  return qApp->checkPermission( microphonePermission );
}

void PlatformUtilities::requestMicrophonePermission( std::function<void( Qt::PermissionStatus )> func )
{
  QMicrophonePermission microphonePermission;
  qApp->requestPermission( microphonePermission, [=]( const QPermission &permission ) { func( permission.status() ); } );
}

QVariantMap PlatformUtilities::getFileInfo(const QString &filePath) const
{
  QVariantMap result;
  QFileInfo fileInfo(filePath);
  
  result["exists"] = fileInfo.exists();
  result["isFile"] = fileInfo.isFile();
  result["isDir"] = fileInfo.isDir();
  result["size"] = fileInfo.size();
  result["lastModified"] = fileInfo.lastModified();
  
  return result;
}
