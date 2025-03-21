/***************************************************************************
                            appinterface.cpp
                              -------------------
              begin                : 10.12.2014
              copyright            : (C) 2014 by Matthias Kuhn
              email                : matthias (at) opengis.ch
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
#include "platformutilities.h"
#include "qfield.h"
#include "qgismobileapp.h"
#if WITH_SENTRY
#include "sentry_wrapper.h"
#endif

#include <QDirIterator>
#include <QFileInfo>
#include <QImageReader>
#include <QQuickItem>
#include <QTemporaryFile>
#include <qgsapplication.h>
#include <qgsmessagelog.h>
#include <qgsproject.h>
#include <qgsruntimeprofiler.h>
#include <qgsziputils.h>

// Add missing include files for print functionality
#include <qgslayoutmanager.h>
#include <qgsprintlayout.h>

// Add includes for GeoPackage layer support
#include <qgsproviderregistry.h>
#include <qgsvectorlayer.h>
#include <qgsrasterlayer.h>
#include <qgsprovidermetadata.h>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <qgslayertree.h>
#include <qgslayertreegroup.h>
#include <qgslayertreelayer.h>

#include <QDateTime>
#include <QProcess>
#include <QStandardPaths>

AppInterface *AppInterface::sAppInterface = nullptr;

AppInterface::AppInterface( QgisMobileapp *app )
  : mApp( app )
{
}

QObject *AppInterface::findItemByObjectName( const QString &name ) const
{
  if ( !mApp->rootObjects().isEmpty() )
  {
    return mApp->rootObjects().at( 0 )->findChild<QObject *>( name );
  }
  return nullptr;
}

void AppInterface::addItemToPluginsToolbar( QQuickItem *item ) const
{
  if ( !mApp->rootObjects().isEmpty() )
  {
    QQuickItem *toolbar = mApp->rootObjects().at( 0 )->findChild<QQuickItem *>( QStringLiteral( "pluginsToolbar" ) );
    item->setParentItem( toolbar );
  }
}

void AppInterface::addItemToCanvasActionsToolbar( QQuickItem *item ) const
{
  if ( !mApp->rootObjects().isEmpty() )
  {
    QQuickItem *toolbar = mApp->rootObjects().at( 0 )->findChild<QQuickItem *>( QStringLiteral( "canvasMenuActionsToolbar" ) );
    item->setParentItem( toolbar );
  }
}

void AppInterface::addItemToDashboardActionsToolbar( QQuickItem *item ) const
{
  if ( !mApp->rootObjects().isEmpty() )
  {
    QQuickItem *toolbar = mApp->rootObjects().at( 0 )->findChild<QQuickItem *>( QStringLiteral( "dashboardActionsToolbar" ) );
    item->setParentItem( toolbar );
  }
}

void AppInterface::addItemToMainMenuActionsToolbar( QQuickItem *item ) const
{
  addItemToDashboardActionsToolbar( item );
}

QObject *AppInterface::mainWindow() const
{
  if ( !mApp->rootObjects().isEmpty() )
  {
    return mApp->rootObjects().at( 0 );
  }
  return nullptr;
}

QObject *AppInterface::mapCanvas() const
{
  if ( !mApp->rootObjects().isEmpty() )
  {
    return mApp->rootObjects().at( 0 )->findChild<QObject *>( "mapCanvas" );
  }
  return nullptr;
}

void AppInterface::removeRecentProject( const QString &path )
{
  return mApp->removeRecentProject( path );
}

bool AppInterface::hasProjectOnLaunch() const
{
  if ( PlatformUtilities::instance()->hasQgsProject() )
  {
    return true;
  }
  else
  {
    if ( QSettings().value( "/QField/loadProjectOnLaunch", true ).toBool() )
    {
      const QString lastProjectFilePath = QSettings().value( QStringLiteral( "QField/lastProjectFilePath" ), QString() ).toString();
      if ( !lastProjectFilePath.isEmpty() && QFileInfo::exists( lastProjectFilePath ) )
      {
        return true;
      }
    }
  }
  return false;
}

bool AppInterface::loadFile( const QString &path, const QString &name )
{
  qInfo() << QStringLiteral( "AppInterface loading file: %1" ).arg( path );
  if ( QFileInfo::exists( path ) )
  {
    return mApp->loadProjectFile( path, name );
  }

  const QUrl url( path );
  return mApp->loadProjectFile( url.isLocalFile() ? url.toLocalFile() : url.path(), name );
}

void AppInterface::reloadProject()
{
  return mApp->reloadProjectFile();
}

void AppInterface::readProject()
{
  return mApp->readProjectFile();
}

QString AppInterface::readProjectEntry( const QString &scope, const QString &key, const QString &def ) const
{
  return mApp->readProjectEntry( scope, key, def );
}

int AppInterface::readProjectNumEntry( const QString &scope, const QString &key, int def ) const
{
  return mApp->readProjectNumEntry( scope, key, def );
}

double AppInterface::readProjectDoubleEntry( const QString &scope, const QString &key, double def ) const
{
  return mApp->readProjectDoubleEntry( scope, key, def );
}

bool AppInterface::readProjectBoolEntry( const QString &scope, const QString &key, bool def ) const
{
  return mApp->readProjectBoolEntry( scope, key, def );
}

bool AppInterface::print( const QString &layoutName )
{
  QgsMessageLog::logMessage(QStringLiteral("Print request received for layout: %1").arg(layoutName.isEmpty() ? "default" : layoutName), QStringLiteral("SIGPACGO"), Qgis::Info);
  
  QgsProject* project = QgsProject::instance();
  if (!project)
  {
    QgsMessageLog::logMessage(QStringLiteral("Cannot print: No active project"), QStringLiteral("SIGPACGO"), Qgis::Warning);
    return false;
  }
  
  const QList<QgsPrintLayout*> printLayouts = project->layoutManager()->printLayouts();
  QgsMessageLog::logMessage(QStringLiteral("Available print layouts: %1").arg(printLayouts.size()), QStringLiteral("SIGPACGO"), Qgis::Info);
  
  for (const QgsPrintLayout* layout : printLayouts)
  {
    QgsMessageLog::logMessage(QStringLiteral("  - Layout: %1").arg(layout->name()), QStringLiteral("SIGPACGO"), Qgis::Info);
  }
  
  return mApp->print( layoutName );
}

bool AppInterface::printAtlasFeatures( const QString &layoutName, const QList<long long> &featureIds )
{
  return mApp->printAtlasFeatures( layoutName, featureIds );
}

void AppInterface::openFeatureForm()
{
  emit openFeatureFormRequested();
}

void AppInterface::setScreenDimmerTimeout( int timeoutSeconds )
{
  mApp->setScreenDimmerTimeout( timeoutSeconds );
}

void AppInterface::setCustomWmsParameters( const QVariantMap &parameters )
{
  // Store the custom WMS parameters in the project
  QgsProject *project = QgsProject::instance();
  if (project)
  {
    // Save each parameter as a project variable
    QVariantMap::const_iterator i = parameters.constBegin();
    while (i != parameters.constEnd())
    {
      project->writeEntry("Sentinel", QString("CustomWmsParam_%1").arg(i.key()), i.value().toString());
      ++i;
    }
    
    // Set a flag indicating custom parameters are in use
    project->writeEntry("Sentinel", "UseCustomWmsParams", true);
  }
}

QVariantMap AppInterface::availableLanguages() const
{
  QVariantMap languages;
  QDirIterator it( QStringLiteral( ":/i18n/" ), { QStringLiteral( "*.qm" ) }, QDir::Files );
  while ( it.hasNext() )
  {
    it.next();
    if ( it.fileName().startsWith( "qfield_" ) )
    {
      const qsizetype delimiter = it.fileName().indexOf( '.' );
      const QString languageCode = it.fileName().mid( 7, delimiter - 7 );
      const bool hasCoutryCode = languageCode.indexOf( '_' ) > -1;

      const QLocale locale( languageCode );
      QString displayName;
      if ( languageCode == QStringLiteral( "en" ) )
      {
        displayName = QStringLiteral( "english" );
      }
      else if ( locale.nativeLanguageName().isEmpty() )
      {
        displayName = QStringLiteral( "code (%1)" ).arg( languageCode );
      }
      else
      {
        displayName = locale.nativeLanguageName().toLower() + ( hasCoutryCode ? QStringLiteral( " / %1" ).arg( locale.nativeTerritoryName() ) : QString() );
      }

      languages.insert( languageCode, displayName );
    }
  }
  return languages;
}

bool AppInterface::isFileExtensionSupported( const QString &filename ) const
{
  const QFileInfo fi( filename );
  const QString suffix = fi.suffix().toLower();
  return SUPPORTED_PROJECT_EXTENSIONS.contains( suffix ) || SUPPORTED_VECTOR_EXTENSIONS.contains( suffix ) || SUPPORTED_RASTER_EXTENSIONS.contains( suffix );
}

void AppInterface::logMessage( const QString &message )
{
  QgsMessageLog::logMessage( message, QStringLiteral( "SIGPACGO" ) );
}

void AppInterface::logRuntimeProfiler()
{
#if _QGIS_VERSION_INT >= 33299
  QgsMessageLog::logMessage( QgsApplication::profiler()->asText(), QStringLiteral( "SIGPACGO" ) );
#else
  QgsMessageLog::logMessage( QStringLiteral( "SIGPACGO must be compiled against QGIS >= 3.34 to support logging of the runtime profiler" ), QStringLiteral( "SIGPACGO" ) );
#endif
}

void AppInterface::sendLog( const QString &message, const QString &cloudUser )
{
#if WITH_SENTRY
  sentry_wrapper::capture_event( message.toUtf8().constData(), cloudUser.toUtf8().constData() );
#endif
}

void AppInterface::initiateSentry() const
{
#if WITH_SENTRY
  sentry_wrapper::init();
#endif
}

void AppInterface::closeSentry() const
{
#if WITH_SENTRY
  sentry_wrapper::close();
#endif
}

void AppInterface::clearProject() const
{
  mApp->clearProject();
}

void AppInterface::importUrl( const QString &url )
{
  QString sanitizedUrl = url.trimmed();
  if ( sanitizedUrl.isEmpty() )
    return;

  if ( !sanitizedUrl.contains( QRegularExpression( "^([a-z][a-z0-9+\\-.]*):" ) ) )
  {
    // Prepend HTTPS when the URL scheme is missing instead of assured failure
    sanitizedUrl = QStringLiteral( "https://%1" ).arg( sanitizedUrl );
  }

  const QString applicationDirectory = PlatformUtilities::instance()->applicationDirectory();
  if ( applicationDirectory.isEmpty() )
    return;

  QgsNetworkAccessManager *manager = QgsNetworkAccessManager::instance();
  QNetworkRequest request( ( QUrl( sanitizedUrl ) ) );
  request.setAttribute( QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy );

  emit importTriggered( request.url().fileName() );

  QNetworkReply *reply = manager->get( request );

  QTemporaryFile *temporaryFile = new QTemporaryFile( reply );
  temporaryFile->setFileTemplate( QStringLiteral( "%1/XXXXXXXXXXXX" ).arg( applicationDirectory ) );
  temporaryFile->open();

  connect( reply, &QNetworkReply::downloadProgress, this, [=]( int bytesReceived, int bytesTotal ) {
    temporaryFile->write( reply->readAll() );
    if ( bytesTotal != 0 )
    {
      emit importProgress( static_cast<double>( bytesReceived ) / bytesTotal );
    }
  } );

  connect( reply, &QNetworkReply::finished, this, [=]() {
    if ( reply->error() == QNetworkReply::NoError )
    {
      QString fileName = reply->url().fileName();
      QString contentDisposition = reply->header( QNetworkRequest::ContentDispositionHeader ).toString();
      if ( !contentDisposition.isEmpty() )
      {
        QRegularExpression rx( QStringLiteral( "filename=\"?([^\";]*)\"?" ) );
        QRegularExpressionMatch match = rx.match( contentDisposition );
        if ( match.hasMatch() )
        {
          fileName = match.captured( 1 );
        }
      }

      QFileInfo fileInfo = QFileInfo( fileName );
      const QString fileSuffix = fileInfo.completeSuffix().toLower();
      const bool isProjectFile = fileSuffix == QLatin1String( "qgs" ) || fileSuffix == QLatin1String( "qgz" );

      QString filePath = QStringLiteral( "%1/%2/%3" ).arg( applicationDirectory, isProjectFile ? QLatin1String( "Imported Projects" ) : QLatin1String( "Imported Datasets" ), fileName );
      {
        int i = 0;
        while ( QFileInfo::exists( filePath ) )
        {
          filePath = QStringLiteral( "%1/%2/%3_%4.%5" ).arg( applicationDirectory, isProjectFile ? QLatin1String( "Imported Projects" ) : QLatin1String( "Imported Datasets" ), fileInfo.baseName(), QString::number( ++i ), fileSuffix );
        }
      }
      QDir( QFileInfo( filePath ).absolutePath() ).mkpath( "." );

      temporaryFile->write( reply->readAll() );
      temporaryFile->setAutoRemove( false );
      temporaryFile->close();
      if ( temporaryFile->rename( filePath ) )
      {
        if ( fileSuffix == QLatin1String( "zip" ) )
        {
          // Check if this is a compressed project and handle accordingly
          QStringList zipFiles = QgsZipUtils::files( filePath );
          const bool isCompressedProject = std::find_if( zipFiles.begin(),
                                                         zipFiles.end(),
                                                         []( const QString &zipFile ) {
                                                           return zipFile.toLower().endsWith( QLatin1String( ".qgs" ) ) || zipFile.toLower().endsWith( QLatin1String( ".qgz" ) );
                                                         } )
                                           != zipFiles.end();
          if ( isCompressedProject )
          {
            QString zipDirectory = QStringLiteral( "%1/Imported Projects/%2" ).arg( applicationDirectory, fileInfo.baseName() );
            {
              int i = 0;
              while ( QFileInfo::exists( zipDirectory ) )
              {
                zipDirectory = QStringLiteral( "%1/Imported Projects/%2_%3" ).arg( applicationDirectory, fileInfo.baseName(), QString::number( ++i ) );
              }
            }
            QDir( zipDirectory ).mkpath( "." );

            if ( QgsZipUtils::unzip( filePath, zipDirectory, zipFiles, false ) )
            {
              // Project archive successfully imported
              emit importEnded( zipDirectory );
              return;
            }
            else
            {
              // Broken project archive, bail out
              QDir dir( zipDirectory );
              dir.removeRecursively();
              filePath.clear();
              emit importEnded();
              return;
            }
          }
        }

        // Dataset successfully imported
        emit importEnded( QFileInfo( filePath ).absolutePath() );
        return;
      }
    }

    emit importEnded();
  } );
}

QVariantList AppInterface::getLayersInGeoPackage( const QString &gpkgPath ) const
{
  QVariantList result;
  QFileInfo fileInfo( gpkgPath );
  
  if ( !fileInfo.exists() || !fileInfo.isFile() )
    return result;
  
  // Create a unique connection name based on file path to avoid conflicts
  QString connectionName = QString("gpkg_connection_%1").arg(fileInfo.fileName().replace(".", "_"));
  
  {
    // Using a scope to ensure all queries are finished before removing the connection
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
    db.setDatabaseName(gpkgPath);
    
    if (db.open()) {
      // Look for vector layers
      {
        QSqlQuery query(db);
        if (query.exec("SELECT table_name FROM gpkg_contents WHERE data_type='features'")) {
          while (query.next()) {
            QString layerName = query.value(0).toString();
            QVariantMap layerInfo;
            layerInfo["name"] = layerName;
            layerInfo["type"] = "vector";
            result.append(layerInfo);
          }
        }
        // Explicitly clear the query to release resources
        query.clear();
      }
      
      // Look for raster layers
      {
        QSqlQuery query(db);
        if (query.exec("SELECT table_name FROM gpkg_contents WHERE data_type='tiles'")) {
          while (query.next()) {
            QString layerName = query.value(0).toString();
            QVariantMap layerInfo;
            layerInfo["name"] = layerName;
            layerInfo["type"] = "raster";
            result.append(layerInfo);
          }
        }
        // Explicitly clear the query to release resources
        query.clear();
      }
      
      // Close the database connection
      db.close();
    }
  }
  
  // Now remove the database connection after all queries and the db connection are out of scope
  QSqlDatabase::removeDatabase(connectionName);
  
  // If we couldn't get layer info from the database, at least try to open it as a vector layer
  if (result.isEmpty()) {
    QgsVectorLayer testLayer(gpkgPath, "test", "ogr");
    if (testLayer.isValid()) {
      QVariantMap layerInfo;
      layerInfo["name"] = fileInfo.baseName();
      layerInfo["type"] = "vector";
      result.append(layerInfo);
    }
  }
  
  return result;
}

bool AppInterface::addLayerFromGeoPackage( const QString &gpkgPath, const QString &layerName, const QString &layerType ) const
{
  QFileInfo fileInfo( gpkgPath );
  
  if ( !fileInfo.exists() || !fileInfo.isFile() )
    return false;
  
  if ( !QgsProject::instance() )
    return false;
  
  // Create the layer
  QgsMapLayer *newLayer = nullptr;
  
  if ( layerType == "vector" )
  {
    // For vector layers, we need to create the URI with the layer name
    QString uri = gpkgPath + "|layername=" + layerName;
    newLayer = new QgsVectorLayer( uri, layerName, "ogr" );
  }
  else if ( layerType == "raster" )
  {
    // For raster layers in GPKG
    QString uri = gpkgPath + "|layername=" + layerName;
    newLayer = new QgsRasterLayer( uri, layerName, "gdal" );
  }
  
  if ( !newLayer || !newLayer->isValid() )
  {
    QgsMessageLog::logMessage( QStringLiteral( "Failed to create layer from GeoPackage: %1, layer: %2" ).arg( gpkgPath, layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    delete newLayer;
    return false;
  }
  
  // Add the layer to the project
  if ( !QgsProject::instance()->addMapLayer( newLayer ) )
  {
    QgsMessageLog::logMessage( QStringLiteral( "Failed to add layer to project: %1" ).arg( layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    delete newLayer;
    return false;
  }
  
  // Save the project to persist the added layer
  if ( !QgsProject::instance()->write() )
  {
    QgsMessageLog::logMessage( QStringLiteral( "Failed to save project after adding layer: %1" ).arg( layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    // Continue anyway, the layer is still added to the current session
  }
  
  QgsMessageLog::logMessage( QStringLiteral( "Successfully added layer from GeoPackage: %1, layer: %2" ).arg( gpkgPath, layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
  return true;
}

bool AppInterface::removeLayerFromProject( const QString &layerId ) const
{
  if ( !QgsProject::instance() )
    return false;
  
  QgsMapLayer *layer = QgsProject::instance()->mapLayer( layerId );
  if ( !layer )
  {
    QgsMessageLog::logMessage( QStringLiteral( "Failed to find layer with ID: %1" ).arg( layerId ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    return false;
  }
  
  // Store the layer name for the log message
  QString layerName = layer->name();
  
  // Remove the layer from the project
  // QgsProject::removeMapLayer doesn't return a boolean, so we can't check its return value directly
  QgsProject::instance()->removeMapLayer( layerId );
  
  // Save the project to persist the removal of the layer
  if ( !QgsProject::instance()->write() )
  {
    QgsMessageLog::logMessage( QStringLiteral( "Failed to save project after removing layer: %1" ).arg( layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    // Continue anyway, the layer is still removed from the current session
  }
  
  QgsMessageLog::logMessage( QStringLiteral( "Successfully removed layer: %1" ).arg( layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
  return true;
}

QVariantList AppInterface::getProjectLayers() const
{
  QVariantList result;
  
  if ( !QgsProject::instance() )
    return result;
  
  // Get all map layers from the project
  const QMap<QString, QgsMapLayer *> mapLayers = QgsProject::instance()->mapLayers();
  
  // Add each layer to the result list
  for ( auto it = mapLayers.constBegin(); it != mapLayers.constEnd(); ++it )
  {
    QgsMapLayer *layer = it.value();
    if ( !layer )
      continue;
    
    QVariantMap layerInfo;
    layerInfo["id"] = it.key();
    layerInfo["name"] = layer->name();
    
    // Determine the layer type
    if ( qobject_cast<QgsVectorLayer *>( layer ) )
    {
      layerInfo["type"] = "vector";
    }
    else if ( qobject_cast<QgsRasterLayer *>( layer ) )
    {
      layerInfo["type"] = "raster";
    }
    else
    {
      layerInfo["type"] = "other";
    }
    
    result.append( layerInfo );
  }
  
  return result;
}

QVariantList AppInterface::getLayerGroups() const
{
  QVariantList result;
  
  if ( !QgsProject::instance() )
    return result;
  
  // Get the layer tree root
  QgsLayerTreeGroup *root = QgsProject::instance()->layerTreeRoot();
  if ( !root )
    return result;
  
  // Add root group
  QVariantMap rootInfo;
  rootInfo["id"] = "root";
  rootInfo["name"] = tr( "Root" );
  rootInfo["path"] = "/";
  result.append( rootInfo );
  
  // Function to recursively collect groups
  std::function<void( QgsLayerTreeGroup *, const QString & )> collectGroups;
  collectGroups = [&result, &collectGroups]( QgsLayerTreeGroup *group, const QString &parentPath )
  {
    if ( !group )
      return;
    
    // Process all child groups
    QList<QgsLayerTreeGroup *> childGroups = group->findGroups();
    for ( QgsLayerTreeGroup *childGroup : childGroups )
    {
      QString path = parentPath + "/" + childGroup->name();
      
      QVariantMap groupInfo;
      groupInfo["id"] = childGroup->name();
      groupInfo["name"] = childGroup->name();
      groupInfo["path"] = path;
      result.append( groupInfo );
      
      // Process subgroups
      collectGroups( childGroup, path );
    }
  };
  
  // Start collecting from root
  collectGroups( root, "/" );
  
  return result;
}

bool AppInterface::addLayerToGroup( const QString &gpkgPath, const QString &layerName, const QString &layerType, const QString &groupName ) const
{
  if ( !QgsProject::instance() )
  {
    QgsMessageLog::logMessage( tr( "No project loaded" ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    return false;
  }
  
  QFileInfo fileInfo( gpkgPath );
  if ( !fileInfo.exists() )
  {
    QgsMessageLog::logMessage( tr( "File does not exist: %1" ).arg( gpkgPath ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    return false;
  }
  
  // Get the layer tree root
  QgsLayerTreeGroup *root = QgsProject::instance()->layerTreeRoot();
  if ( !root )
  {
    QgsMessageLog::logMessage( tr( "Could not get layer tree root" ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    return false;
  }
  
  // Find or create the target group
  QgsLayerTreeGroup *targetGroup = nullptr;
  
  // Determine the group to use
  QString targetGroupName;
  
  if ( groupName.isEmpty() || groupName == "root" )
  {
    // For layers being added to root, add them to a common "Imported Layers" group
    targetGroupName = tr( "Imported Layers" );
  }
  else
  {
    // Use the provided group name
    targetGroupName = groupName;
  }
  
  // Find the target group by name 
  QList<QgsLayerTreeGroup *> topLevelGroups = root->findGroups();
  bool foundGroup = false;
  
  for ( QgsLayerTreeGroup *group : topLevelGroups )
  {
    if ( group->name() == targetGroupName )
    {
      targetGroup = group;
      foundGroup = true;
      QgsMessageLog::logMessage( tr( "Using existing group: %1" ).arg( targetGroupName ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
      break;
    }
  }
  
  // Create the group if it doesn't exist
  if ( !foundGroup )
  {
    targetGroup = root->addGroup( targetGroupName );
    if ( !targetGroup )
    {
      QgsMessageLog::logMessage( tr( "Failed to create group: %1, falling back to root" ).arg( targetGroupName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
      targetGroup = root;
    }
    else
    {
      QgsMessageLog::logMessage( tr( "Created new group: %1" ).arg( targetGroupName ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
    }
  }
  
  // Check if a layer with the same name already exists in the target group
  QList<QgsLayerTreeLayer*> existingLayers = targetGroup->findLayers();
  for (QgsLayerTreeLayer* existingLayerNode : existingLayers)
  {
    if (existingLayerNode && existingLayerNode->layer())
    {
      // Check if we already have a layer with the same name
      if (existingLayerNode->layer()->name() == layerName)
      {
        QgsMessageLog::logMessage( tr( "Layer with name '%1' already exists in group '%2', skipping" )
                                   .arg( layerName, targetGroupName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
        return true; // Return true to indicate "success" since the layer already exists
      }
    }
  }
  
  // Add the layer
  QgsMapLayer *layer = nullptr;
  
  // Create a connection to the database
  QString connectionName = QString( "gpkg_connection_%1" ).arg( fileInfo.fileName().replace( ".", "_" ) );
  
  {
    QSqlDatabase db = QSqlDatabase::addDatabase( "QSQLITE", connectionName );
    db.setDatabaseName( gpkgPath );
    
    if ( !db.open() )
    {
      QgsMessageLog::logMessage( tr( "Failed to open database: %1" ).arg( db.lastError().text() ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
      QSqlDatabase::removeDatabase( connectionName );
      return false;
    }
    
    // Load the layer
    if ( layerType.toLower() == "vector" )
    {
      QString uri = QString( "%1|layername=%2" ).arg( gpkgPath ).arg( layerName );
      layer = new QgsVectorLayer( uri, layerName, "ogr" );
    }
    else if ( layerType.toLower() == "raster" )
    {
      QString uri = QString( "GPKG:%1:%2" ).arg( gpkgPath ).arg( layerName );
      layer = new QgsRasterLayer( uri, layerName, "gdal" );
    }
    
    // Clean up the database connection
    db.close();
    QSqlDatabase::removeDatabase( connectionName );
  }
  
  if ( !layer || !layer->isValid() )
  {
    QgsMessageLog::logMessage( tr( "Failed to load layer: %1" ).arg( layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    delete layer;
    return false;
  }
  
  // Add layer to the project
  QgsProject::instance()->addMapLayer( layer, false );
  
  // Add it to the specified group in the layer tree
  targetGroup->addLayer( layer );
  
  QgsMessageLog::logMessage( tr( "Layer added successfully: %1" ).arg( layerName ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
  
  // Save the project
  if ( !QgsProject::instance()->write() )
  {
    QgsMessageLog::logMessage( tr( "Failed to save project after adding layer" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
  }
  
  return true;
}

bool AppInterface::removeLayerGroup( const QString &groupName ) const
{
  if ( !QgsProject::instance() )
  {
    QgsMessageLog::logMessage( tr( "No project loaded" ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    return false;
  }
  
  // Prevent removing the root group
  if ( groupName == "root" )
  {
    QgsMessageLog::logMessage( tr( "Cannot remove root group" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    return false;
  }
  
  // Get the layer tree root
  QgsLayerTreeGroup *root = QgsProject::instance()->layerTreeRoot();
  if ( !root )
  {
    QgsMessageLog::logMessage( tr( "Could not get layer tree root" ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    return false;
  }
  
  // Find the group
  QgsLayerTreeGroup *targetGroup = nullptr;
  
  // Recursive function to find a group by name
  std::function<QgsLayerTreeGroup*(QgsLayerTreeGroup*, const QString&)> findGroup;
  findGroup = [&findGroup](QgsLayerTreeGroup* group, const QString& name) -> QgsLayerTreeGroup* {
    if (group->name() == name)
      return group;
    
    const QList<QgsLayerTreeGroup*> childGroups = group->findGroups();
    for (QgsLayerTreeGroup* childGroup : childGroups)
    {
      QgsLayerTreeGroup *result = findGroup(childGroup, name);
      if (result)
        return result;
    }
    
    return nullptr;
  };
  
  targetGroup = findGroup(root, groupName);
  
  if (!targetGroup)
  {
    QgsMessageLog::logMessage( tr( "Group not found: %1" ).arg( groupName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    return false;
  }
  
  // Before removing the group, get its parent group
  QgsLayerTreeGroup *parentGroup = qobject_cast<QgsLayerTreeGroup*>(targetGroup->parent());
  if (!parentGroup)
  {
    QgsMessageLog::logMessage( tr( "Could not get parent group for: %1" ).arg( groupName ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    return false;
  }
  
  // Find all layers in the group and remove them from the project
  QList<QgsLayerTreeLayer*> layerNodes = targetGroup->findLayers();
  
  for (QgsLayerTreeLayer* layerNode : layerNodes)
  {
    if (layerNode && layerNode->layer())
    {
      QString layerId = layerNode->layerId();
      QString layerName = layerNode->layer()->name();
      
      QgsProject::instance()->removeMapLayer(layerId);
      QgsMessageLog::logMessage(tr("Removed layer: %1 from group: %2").arg(layerName, groupName), QStringLiteral("SIGPACGO"), Qgis::Info);
    }
  }
  
  // Remove all subgroups recursively
  QList<QgsLayerTreeGroup*> subGroups = targetGroup->findGroups();
  for (QgsLayerTreeGroup* subGroup : subGroups)
  {
    if (subGroup)
    {
      // Recursively remove layers from subgroups
      QList<QgsLayerTreeLayer*> subLayerNodes = subGroup->findLayers();
      for (QgsLayerTreeLayer* layerNode : subLayerNodes)
      {
        if (layerNode && layerNode->layer())
        {
          QgsProject::instance()->removeMapLayer(layerNode->layerId());
        }
      }
    }
  }
  
  // Remove the group itself
  parentGroup->removeChildNode(targetGroup);
  
  // Save the project
  if ( !QgsProject::instance()->write() )
  {
    QgsMessageLog::logMessage( tr( "Failed to save project after removing group" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
  }
  
  QgsMessageLog::logMessage( tr( "Group and all its layers removed successfully: %1" ).arg( groupName ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
  return true;
}

QString AppInterface::createFolderBackup( const QString &sourceFolderPath, const QString &destinationFolderPath ) const
{
  QDir sourceDir( sourceFolderPath );
  if ( !sourceDir.exists() )
  {
    QgsMessageLog::logMessage( tr( "Source folder does not exist: %1" ).arg( sourceFolderPath ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    return QString();
  }
  
  // Create a timestamp for the backup filename
  QString timestamp = QDateTime::currentDateTime().toString( "yyyyMMdd_HHmmss" );
  QString folderName = sourceDir.dirName();
  
  // Determine the destination folder
  QString destFolder;
  if ( destinationFolderPath.isEmpty() )
  {
    // If no destination specified, use the Documents/SIGPACGO_Backups folder
    destFolder = QStandardPaths::writableLocation( QStandardPaths::DocumentsLocation ) + "/SIGPACGO_Backups";
    QDir().mkpath( destFolder );
  }
  else
  {
    destFolder = destinationFolderPath;
    QDir destDir( destFolder );
    if ( !destDir.exists() )
    {
      if ( !QDir().mkpath( destFolder ) )
      {
        QgsMessageLog::logMessage( tr( "Could not create destination folder: %1" ).arg( destFolder ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
        return QString();
      }
    }
  }
  
  // Create the backup zip file path
  QString zipFilePath = QString( "%1/%2_backup_%3.zip" ).arg( destFolder, folderName, timestamp );
  
  // Check if we can use the QgsZipUtils directly
  bool success = false;
  
  // Try using QgsZipUtils first
  try
  {
    QgsMessageLog::logMessage( tr( "Creating backup using QgsZipUtils: %1" ).arg( zipFilePath ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
    
    // Get all the files in the source folder recursively
    QDir dir( sourceFolderPath );
    QStringList files;
    QDirIterator it( sourceFolderPath, QDir::Files | QDir::NoDotAndDotDot | QDir::Hidden, QDirIterator::Subdirectories );
    const int sourceDirNameLength = sourceFolderPath.length() + 1; // +1 for the trailing slash
    
    while ( it.hasNext() )
    {
      QString filePath = it.next();
      files << filePath;
    }
    
    if ( files.isEmpty() )
    {
      QgsMessageLog::logMessage( tr( "No files found in source folder: %1" ).arg( sourceFolderPath ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
      return QString();
    }
    
    // Change directory to the source folder before zipping to maintain relative paths
    QDir::setCurrent( sourceFolderPath );
    success = QgsZipUtils::zip( zipFilePath, files );
  }
  catch ( const std::exception &e )
  {
    QgsMessageLog::logMessage( tr( "Error in QgsZipUtils: %1" ).arg( e.what() ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    success = false;
  }
  
  // If QgsZipUtils failed, try using a system command
  if ( !success )
  {
    QgsMessageLog::logMessage( tr( "Falling back to system zip command" ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
    
    // Try to use the system's zip command
    QProcess zipProcess;
    QString command;
    
#ifdef Q_OS_WIN
    // On Windows, try to use PowerShell's compression
    command = QString( "powershell.exe -Command \"Compress-Archive -Path '%1\\*' -DestinationPath '%2' -Force\"" )
              .arg( sourceFolderPath.replace( "/", "\\" ), zipFilePath.replace( "/", "\\" ) );
#else
    // On Linux/macOS, use the zip command
    command = QString( "cd '%1' && zip -r '%2' ." )
              .arg( sourceFolderPath, zipFilePath );
#endif
    
    QgsMessageLog::logMessage( tr( "Running command: %1" ).arg( command ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
    zipProcess.start( command );
    
    if ( !zipProcess.waitForFinished( 300000 ) ) // 5 minute timeout
    {
      QgsMessageLog::logMessage( tr( "Zip process timed out" ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
      return QString();
    }
    
    if ( zipProcess.exitCode() != 0 )
    {
      QgsMessageLog::logMessage( tr( "Zip process failed: %1" ).arg( QString::fromUtf8( zipProcess.readAllStandardError() ) ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
      return QString();
    }
    
    success = true;
  }
  
  if ( success )
  {
    QgsMessageLog::logMessage( tr( "Backup successfully created: %1" ).arg( zipFilePath ), QStringLiteral( "SIGPACGO" ), Qgis::Success );
    return zipFilePath;
  }
  else
  {
    QgsMessageLog::logMessage( tr( "Failed to create backup" ), QStringLiteral( "SIGPACGO" ), Qgis::Critical );
    return QString();
  }
}
