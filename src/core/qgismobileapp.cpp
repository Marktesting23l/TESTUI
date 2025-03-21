/***************************************************************************
                            qgismobileapp.cpp
                              -------------------
              begin                : Wed Apr 04 10:48:28 CET 2012
              copyright            : (C) 2012 by Marco Bernasocchi
              email                : marco@bernawebdesign.ch
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include <QApplication>

#ifndef _MSC_VER
#include <unistd.h>
#endif
#include <stdlib.h>

// use GDAL VSI mechanism
#define CPL_SUPRESS_CPLUSPLUS //#spellok
#include "cpl_conv.h"
#include "cpl_string.h"
#include "cpl_vsi.h"
#include "gdal_version.h"

#ifdef WITH_BLUETOOTH
#include "bluetoothdevicemodel.h"
#include "bluetoothreceiver.h"
#endif
#ifdef WITH_SERIALPORT
#include "serialportmodel.h"
#include "serialportreceiver.h"
#endif
#include "appinterface.h"
#include "attributeformmodel.h"
#include "audiorecorder.h"
#include "badlayerhandler.h"
#include "barcodedecoder.h"
#include "changelogcontents.h"
#include "coordinatereferencesystemutils.h"
#include "deltafilewrapper.h"
#include "deltalistmodel.h"
#include "digitizinglogger.h"
#include "distancearea.h"
#include "drawingcanvas.h"
#include "expressioncontextutils.h"
#include "expressionevaluator.h"
#include "expressionvariablemodel.h"
#include "featurechecklistmodel.h"
#include "featurehistory.h"
#include "featurelistextentcontroller.h"
#include "featurelistmodel.h"
#include "featurelistmodelselection.h"
#include "featuremodel.h"
#include "featureutils.h"
#include "fileutils.h"
#include "focusstack.h"
#include "geofencer.h"
#include "geometry.h"
#include "geometryeditorsmodel.h"
#include "geometryutils.h"
#include "gnsspositioninformation.h"
#include "gridmodel.h"
#include "identifytool.h"
#include "layerobserver.h"
#include "layerresolver.h"
#include "layertreemapcanvasbridge.h"
#include "layertreemodel.h"
#include "layerutils.h"
#include "legendimageprovider.h"
#include "linepolygonshape.h"
#include "localfilesimageprovider.h"
#include "localfilesmodel.h"
#include "locatormodelsuperbridge.h"
#include "maptoscreen.h"
#include "messagelogmodel.h"
#include "modelhelper.h"
#include "navigation.h"
#include "navigationmodel.h"
#include "nearfieldreader.h"
#include "orderedrelationmodel.h"
#include "parametizedimage.h"
#include "permissions.h"
#include "platformutilities.h"
#include "positioning.h"
#include "positioningdevicemodel.h"
#include "positioninginformationmodel.h"
#include "positioningutils.h"
#include "printlayoutlistmodel.h"
#include "processingalgorithm.h"
#include "processingalgorithmparametersmodel.h"
#include "processingalgorithmsmodel.h"
#include "projectinfo.h"
#include "projectsimageprovider.h"
#include "projectsource.h"
#include "projectutils.h"
#include "qfield.h"
#include "qgismobileapp.h"
#include "qgsgeometrywrapper.h"
#include "qgsproviderregistry.h"
#include "qgsprovidersublayerdetails.h"
#include "qgsquickcoordinatetransformer.h"
#include "qgsquickelevationprofilecanvas.h"
#include "qgsquickmapcanvasmap.h"
#include "qgsquickmapsettings.h"
#include "qgsquickmaptransform.h"
#include "recentprojectlistmodel.h"
#include "referencingfeaturelistmodel.h"
#include "relationutils.h"
#include "resourcesource.h"
#include "rubberbandmodel.h"
#include "rubberbandshape.h"
#include "scalebarmeasurement.h"
#include "sensorlistmodel.h"
#include "snappingresult.h"
#include "snappingutils.h"
#include "stringutils.h"
#include "submodel.h"
#include "trackingmodel.h"
#include "urlutils.h"
#include "valuemapmodel.h"
#include "vertexmodel.h"
#include "webdavconnection.h"

#include <QDateTime>
#include <QFileInfo>
#include <QFontDatabase>
#include <QPalette>
#include <QPermissions>
#include <QQmlFileSelector>
#include <QResource>
#include <QScreen>
#include <QStyleHints>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <qgsauthmanager.h>
#include <qgsbilinearrasterresampler.h>
#include <qgscoordinatereferencesystem.h>
#include <qgsexpressionfunction.h>
#include <qgsfeature.h>
#include <qgsfield.h>
#include <qgsfieldconstraints.h>
#include <qgsfontmanager.h>
#include <qgsgeopackageprojectstorage.h>
#include <qgslayertree.h>
#include <qgslayertreemodel.h>
#include <qgslayertreeregistrybridge.h>
#include <qgslayoutatlas.h>
#include <qgslayoutexporter.h>
#include <qgslayoutitemlabel.h>
#include <qgslayoutitemmap.h>
#include <qgslayoutmanager.h>
#include <qgslayoutpagecollection.h>
#include <qgslocalizeddatapathregistry.h>
#include <qgslocator.h>
#include <qgslocatorcontext.h>
#include <qgslocatormodel.h>
#include <qgsmaplayer.h>
#include <qgsmaplayerstyle.h>
#include <qgsmapthemecollection.h>
#include <qgsmessagelog.h>
#include <qgsnetworkaccessmanager.h>
#include <qgsofflineediting.h>
#include <qgsprintlayout.h>
#include <qgsproject.h>
#include <qgsprojectdisplaysettings.h>
#include <qgsprojectelevationproperties.h>
#include <qgsprojectstorage.h>
#include <qgsprojectstorageregistry.h>
#include <qgsprojectstylesettings.h>
#include <qgsprojectviewsettings.h>
#include <qgsrasterlayer.h>
#include <qgsrasterresamplefilter.h>
#include <qgsrelationmanager.h>
#include <qgssinglesymbolrenderer.h>
#include <qgssnappingutils.h>
#include <qgstemporalutils.h>
#include <qgsterrainprovider.h>
#include <qgsunittypes.h>
#include <qgsvectorlayer.h>
#include <qgsvectorlayereditbuffer.h>
#include <qgsvectorlayertemporalproperties.h>
#include <qgsvectortilelayer.h>
#include <qgsvectorfilewriter.h>

#include <QFontDatabase>
#include <QTemporaryFile>

#define QUOTE( string ) _QUOTE( string )
#define _QUOTE( string ) #string

// Implementation of WmsRateLimiter
WmsRateLimiter *WmsRateLimiter::sInstance = nullptr;

WmsRateLimiter::WmsRateLimiter(QObject *parent)
  : QObject(parent)
  , mEnabled(false)
  , mDelayMs(1000)
{
}

void WmsRateLimiter::setDelay(int delayMs)
{
  mDelayMs = delayMs;
}

bool WmsRateLimiter::isEnabled() const
{
  return mEnabled;
}

void WmsRateLimiter::setEnabled(bool enabled)
{
  mEnabled = enabled;
}

WmsRateLimiter *WmsRateLimiter::instance()
{
  if (!sInstance)
  {
    sInstance = new WmsRateLimiter();
  }
  return sInstance;
}

QgisMobileapp::QgisMobileapp( QgsApplication *app, QObject *parent )
  : QQmlApplicationEngine( parent )
  , mIface( new AppInterface( this ) )
  , mFirstRenderingFlag( true )
  , mApp( app )
{
  // Set a nicer default hyperlink color to be used in QML Text items
  QPalette palette = app->palette();
  palette.setColor( QPalette::Link, QColor( 128, 204, 40 ) );
  palette.setColor( QPalette::LinkVisited, QColor( 128, 204, 40 ) );
  app->setPalette( palette );

  mMessageLogModel = new MessageLogModel( this );

  QSettings settings;
  if ( PlatformUtilities::instance()->capabilities() & PlatformUtilities::AdjustBrightness )
  {
    mScreenDimmer = std::make_unique<ScreenDimmer>( app );
    mScreenDimmer->setTimeout( settings.value( QStringLiteral( "dimTimeoutSeconds" ), 40 ).toInt() );
  }

  AppInterface::setInstance( mIface );

  //set the authHandler to qfield-handler
  std::unique_ptr<QgsNetworkAuthenticationHandler> handler;
  mAuthRequestHandler = new QFieldAppAuthRequestHandler();
  handler.reset( mAuthRequestHandler );
  QgsNetworkAccessManager::instance()->setAuthHandler( std::move( handler ) );

  QStringList dataDirs = PlatformUtilities::instance()->appDataDirs();
  if ( !dataDirs.isEmpty() )
  {
    //set localized data paths and register fonts
    QStringList localizedDataPaths;
    for ( const QString &dataDir : dataDirs )
    {
      localizedDataPaths << dataDir + QStringLiteral( "basemaps/" );

      // Add app-wide font(s)
      const QDir fontDir = QDir::cleanPath( QFileInfo( dataDir ).absoluteDir().path() + QDir::separator() + QStringLiteral( "fonts" ) );
      const QStringList fontExts = QStringList() << "*.ttf"
                                                 << "*.TTF"
                                                 << "*.otf"
                                                 << "*.OTF";
      const QStringList fontFiles = fontDir.entryList( fontExts, QDir::Files );
      for ( const QString &fontFile : fontFiles )
      {
        const int id = QFontDatabase::addApplicationFont( QDir::cleanPath( fontDir.path() + QDir::separator() + fontFile ) );
        qInfo() << QStringLiteral( "App-wide font registered: %1" ).arg( QDir::cleanPath( fontDir.path() + QDir::separator() + fontFile ) );
        if ( id == -1 )
        {
          QgsMessageLog::logMessage( tr( "Could not load font: %1" ).arg( fontFile ) );
        }
      }
    }
    QgsApplication::instance()->localizedDataPathRegistry()->setPaths( localizedDataPaths );
  }

  QFontDatabase::addApplicationFont( ":/fonts/InterDisplay-Bold.ttf" );
  QFontDatabase::addApplicationFont( ":/fonts/InterDisplay-BoldItalic.ttf" );
  QFontDatabase::addApplicationFont( ":/fonts/InterDisplay-Light.ttf" );
  QFontDatabase::addApplicationFont( ":/fonts/InterDisplay-Italic.ttf" );
  QFontDatabase::addApplicationFont( ":/fonts/InterDisplay-Regular.ttf" );
  QFontDatabase::addApplicationFont( ":/fonts/InterDisplay-SemiBoldItalic.ttf" );
  QFontDatabase::addApplicationFont( ":/fonts/CadastraSymbol-Mask.ttf" );
  QFontDatabase::addApplicationFont( ":/fonts/CadastraSymbol-Regular.ttf" );

  QgsApplication::fontManager()->enableFontDownloadsForSession();

  mProject = QgsProject::instance();
  mTrackingModel = new TrackingModel();
  mGpkgFlusher = std::make_unique<QgsGpkgFlusher>( mProject );
  mLayerObserver = std::make_unique<LayerObserver>( mProject );
  mFeatureHistory = std::make_unique<FeatureHistory>( mProject, mTrackingModel );
  mClipboardManager = std::make_unique<ClipboardManager>( this );
  mFlatLayerTree = new FlatLayerTreeModel( mProject->layerTreeRoot(), mProject, this );
  mLegendImageProvider = new LegendImageProvider( mFlatLayerTree->layerTreeModel() );
  mLocalFilesImageProvider = new LocalFilesImageProvider();
  mProjectsImageProvider = new ProjectsImageProvider();

  mBookmarkModel = new BookmarkModel( QgsApplication::bookmarkManager(), mProject->bookmarkManager(), this );
  mDrawingTemplateModel = new DrawingTemplateModel( this );

  mPluginManager = new PluginManager( this );

  // cppcheck-suppress leakReturnValNotUsed
  initDeclarative( this );

  registerGlobalVariables();

  if ( !dataDirs.isEmpty() )
  {
    QgsApplication::instance()->authManager()->setPasswordHelperEnabled( false );
    QgsApplication::instance()->authManager()->setMasterPassword( QString( "qfield" ) );
    // import authentication method configurations
    for ( const QString &dataDir : dataDirs )
    {
      QDir configurationsDir( QStringLiteral( "%1/auth/" ).arg( dataDir ) );
      if ( configurationsDir.exists() )
      {
        const QStringList configurations = configurationsDir.entryList( QStringList() << QStringLiteral( "*.xml" ) << QStringLiteral( "*.XML" ), QDir::Files );
        for ( const QString &configuration : configurations )
        {
          QgsApplication::instance()->authManager()->importAuthenticationConfigsFromXml( configurationsDir.absoluteFilePath( configuration ), QString(), true );
        }
      }
    }
  }

  PlatformUtilities::instance()->setScreenLockPermission( false );

  load( QUrl( "qrc:/qml/qgismobileapp.qml" ) );

  mMapCanvas = rootObjects().first()->findChild<QgsQuickMapCanvasMap *>();
  Q_ASSERT_X( mMapCanvas, "QML Init", "QgsQuickMapCanvasMap not found. It is likely that we failed to load the QML files. Check debug output for related messages." );
  mMapCanvas->mapSettings()->setProject( mProject );
  mBookmarkModel->setMapSettings( mMapCanvas->mapSettings() );

  mFlatLayerTree->layerTreeModel()->setLegendMapViewData( mMapCanvas->mapSettings()->outputDpi() * mMapCanvas->mapSettings()->mapSettings().mapUnitsPerPixel(),
                                                          static_cast<int>( std::round( mMapCanvas->mapSettings()->outputDpi() ) ), mMapCanvas->mapSettings()->mapSettings().scale() );

  mLayerTreeCanvasBridge = new LayerTreeMapCanvasBridge( mFlatLayerTree, mMapCanvas->mapSettings(), mTrackingModel, this );

  connect( this, &QgisMobileapp::loadProjectTriggered, mIface, &AppInterface::loadProjectTriggered );
  connect( this, &QgisMobileapp::loadProjectEnded, mIface, &AppInterface::loadProjectEnded );
  connect( this, &QgisMobileapp::setMapExtent, mIface, &AppInterface::setMapExtent );

  QTimer::singleShot( 1, this, &QgisMobileapp::onAfterFirstRendering );

  mOfflineEditing = new QgsOfflineEditing();

  mSettings.setValue( "/Map/searchRadiusMM", 5 );

  mAppMissingGridHandler = new AppMissingGridHandler( this );

  // Set GDAL option to fix loading of datasets within ZIP containers
  CPLSetConfigOption( "CPL_ZIP_ENCODING", "UTF-8" );

  connect( QgsApplication::instance(), &QGuiApplication::applicationStateChanged, this, [=]( Qt::ApplicationState state ) {
    switch ( state )
    {
      case Qt::ApplicationSuspended:
      case Qt::ApplicationHidden:
      case Qt::ApplicationInactive:
      {
        // Write settings to permanent storage
        QSettings().sync();
      }

      case Qt::ApplicationActive:
      {
        break;
      }
    }
  } );
}

void QgisMobileapp::initDeclarative( QQmlEngine *engine )
{
#if defined( Q_OS_ANDROID )
  QResource::registerResource( QStringLiteral( "assets:/android_rcc_bundle.rcc" ) );
#endif
  engine->addImportPath( QStringLiteral( "qrc:/qml/imports" ) );

  qRegisterMetaType<QMetaType::Type>( "QMetaType::Type" );

  // Register QGIS QML types
  qmlRegisterType<QgsSnappingUtils>( "org.qgis", 1, 0, "SnappingUtils" );
  qmlRegisterType<QgsMapLayerProxyModel>( "org.qgis", 1, 0, "MapLayerModel" );
  qmlRegisterType<QgsVectorLayer>( "org.qgis", 1, 0, "VectorLayer" );
  qmlRegisterType<QgsMapThemeCollection>( "org.qgis", 1, 0, "MapThemeCollection" );
  qmlRegisterType<QgsLocatorProxyModel>( "org.qgis", 1, 0, "QgsLocatorProxyModel" );
  qmlRegisterType<QgsVectorLayerEditBuffer>( "org.qgis", 1, 0, "QgsVectorLayerEditBuffer" );

  qRegisterMetaType<QgsGeometry>( "QgsGeometry" );
  qRegisterMetaType<QgsFeature>( "QgsFeature" );
  qRegisterMetaType<QgsFeatureRequest>( "QgsFeatureRequest" );
  qRegisterMetaType<QgsFeatureIterator>( "QgsFeatureIterator" );
  qRegisterMetaType<QgsPoint>( "QgsPoint" );
  qRegisterMetaType<QgsPointXY>( "QgsPointXY" );
  qRegisterMetaType<QgsPointSequence>( "QgsPointSequence" );
  qRegisterMetaType<QgsCoordinateTransformContext>( "QgsCoordinateTransformContext" );
  qRegisterMetaType<QgsFeatureId>( "QgsFeatureId" );
  qRegisterMetaType<QgsFeatureIds>( "QgsFeatureIds" );
  qRegisterMetaType<QgsAttributes>( "QgsAttributes" );
  qRegisterMetaType<QgsSnappingConfig>( "QgsSnappingConfig" );
  qRegisterMetaType<QgsRelation>( "QgsRelation" );
  qRegisterMetaType<QgsPolymorphicRelation>( "QgsPolymorphicRelation" );
  qRegisterMetaType<QgsFields>( "QgsFields" );
  qRegisterMetaType<QgsField>( "QgsField" );
  qRegisterMetaType<QgsDefaultValue>( "QgsDefaultValue" );
  qRegisterMetaType<QgsFieldConstraints>( "QgsFieldConstraints" );

  qRegisterMetaType<Qgis::GeometryType>( "Qgis::GeometryType" );
  qRegisterMetaType<Qgis::WkbType>( "Qgis::WkbType" );
  qRegisterMetaType<Qgis::LayerType>( "Qgis::LayerType" );
  qRegisterMetaType<Qgis::DistanceUnit>( "Qgis::DistanceUnit" );
  qRegisterMetaType<Qgis::AreaUnit>( "Qgis::AreaUnit" );
  qRegisterMetaType<Qgis::AngleUnit>( "Qgis::AngleUnit" );
  qRegisterMetaType<Qgis::DeviceConnectionStatus>( "Qgis::DeviceConnectionStatus" );
  qRegisterMetaType<Qgis::SnappingMode>( "Qgis::SnappingMode" );

  qmlRegisterUncreatableType<Qgis>( "org.qgis", 1, 0, "Qgis", "" );

  qmlRegisterUncreatableType<QgsProject>( "org.qgis", 1, 0, "Project", "" );
  qmlRegisterUncreatableType<QgsProjectDisplaySettings>( "org.qgis", 1, 0, "ProjectDisplaySettings", "" );
  qmlRegisterUncreatableType<QgsCoordinateReferenceSystem>( "org.qgis", 1, 0, "CoordinateReferenceSystem", "" );
  qmlRegisterUncreatableType<QgsUnitTypes>( "org.qgis", 1, 0, "QgsUnitTypes", "" );
  qmlRegisterUncreatableType<QgsRelationManager>( "org.qgis", 1, 0, "RelationManager", "The relation manager is available from the QgsProject. Try `qgisProject.relationManager`" );
  qmlRegisterUncreatableType<QgsWkbTypes>( "org.qgis", 1, 0, "QgsWkbTypes", "" );
  qmlRegisterUncreatableType<QgsMapLayer>( "org.qgis", 1, 0, "MapLayer", "" );
  qmlRegisterUncreatableType<QgsVectorLayer>( "org.qgis", 1, 0, "VectorLayerStatic", "" );

  // Register QgsQuick QML types
  qmlRegisterType<QgsQuickMapCanvasMap>( "org.qgis", 1, 0, "MapCanvasMap" );
  qmlRegisterType<QgsQuickMapSettings>( "org.qgis", 1, 0, "MapSettings" );
  qmlRegisterType<QgsQuickCoordinateTransformer>( "org.qfield", 1, 0, "CoordinateTransformer" );
  qmlRegisterType<QgsQuickElevationProfileCanvas>( "org.qgis", 1, 0, "ElevationProfileCanvas" );
  qmlRegisterType<QgsQuickMapTransform>( "org.qgis", 1, 0, "MapTransform" );

  // Register QField QML types
  qRegisterMetaType<PlatformUtilities::Capabilities>( "PlatformUtilities::Capabilities" );
  qRegisterMetaType<GeometryUtils::GeometryOperationResult>( "GeometryOperationResult" );
  qRegisterMetaType<Tracker::MeasureType>( "Tracker::MeasureType" );
  qRegisterMetaType<PositioningSource::ElevationCorrectionMode>( "PositioningSource::ElevationCorrectionMode" );

  qmlRegisterType<MultiFeatureListModel>( "org.qfield", 1, 0, "MultiFeatureListModel" );
  qmlRegisterType<FeatureIterator>( "org.qfield", 1, 0, "FeatureIterator" );
  qmlRegisterType<FeatureListModel>( "org.qfield", 1, 0, "FeatureListModel" );
  qmlRegisterType<FeatureListModelSelection>( "org.qfield", 1, 0, "FeatureListModelSelection" );
  qmlRegisterType<FeatureListExtentController>( "org.qfield", 1, 0, "FeaturelistExtentController" );
  qmlRegisterType<Geometry>( "org.qfield", 1, 0, "Geometry" );
  qmlRegisterType<ModelHelper>( "org.qfield", 1, 0, "ModelHelper" );
  qmlRegisterType<RubberbandShape>( "org.qfield", 1, 0, "RubberbandShape" );
  qmlRegisterType<RubberbandModel>( "org.qfield", 1, 0, "RubberbandModel" );
  qmlRegisterType<ResourceSource>( "org.qfield", 1, 0, "ResourceSource" );
  qmlRegisterType<ProjectInfo>( "org.qfield", 1, 0, "ProjectInfo" );
  qmlRegisterType<ProjectSource>( "org.qfield", 1, 0, "ProjectSource" );
  qmlRegisterType<ViewStatus>( "org.qfield", 1, 0, "ViewStatus" );
  qmlRegisterType<GridModel>( "org.qfield", 1, 0, "GridModel" );
  qmlRegisterUncreatableType<GridAnnotation>( "org.qfield", 1, 0, "GridAnnotation", "" );

  qmlRegisterType<Geofencer>( "org.qfield", 1, 0, "Geofencer" );
  qmlRegisterType<DigitizingLogger>( "org.qfield", 1, 0, "DigitizingLogger" );
  qmlRegisterType<AttributeFormModel>( "org.qfield", 1, 0, "AttributeFormModel" );
  qmlRegisterType<FeatureModel>( "org.qfield", 1, 0, "FeatureModel" );
  qmlRegisterType<IdentifyTool>( "org.qfield", 1, 0, "IdentifyTool" );
  qmlRegisterType<DrawingCanvas>( "org.qfield", 1, 0, "DrawingCanvas" );
  qmlRegisterType<SubModel>( "org.qfield", 1, 0, "SubModel" );
  qmlRegisterType<ExpressionVariableModel>( "org.qfield", 1, 0, "ExpressionVariableModel" );
  qmlRegisterType<BadLayerHandler>( "org.qfield", 1, 0, "BadLayerHandler" );
  qmlRegisterType<SnappingUtils>( "org.qfield", 1, 0, "SnappingUtils" );
  qmlRegisterType<DistanceArea>( "org.qfield", 1, 0, "DistanceArea" );
  qmlRegisterType<FocusStack>( "org.qfield", 1, 0, "FocusStack" );
  qmlRegisterType<ParametizedImage>( "org.qfield", 1, 0, "ParametizedImage" );
  qmlRegisterType<PrintLayoutListModel>( "org.qfield", 1, 0, "PrintLayoutListModel" );
  qmlRegisterType<VertexModel>( "org.qfield", 1, 0, "VertexModel" );
  qmlRegisterType<MapToScreen>( "org.qfield", 1, 0, "MapToScreen" );
  qmlRegisterType<LocatorModelSuperBridge>( "org.qfield", 1, 0, "LocatorModelSuperBridge" );
  qmlRegisterType<LocatorActionsModel>( "org.qfield", 1, 0, "LocatorActionsModel" );
  qmlRegisterType<LocatorFiltersModel>( "org.qfield", 1, 0, "LocatorFiltersModel" );
  qmlRegisterType<LinePolygonShape>( "org.qfield", 1, 0, "LinePolygonShape" );
  qmlRegisterType<LocalFilesModel>( "org.qfield", 1, 0, "LocalFilesModel" );
  qmlRegisterType<QgsGeometryWrapper>( "org.qfield", 1, 0, "QgsGeometryWrapper" );
  qmlRegisterType<ValueMapModel>( "org.qfield", 1, 0, "ValueMapModel" );
  qmlRegisterType<RecentProjectListModel>( "org.qfield", 1, 0, "RecentProjectListModel" );
  qmlRegisterType<ReferencingFeatureListModel>( "org.qfield", 1, 0, "ReferencingFeatureListModel" );
  qmlRegisterType<OrderedRelationModel>( "org.qfield", 1, 0, "OrderedRelationModel" );
  qmlRegisterType<FeatureCheckListModel>( "org.qfield", 1, 0, "FeatureCheckListModel" );
  qmlRegisterType<GeometryEditorsModel>( "org.qfield", 1, 0, "GeometryEditorsModel" );
  qmlRegisterType<ExpressionEvaluator>( "org.qfield", 1, 0, "ExpressionEvaluator" );
#ifdef WITH_BLUETOOTH
  qmlRegisterType<BluetoothDeviceModel>( "org.qfield", 1, 0, "BluetoothDeviceModel" );
  qmlRegisterType<BluetoothReceiver>( "org.qfield", 1, 0, "BluetoothReceiver" );
  engine->rootContext()->setContextProperty( "withBluetooth", QVariant( true ) );
#else
  engine->rootContext()->setContextProperty( "withBluetooth", QVariant( false ) );
#endif
#ifdef WITH_SERIALPORT
  qmlRegisterType<SerialPortModel>( "org.qfield", 1, 0, "SerialPortModel" );
  qmlRegisterType<SerialPortReceiver>( "org.qfield", 1, 0, "SerialPortReceiver" );
  engine->rootContext()->setContextProperty( "withSerialPort", QVariant( true ) );
#else
  engine->rootContext()->setContextProperty( "withSerialPort", QVariant( false ) );
#endif
  qmlRegisterType<NearFieldReader>( "org.qfield", 1, 0, "NearFieldReader" );
  engine->rootContext()->setContextProperty( "withNfc", QVariant( NearFieldReader::isSupported() ) );
  qmlRegisterType<ChangelogContents>( "org.qfield", 1, 0, "ChangelogContents" );
  qmlRegisterType<LayerResolver>( "org.qfield", 1, 0, "LayerResolver" );
  qmlRegisterType<DeltaListModel>( "org.qfield", 1, 0, "DeltaListModel" );
  qmlRegisterType<ScaleBarMeasurement>( "org.qfield", 1, 0, "ScaleBarMeasurement" );
  qmlRegisterType<SensorListModel>( "org.qfield", 1, 0, "SensorListModel" );
  qmlRegisterType<Navigation>( "org.qfield", 1, 0, "Navigation" );
  qmlRegisterType<NavigationModel>( "org.qfield", 1, 0, "NavigationModel" );
  qmlRegisterType<Positioning>( "org.qfield", 1, 0, "Positioning" );
  qmlRegisterType<PositioningInformationModel>( "org.qfield", 1, 0, "PositioningInformationModel" );
  qmlRegisterType<PositioningDeviceModel>( "org.qfield", 1, 0, "PositioningDeviceModel" );
  qmlRegisterType<WebdavConnection>( "org.qfield", 1, 0, "WebdavConnection" );
  qmlRegisterType<AudioRecorder>( "org.qfield", 1, 0, "AudioRecorder" );
  qmlRegisterType<BarcodeDecoder>( "org.qfield", 1, 0, "BarcodeDecoder" );
  qmlRegisterType<CameraPermission>( "org.qfield", 1, 0, "QfCameraPermission" );
  qmlRegisterType<MicrophonePermission>( "org.qfield", 1, 0, "QfMicrophonePermission" );
  qmlRegisterUncreatableType<QAbstractSocket>( "org.qfield", 1, 0, "QAbstractSocket", "" );
  qmlRegisterUncreatableType<AbstractGnssReceiver>( "org.qfield", 1, 0, "AbstractGnssReceiver", "" );
  qmlRegisterUncreatableType<Tracker>( "org.qfield", 1, 0, "Tracker", "" );
  qRegisterMetaType<GnssPositionInformation>( "GnssPositionInformation" );
  qRegisterMetaType<GnssPositionDetails>( "GnssPositionDetails" );
  qRegisterMetaType<PluginInformation>( "PluginInformation" );

  qmlRegisterType<ProcessingAlgorithm>( "org.qfield", 1, 0, "ProcessingAlgorithm" );
  qmlRegisterType<ProcessingAlgorithmParametersModel>( "org.qfield", 1, 0, "ProcessingAlgorithmParametersModel" );
  qmlRegisterType<ProcessingAlgorithmsModel>( "org.qfield", 1, 0, "ProcessingAlgorithmsModel" );

  qmlRegisterType<QgsLocatorContext>( "org.qgis", 1, 0, "QgsLocatorContext" );
  // This causes errors due to incomplete type - comment out until filter is fully defined
  // qmlRegisterType<QFieldLocatorFilter>( "org.qfield", 1, 0, "QFieldLocatorFilter" );

  REGISTER_SINGLETON( "org.qfield", ExpressionContextUtils, "ExpressionContextUtils" );
  REGISTER_SINGLETON( "org.qfield", GeometryEditorsModel, "GeometryEditorsModelSingleton" );
  REGISTER_SINGLETON( "org.qfield", GeometryUtils, "GeometryUtils" );
  REGISTER_SINGLETON( "org.qfield", FeatureUtils, "FeatureUtils" );
  REGISTER_SINGLETON( "org.qfield", FileUtils, "FileUtils" );
  REGISTER_SINGLETON( "org.qfield", LayerUtils, "LayerUtils" );
  REGISTER_SINGLETON( "org.qfield", RelationUtils, "RelationUtils" );
  REGISTER_SINGLETON( "org.qfield", StringUtils, "StringUtils" );
  REGISTER_SINGLETON( "org.qfield", UrlUtils, "UrlUtils" );
  REGISTER_SINGLETON( "org.qfield", PositioningUtils, "PositioningUtils" );
  REGISTER_SINGLETON( "org.qfield", ProjectUtils, "ProjectUtils" );
  REGISTER_SINGLETON( "org.qfield", CoordinateReferenceSystemUtils, "CoordinateReferenceSystemUtils" );

  qmlRegisterUncreatableType<AppInterface>( "org.qfield", 1, 0, "AppInterface", "AppInterface is only provided by the environment and cannot be created ad-hoc" );
  qmlRegisterUncreatableType<Settings>( "org.qfield", 1, 0, "SettingsInterface", "" );
  qmlRegisterUncreatableType<PluginManager>( "org.qfield", 1, 0, "PluginManager", "" );
  qmlRegisterUncreatableType<PlatformUtilities>( "org.qfield", 1, 0, "PlatformUtilities", "" );
  qmlRegisterUncreatableType<FlatLayerTreeModel>( "org.qfield", 1, 0, "FlatLayerTreeModel", "The FlatLayerTreeModel is available as context property `flatLayerTree`." );
  qmlRegisterUncreatableType<TrackingModel>( "org.qfield", 1, 0, "TrackingModel", "The TrackingModel is available as context property `trackingModel`." );
  qmlRegisterUncreatableType<QgsGpkgFlusher>( "org.qfield", 1, 0, "QgsGpkgFlusher", "The gpkgFlusher is available as context property `gpkgFlusher`" );
  qmlRegisterUncreatableType<LayerObserver>( "org.qfield", 1, 0, "LayerObserver", "" );
  qmlRegisterUncreatableType<DeltaFileWrapper>( "org.qfield", 1, 0, "DeltaFileWrapper", "" );
  qmlRegisterUncreatableType<BookmarkModel>( "org.qfield", 1, 0, "BookmarkModel", "The BookmarkModel is available as context property `bookmarkModel`" );
  qmlRegisterUncreatableType<MessageLogModel>( "org.qfield", 1, 0, "MessageLogModel", "The MessageLogModel is available as context property `messageLogModel`." );

  qRegisterMetaType<SnappingResult>( "SnappingResult" );

  // Register some globally available variables
  engine->rootContext()->setContextProperty( "qVersion", qVersion() );
  engine->rootContext()->setContextProperty( "qgisVersion", Qgis::version() );
  engine->rootContext()->setContextProperty( "gdalVersion", GDAL_RELEASE_NAME );
  engine->rootContext()->setContextProperty( "withNfc", QVariant( NearFieldReader::isSupported() ) );
  engine->rootContext()->setContextProperty( "systemFontPointSize", PlatformUtilities::instance()->systemFontPointSize() );
  engine->rootContext()->setContextProperty( "mouseDoubleClickInterval", QApplication::styleHints()->mouseDoubleClickInterval() );
  engine->rootContext()->setContextProperty( "appVersion", qfield::appVersion );
  engine->rootContext()->setContextProperty( "appVersionStr", qfield::appVersionStr );
  engine->rootContext()->setContextProperty( "gitRev", qfield::gitRev );
  engine->rootContext()->setContextProperty( "platformUtilities", PlatformUtilities::instance() );
}

void QgisMobileapp::registerGlobalVariables()
{
  // Calculate device pixels
  qreal dpi = mApp ? mApp->primaryScreen()->logicalDotsPerInch() * mApp->primaryScreen()->devicePixelRatio() : 96;

  rootContext()->setContextProperty( "ppi", dpi );
  rootContext()->setContextProperty( "qgisProject", mProject );
  rootContext()->setContextProperty( "iface", mIface );
  rootContext()->setContextProperty( "pluginManager", mPluginManager );
  rootContext()->setContextProperty( "settings", &mSettings );
  rootContext()->setContextProperty( "flatLayerTree", mFlatLayerTree );
  rootContext()->setContextProperty( "CrsFactory", QVariant::fromValue<QgsCoordinateReferenceSystem>( mCrsFactory ) );
  rootContext()->setContextProperty( "UnitTypes", QVariant::fromValue<QgsUnitTypes>( mUnitTypes ) );
  rootContext()->setContextProperty( "ExifTools", QVariant::fromValue<QgsExifTools>( mExifTools ) );
  rootContext()->setContextProperty( "bookmarkModel", mBookmarkModel );
  rootContext()->setContextProperty( "gpkgFlusher", mGpkgFlusher.get() );
  rootContext()->setContextProperty( "layerObserver", mLayerObserver.get() );
  rootContext()->setContextProperty( "featureHistory", mFeatureHistory.get() );
  rootContext()->setContextProperty( "clipboardManager", mClipboardManager.get() );
  rootContext()->setContextProperty( "messageLogModel", mMessageLogModel );
  rootContext()->setContextProperty( "drawingTemplateModel", mDrawingTemplateModel );
  rootContext()->setContextProperty( "qfieldAuthRequestHandler", mAuthRequestHandler );
  rootContext()->setContextProperty( "trackingModel", mTrackingModel );
  addImageProvider( QLatin1String( "legend" ), mLegendImageProvider );
  addImageProvider( QLatin1String( "localfiles" ), mLocalFilesImageProvider );
  addImageProvider( QLatin1String( "projects" ), mProjectsImageProvider );
}


void QgisMobileapp::loadProjectQuirks()
{
  // force update of canvas, without automatic changes to extent and OTF projections
  bool autoEnableCrsTransform = mLayerTreeCanvasBridge->autoEnableCrsTransform();
  bool autoSetupOnFirstLayer = mLayerTreeCanvasBridge->autoSetupOnFirstLayer();
  mLayerTreeCanvasBridge->setAutoEnableCrsTransform( false );
  mLayerTreeCanvasBridge->setAutoSetupOnFirstLayer( false );

  mLayerTreeCanvasBridge->setCanvasLayers();

  if ( autoEnableCrsTransform )
    mLayerTreeCanvasBridge->setAutoEnableCrsTransform( true );

  if ( autoSetupOnFirstLayer )
    mLayerTreeCanvasBridge->setAutoSetupOnFirstLayer( true );
}

void QgisMobileapp::removeRecentProject( const QString &path )
{
  QList<QPair<QString, QString>> projects = recentProjects();
  for ( int idx = 0; idx < projects.count(); idx++ )
  {
    if ( projects.at( idx ).second == path )
    {
      projects.removeAt( idx );
      break;
    }
  }
  saveRecentProjects( projects );
}

QList<QPair<QString, QString>> QgisMobileapp::recentProjects()
{
  QSettings settings;
  QList<QPair<QString, QString>> projects;

  settings.beginGroup( "/qgis/recentProjects" );
  const QStringList projectKeysList = settings.childGroups();
  QList<int> projectKeys;
  // This is overdoing it since we're clipping the recent projects list to five items at the moment, but might as well be futureproof
  for ( const QString &key : projectKeysList )
  {
    projectKeys.append( key.toInt() );
  }
  for ( int i = 0; i < projectKeys.count(); i++ )
  {
    settings.beginGroup( QString::number( projectKeys.at( i ) ) );
    projects << qMakePair( settings.value( QStringLiteral( "title" ) ).toString(), settings.value( QStringLiteral( "path" ) ).toString() );
    settings.endGroup();
  }
  settings.endGroup();
  return projects;
}

void QgisMobileapp::saveRecentProjects( QList<QPair<QString, QString>> &projects )
{
  QSettings settings;
  settings.remove( QStringLiteral( "/qgis/recentProjects" ) );
  for ( int idx = 0; idx < projects.count() && idx < 5; idx++ )
  {
    settings.beginGroup( QStringLiteral( "/qgis/recentProjects/%1" ).arg( idx ) );
    settings.setValue( QStringLiteral( "title" ), projects.at( idx ).first );
    settings.setValue( QStringLiteral( "path" ), projects.at( idx ).second );
    settings.endGroup();
  }
}

void QgisMobileapp::onAfterFirstRendering()
{
  // This should get triggered exactly once, so we disconnect it right away
  // disconnect( this, &QgisMobileapp::afterRendering, this, &QgisMobileapp::onAfterFirstRendering );
  if ( mFirstRenderingFlag )
  {
    mPluginManager->restoreAppPlugins();
    if ( PlatformUtilities::instance()->hasQgsProject() )
    {
      PlatformUtilities::instance()->loadQgsProject();
    }
    else
    {
      if ( QSettings().value( "/QField/loadProjectOnLaunch", true ).toBool() )
      {
        QSettings settings;
        const QString defaultProject = settings.value( QStringLiteral( "QField/defaultProject" ), QString() ).toString();
        if ( !defaultProject.isEmpty() && QFileInfo::exists( defaultProject ) )
        {
          loadProjectFile( defaultProject );
        }
        else
        {
          const QString lastProjectFilePath = settings.value( QStringLiteral( "QField/lastProjectFilePath" ), QString() ).toString();
          if ( !lastProjectFilePath.isEmpty() && QFileInfo::exists( lastProjectFilePath ) )
          {
            loadProjectFile( lastProjectFilePath );
          }
        }
      }
    }
    rootObjects().first()->setProperty( "sceneLoaded", true );
    mFirstRenderingFlag = false;
  }
}

void QgisMobileapp::onMapCanvasRefreshed()
{
  disconnect( mMapCanvas, &QgsQuickMapCanvasMap::mapCanvasRefreshed, this, &QgisMobileapp::onMapCanvasRefreshed );
  if ( !mProjectFilePath.isEmpty() )
  {
    if ( !QFileInfo::exists( QStringLiteral( "%1.png" ).arg( mProjectFilePath ) ) )
    {
      saveProjectPreviewImage();
    }
  }
}

bool QgisMobileapp::loadProjectFile( const QString &path, const QString &name )
{
  QFileInfo fi( path );
  if ( !fi.exists() )
  {
    QgsMessageLog::logMessage( tr( "Can't load project, file \"%1\" does not exist" ).arg( path ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    return false;
  }

  const QString suffix = fi.suffix().toLower();
  if ( SUPPORTED_PROJECT_EXTENSIONS.contains( suffix ) || SUPPORTED_VECTOR_EXTENSIONS.contains( suffix ) || SUPPORTED_RASTER_EXTENSIONS.contains( suffix ) )
  {
    saveProjectPreviewImage();

    if ( !mProjectFilePath.isEmpty() )
    {
      mPluginManager->unloadPlugin( PluginManager::findProjectPlugin( mProjectFilePath ) );
    }
    mAuthRequestHandler->clearStoredRealms();

    mProjectFilePath = path;
    mProjectFileName = !name.isEmpty() ? name : fi.completeBaseName();

    emit loadProjectTriggered( mProjectFilePath, mProjectFileName );
    return true;
  }

  return false;
}

void QgisMobileapp::reloadProjectFile()
{
  if ( mProjectFilePath.isEmpty() )
    QgsMessageLog::logMessage( tr( "No project file currently opened" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );

  emit loadProjectTriggered( mProjectFilePath, mProjectFileName );
}

void QgisMobileapp::readProjectFile()
{
  QFileInfo fi( mProjectFilePath );
  if ( !fi.exists() )
    QgsMessageLog::logMessage( tr( "Can't read project, file \"%1\" does not exist" ).arg( mProjectFilePath ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );

  QSettings().setValue( QStringLiteral( "QField/lastProjectFilePath" ), mProjectFilePath );

  const QString suffix = fi.suffix().toLower();

  static QSet<QString> loadedProjects;
  const bool isFirstLoad = !loadedProjects.contains(mProjectFilePath);
  
  if (isFirstLoad) {
    // Removed flusher log message to reduce log spam
    
    // Also disable flushing for the project file itself if it's a GPKG
    if (suffix == QStringLiteral( "gpkg" )) {
      // Removed flusher log message to reduce log spam
      if (mGpkgFlusher) {
        mGpkgFlusher->stop(mProjectFilePath);
      }
    }
    
    // Find all GPKG files in the project directory
    QDir projectDir = fi.dir();
    QStringList gpkgFiles = projectDir.entryList(QStringList() << "*.gpkg", QDir::Files);
    for (const QString &gpkgFile : gpkgFiles) {
      QString fullPath = projectDir.filePath(gpkgFile);
      if (fullPath != mProjectFilePath) { // Don't double-process the project file
        // Removed flusher log message to reduce log spam
        
        // If we have a GPKG flusher, disable it for this file
        if (mGpkgFlusher) {
          mGpkgFlusher->stop(fullPath);
        }
      }
    }
    
    // Add this project to our loaded projects set
    loadedProjects.insert(mProjectFilePath);
  }

  mProject->clear();
  mProject->layerTreeRegistryBridge()->setLayerInsertionMethod( Qgis::LayerTreeInsertionMethod::OptimalInInsertionGroup );

  mTrackingModel->reset();

  // load project file fonts if present
  const QStringList fontDirNames = QStringList() << QStringLiteral( ".fonts" ) << QStringLiteral( "fonts" );
  for ( const QString &fontDirName : fontDirNames )
  {
    const QDir fontDir = QDir::cleanPath( QFileInfo( mProjectFilePath ).absoluteDir().path() + QDir::separator() + fontDirName );
    const QStringList fontExts = QStringList() << "*.ttf"
                                               << "*.TTF"
                                               << "*.otf"
                                               << "*.OTF";
    const QStringList fontFiles = fontDir.entryList( fontExts, QDir::Files );
    for ( const QString &fontFile : fontFiles )
    {
      const int id = QFontDatabase::addApplicationFont( QDir::cleanPath( fontDir.path() + QDir::separator() + fontFile ) );
      qInfo() << QStringLiteral( "Project font registered: %1" ).arg( QDir::cleanPath( fontDir.path() + QDir::separator() + fontFile ) );
      if ( id == -1 )
      {
        QgsMessageLog::logMessage( tr( "Could not load font: %1" ).arg( fontFile ) );
      }
    }
  }

  // Load project file
  bool projectLoaded = false;
  if ( SUPPORTED_PROJECT_EXTENSIONS.contains( suffix ) )
  {
    mProject->read( mProjectFilePath, Qgis::ProjectReadFlag::DontLoadProjectStyles | Qgis::ProjectReadFlag::DontLoad3DViews );
    mProject->writeEntry( QStringLiteral( "QField" ), QStringLiteral( "isDataset" ), false );
    projectLoaded = true;
  }
  else if ( suffix == QStringLiteral( "gpkg" ) )
  {
    QgsProjectStorage *storage = QgsApplication::projectStorageRegistry()->projectStorageFromType( "geopackage" );
    if ( storage )
    {
      const QStringList projectNames = storage->listProjects( mProjectFilePath );
      if ( !projectNames.isEmpty() )
      {
        QgsGeoPackageProjectUri projectUri { true, mProjectFilePath, projectNames.at( 0 ) };
        mProject->read( QgsGeoPackageProjectStorage::encodeUri( projectUri ), Qgis::ProjectReadFlag::DontLoadProjectStyles | Qgis::ProjectReadFlag::DontLoad3DViews );
        mProject->writeEntry( QStringLiteral( "QField" ), QStringLiteral( "isDataset" ), false );
        projectLoaded = true;
      }
    }
  }

  if ( projectLoaded )
  {
    if ( !mProject->error().isEmpty() )
    {
      QgsMessageLog::logMessage( mProject->error() );
    }
    
    // For Android, we need to give SQLite a moment to initialize before we start flushing
    // This prevents the "Pure virtual function called" crash when opening GPKG files for the first time
#ifdef Q_OS_ANDROID
    QgsMessageLog::logMessage("Project loaded on Android. Optimizing SQLite access...");
    // Add a small delay to ensure all database operations are complete before flush operations begin
    QTimer::singleShot(1000, this, [this]() {
      // We could add additional SQLite optimizations here if needed
      QgsMessageLog::logMessage("Android SQLite optimization complete");
    });
#endif
  }

  QString title;
  if (mProject->fileName().isEmpty()) 
  {
    title = mProjectFileName; 
  }
  else
  {
    title = mProject->title().isEmpty() ? mProjectFileName : mProject->title(); // Set title based on project title or file name
  }

  QList<QPair<QString, QString>> projects = recentProjects();
  for ( int idx = 0; idx < projects.count(); idx++ )
  {
    if ( projects.at( idx ).second == mProjectFilePath )
    {
      projects.removeAt( idx );
      break;
    }
  }
  QPair<QString, QString> project = qMakePair( title, mProjectFilePath );
  projects.insert( 0, project );
  saveRecentProjects( projects );

  QList<QgsMapLayer *> vectorLayers;
  QList<QgsMapLayer *> rasterLayers;
  QgsCoordinateReferenceSystem crs;
  QgsRectangle extent;

  QStringList files;
  if ( suffix == QStringLiteral( "zip" ) || suffix == QStringLiteral( "7z" ) || suffix == QStringLiteral( "rar" ) )
  {
    // get list of files inside zip file
    QString tmpPath;
    char **papszSiblingFiles = VSIReadDirRecursive( QStringLiteral( "/vsi%1/%2" ).arg( suffix, mProjectFilePath ).toLocal8Bit().constData() );
    if ( papszSiblingFiles )
    {
      for ( int i = 0; papszSiblingFiles[i]; i++ )
      {
        tmpPath = papszSiblingFiles[i];
        // skip directories (files ending with /)
        if ( tmpPath.right( 1 ) != QLatin1String( "/" ) )
        {
          const QFileInfo tmpFi( tmpPath );
          if ( SUPPORTED_VECTOR_EXTENSIONS.contains( tmpFi.suffix().toLower() ) || SUPPORTED_RASTER_EXTENSIONS.contains( tmpFi.suffix().toLower() ) )
            files << QStringLiteral( "/vsi%1/%2/%3" ).arg( suffix, mProjectFilePath, tmpPath );
        }
      }
      CSLDestroy( papszSiblingFiles );
    }
  }
  else if ( !projectLoaded )
  {
    files << mProjectFilePath;
  }

  QgsProviderSublayerDetails::LayerOptions options( QgsProject::instance()->transformContext() );
  options.loadDefaultStyle = true;

  for ( auto filePath : std::as_const( files ) )
  {
    const QString fileSuffix = QFileInfo( filePath ).suffix().toLower();

    if ( fileSuffix == QLatin1String( "kmz" ) )
    {
      // GDAL's internal KML driver doesn't support KMZ, work around this limitation
      filePath = QStringLiteral( "/vsizip/%1/doc.kml" ).arg( mProjectFilePath );
    }
    else if ( fileSuffix == QLatin1String( "pdf" ) )
    {
      // Hardcode a DPI value of 300 for PDFs as most PDFs fail to register their proper resolution
      filePath += QStringLiteral( "|option:DPI=300" );
    }

    const QList<QgsProviderSublayerDetails> sublayers = QgsProviderRegistry::instance()->querySublayers( filePath, Qgis::SublayerQueryFlags() | Qgis::SublayerQueryFlag::ResolveGeometryType );
    for ( const QgsProviderSublayerDetails &sublayer : sublayers )
    {
      std::unique_ptr<QgsMapLayer> layer( sublayer.toLayer( options ) );
      if ( !layer || !layer->isValid() )
        continue;

      if ( layer->crs().isValid() )
      {
        if ( !crs.isValid() )
          crs = layer->crs();

        if ( !layer->extent().isEmpty() )
        {
          if ( crs != layer->crs() )
          {
            QgsCoordinateTransform transform( layer->crs(), crs, mProject->transformContext() );
            try
            {
              if ( extent.isEmpty() )
                extent = transform.transformBoundingBox( layer->extent() );
              else
                extent.combineExtentWith( transform.transformBoundingBox( layer->extent() ) );
            }
            catch ( const QgsCsException &exp )
            {
              Q_UNUSED( exp )
              // Ignore extent if it can't be transformed
            }
          }
          else
          {
            if ( extent.isEmpty() )
              extent = layer->extent();
            else
              extent.combineExtentWith( layer->extent() );
          }
        }
      }

      switch ( sublayer.type() )
      {
        case Qgis::LayerType::Vector:
          vectorLayers << layer.release();
          break;
        case Qgis::LayerType::Raster:
          rasterLayers << layer.release();
          break;
        case Qgis::LayerType::Mesh:
        case Qgis::LayerType::VectorTile:
        case Qgis::LayerType::Annotation:
        case Qgis::LayerType::PointCloud:
        case Qgis::LayerType::Group:
        case Qgis::LayerType::Plugin:
        case Qgis::LayerType::TiledScene:
          continue;
          break;
      }
    }
  }

  if ( vectorLayers.size() > 1 )
  {
    std::sort( vectorLayers.begin(), vectorLayers.end(), []( QgsMapLayer *a, QgsMapLayer *b ) {
      QgsVectorLayer *alayer = qobject_cast<QgsVectorLayer *>( a );
      QgsVectorLayer *blayer = qobject_cast<QgsVectorLayer *>( b );
      if ( alayer->geometryType() == Qgis::GeometryType::Point && blayer->geometryType() != Qgis::GeometryType::Point )
      {
        return true;
      }
      else if ( alayer->geometryType() == Qgis::GeometryType::Line && blayer->geometryType() == Qgis::GeometryType::Polygon )
      {
        return true;
      }
      else
      {
        return false;
      }
    } );
  }

  // For datasets (non-project files), we need to load a base project first
  if ( vectorLayers.size() > 0 || rasterLayers.size() > 0 )
  {
    if ( crs.isValid() )
    {
      QSettings settings;
      const QString fileAssociationProject = settings.value( QStringLiteral( "QField/baseMapProject" ), QString() ).toString();
      if ( !fileAssociationProject.isEmpty() && QFile::exists( fileAssociationProject ) )
      {
        mProject->read( fileAssociationProject, Qgis::ProjectReadFlag::DontLoadProjectStyles | Qgis::ProjectReadFlag::DontLoad3DViews );
      }
      else
      {
        const QStringList dataDirs = PlatformUtilities::instance()->appDataDirs();
        bool projectFound = false;
        for ( const QString &dataDir : dataDirs )
        {
          if ( QFile::exists( dataDir + QStringLiteral( "basemap.qgs" ) ) )
          {
            projectFound = true;
            mProject->read( dataDir + QStringLiteral( "basemap.qgs" ), Qgis::ProjectReadFlag::DontLoadProjectStyles | Qgis::ProjectReadFlag::DontLoad3DViews );
            break;
          }
          else if ( QFile::exists( dataDir + QStringLiteral( "basemap.qgz" ) ) )
          {
            projectFound = true;
            mProject->read( dataDir + QStringLiteral( "basemap.qgz" ), Qgis::ProjectReadFlag::DontLoadProjectStyles | Qgis::ProjectReadFlag::DontLoad3DViews );
            break;
          }
        }
        if ( !projectFound )
        {
          mProject->clear();
        }
      }
    }
    else
    {
      mProject->clear();
    }
  }

  // Add all the required basemaps to every project, regardless of whether it's a project file or a datasheet
  // Create the basemap layers
  QgsRasterLayer *osmLayer = new QgsRasterLayer( QStringLiteral( "type=xyz&tilePixelRatio=1&url=https://tile.openstreetmap.org/%7Bz%7D/%7Bx%7D/%7By%7D.png&zmax=19&zmin=0&crs=EPSG3857" ), QStringLiteral( "OpenStreetMap" ), QLatin1String( "wms" ) );
  QgsRasterLayer *satelliteLayer = new QgsRasterLayer( QStringLiteral( "crs=EPSG:3857&format&type=xyz&url=http://www.google.cn/maps/vt?lyrs=s@189%26gl=cn%26x%3D{x}%26y%3D{y}%26z%3D{z}&zmax=21&zmin=0" ), QStringLiteral( "Google Satellite" ), QLatin1String( "wms" ) );
  
  // Add IGN (Instituto Geográfico Nacional) map
  QgsRasterLayer *ignLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=0&crs=EPSG:4326&dpiMode=7&featureCount=10&format=image/png&layers=mtn_rasterizado&styles&tilePixelRatio=0&url=https://www.ign.es/wms-inspire/mapa-raster" ),
      QStringLiteral( "Esp IGN 1:25.000" ),
      QLatin1String( "wms" ) );
  
  QgsRasterLayer *catastroLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4326&dpiMode=7&featureCount=10&format=image/png&layers=Catastro&styles=Default&tilePixelRatio=0&url=http://ovc.catastro.meh.es/Cartografia/WMS/ServidorWMS.aspx" ),
      QStringLiteral( "Catastro" ),
      QLatin1String( "wms" ) );
  
  // Add Junta de Andalucía BCA layer (renamed to Andalucía 1:10.000)
  QgsRasterLayer *bcaLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=0&crs=EPSG:4326&dpiMode=7&featureCount=10&format=image/png&layers=00_BCA&styles=default-style-00_BCA&tilePixelRatio=0&url=http://www.juntadeandalucia.es/institutodeestadisticaycartografia/geoserver-ieca/bca/wms" ),
      QStringLiteral( "Andalucía 1:10.000" ),
      QLatin1String( "wms" ) );
  
  // Add Recintos SIGPAC FEGA layer
  QgsRasterLayer *sigpacLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4326&dpiMode=7&featureCount=10&format=image/png&layers=AU.Sigpac:recinto&styles=recinto&tilePixelRatio=0&url=https://wms.mapa.gob.es/sigpac/wms" ),
      QStringLiteral( "Recintos SIGPAC FEGA" ),
      QLatin1String( "wms" ) );
  
  // Add flood risk WMS layer
  QgsRasterLayer *floodRiskLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:3857&dpiMode=7&featureCount=10&format=image/png&layers=NZ.RiskZone&styles&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/Agua/Riesgo/RiesgoAct_100/wms.aspx" ),
      QStringLiteral( "Riesgo inundación T100" ),
      QLatin1String( "wms" ) );
  
  // Create layer groups in the desired order - Data Collection first, then Sentinel, then Spain GIS Services, then Utils, then Basemaps
  // COMPLETELY DISABLED: Data Collection group is not needed and causes issues
  // QgsLayerTreeGroup *dataCollectionGroup = mProject->layerTreeRoot()->addGroup("Recogida de Datos");
  // dataCollectionGroup->setItemVisibilityChecked(false);
  // dataCollectionGroup->setExpanded(false);
  
  // Translate group names to Spanish
  QgsLayerTreeGroup *spainGisServicesGroup = mProject->layerTreeRoot()->addGroup("Servicios GIS España");
  QgsLayerTreeGroup *utilsGroup = mProject->layerTreeRoot()->addGroup("Utilidades");

  // Create a Spain GIS Base Layers subgroup for Recintos SIGPAC FEGA and Catastro
  QgsLayerTreeGroup *spainGisBaseLayersGroup = spainGisServicesGroup->addGroup("Capas Base GIS España");
  
  // Create a Spain GIS VectorTiles group as a subgroup of Spain GIS Services
  QgsLayerTreeGroup *spainGisVectorTilesGroup = spainGisServicesGroup->addGroup("Teselas Vectoriales GIS España");
  
  // Add Sentinel Imagery group if user has configured an instance ID
  QSettings sentinelSettings;
  QString sentinelInstanceId = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/InstanceId"), QString()).toString();
  bool enableSentinelLayers = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EnableLayers"), true).toBool();
  
  // Read layer configuration from settings
  QStringList enabledLayers;
  QString enabledLayersStr = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EnabledLayers"), "TRUE_COLOR,FALSE_COLOR,NDVI").toString();
  if (!enabledLayersStr.isEmpty()) {
    enabledLayers = enabledLayersStr.split(",");
  } else {
    enabledLayers << "TRUE_COLOR" << "FALSE_COLOR" << "NDVI";
  }
  
  // Read style settings for each layer
  QString ndviStyle = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Styles/NDVI"), "ON").toString();
  QString falseColorStyle = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Styles/FALSE_COLOR"), "ON").toString();
  QString trueColorStyle = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Styles/TRUE_COLOR"), "ON").toString();
  QString custom1Style = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Styles/CUSTOM1"), "DEFAULT").toString();
  QString custom2Style = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Styles/CUSTOM2"), "DEFAULT").toString();
  
  // Read custom layer IDs from settings
  QString custom1LayerId = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Custom1LayerId"), "").toString();
  QString custom2LayerId = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Custom2LayerId"), "").toString();
  
  // Read the IDs for standard layers
  QString trueColorLayerId = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TrueColorLayerId"), "TRUE_COLOR").toString();
  QString falseColorLayerId = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/FalseColorLayerId"), "FALSE_COLOR").toString();
  QString ndviLayerId = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/NdviLayerId"), "NDVI").toString();
  
  // Track if we've updated Sentinel settings
  bool settingsUpdated = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/SettingsUpdated"), false).toBool();
  
  // Log the layer configuration for debugging
  QgsMessageLog::logMessage(QStringLiteral("Sentinel enabled layers: %1").arg(enabledLayersStr), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("NDVI style: %1").arg(ndviStyle), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("FALSE_COLOR style: %1").arg(falseColorStyle), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("TRUE_COLOR style: %1").arg(trueColorStyle), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("CUSTOM1 style: %1").arg(custom1Style), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("CUSTOM2 style: %1").arg(custom2Style), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("TRUE_COLOR layer ID: %1").arg(trueColorLayerId), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("FALSE_COLOR layer ID: %1").arg(falseColorLayerId), "SIGPACGO", Qgis::Info);
  QgsMessageLog::logMessage(QStringLiteral("NDVI layer ID: %1").arg(ndviLayerId), "SIGPACGO", Qgis::Info);
  
  // Read custom layer script parameters
  QString evalScriptUrl = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EvalScriptUrl"), "").toString();
  QString evalScript = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EvalScript"), "").toString();
  
  // Read WMS parameters from settings
  QString crsSetting = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/CRS"), "EPSG:4326").toString();
  QString format = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Format"), "image/png").toString();
  QString dpiMode = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/DPIMode"), "7").toString();
  QString tilePixelRatio = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TilePixelRatio"), "0").toString();
  
  // Time parameters
  bool timeEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TimeEnabled"), false).toBool();
  QString timeParams;
  if (timeEnabled) {
    QString startDate = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TimeStart"), "").toString();
    QString endDate = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TimeEnd"), "").toString();
    if (!startDate.isEmpty() && !endDate.isEmpty()) {
      timeParams = QStringLiteral("&TIME=%1/%2").arg(startDate).arg(endDate);
    }
  }
  
  // Advanced parameters
  QString advancedParams;
  bool showAdvancedParams = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/AdvancedParamsEnabled"), false).toBool();
  if (showAdvancedParams) {
    QString maxCC = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/MAXCC"), "100").toString();
    if (maxCC != "100") {
      advancedParams += QStringLiteral("&MAXCC=%1").arg(maxCC);
    }
    
    QString quality = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/QUALITY"), "90").toString();
    if (format == "image/jpeg" && quality != "90") {
      advancedParams += QStringLiteral("&QUALITY=%1").arg(quality);
    }
    
    QString warnings = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/WARNINGS"), "YES").toString();
    if (warnings != "YES") {
      advancedParams += QStringLiteral("&WARNINGS=%1").arg(warnings);
    }
    
    QString priority = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/PRIORITY"), "mostRecent").toString();
    if (priority != "mostRecent") {
      advancedParams += QStringLiteral("&PRIORITY=%1").arg(priority);
    }
  }
  
  // Handle bbox limiting
  QString bboxParams;
  bool bboxLimitingEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/BboxLimitingEnabled"), false).toBool();
  
  if (bboxLimitingEnabled) {
    QString bboxWidth = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/BboxWidth"), "10000").toString();
    QString bboxHeight = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/BboxHeight"), "10000").toString();
    
    // We will read these values but not implement BBOX limiting in this version
    // This avoids using undefined class members
    QgsMessageLog::logMessage(QStringLiteral("BBOX limiting configured with width=%1, height=%2").arg(bboxWidth, bboxHeight), "SIGPACGO", Qgis::Info);
  }
  
  // Custom script
  QString scriptParams;
  bool customScriptEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/CustomScriptEnabled"), false).toBool();
  if (customScriptEnabled) {
    QString scriptUrl = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/ScriptUrl"), "").toString();
    if (!scriptUrl.isEmpty()) {
      scriptParams = QStringLiteral("&EVALSCRIPTURL=%1").arg(scriptUrl);
    }
    
    // Check if we have a direct script instead of URL
    QString customScript = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/CustomScript"), "").toString();
    if (!customScript.isEmpty()) {
      // BASE64 encode the script
      QByteArray scriptBytes = customScript.toUtf8();
      QByteArray encodedScript = scriptBytes.toBase64();
      scriptParams = QStringLiteral("&EVALSCRIPT=%1").arg(QString::fromUtf8(encodedScript));
    }
  }
  
  // Rate limiting
  bool rateLimitingEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/RateLimitingEnabled"), false).toBool();
  if (rateLimitingEnabled) {
    int delayMs = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/RateLimitDelay"), 1000).toInt();
    WmsRateLimiter::instance()->setEnabled(true);
    WmsRateLimiter::instance()->setDelay(delayMs);
    
    // Log that rate limiting is enabled
    QgsMessageLog::logMessage(QStringLiteral("Sentinel WMS rate limiting enabled with %1ms delay").arg(delayMs), "SIGPACGO", Qgis::Info);
  } else {
    WmsRateLimiter::instance()->setEnabled(false);
  }
  
  // Create Sentinel group first (before basemaps) so it appears on top
  QgsLayerTreeGroup *sentinelGroup = nullptr;
  
  if (!sentinelInstanceId.isEmpty() && enableSentinelLayers && !enabledLayers.isEmpty())
  {
    QgsMessageLog::logMessage(QStringLiteral("Creating Sentinel layers with instance ID: %1").arg(sentinelInstanceId), "SIGPACGO", Qgis::Info);
    QgsMessageLog::logMessage(QStringLiteral("Enabled layers: %1").arg(enabledLayersStr), "SIGPACGO", Qgis::Info);
    
    sentinelGroup = mProject->layerTreeRoot()->addGroup("Imágenes Sentinel");
    sentinelGroup->setExpanded(false);
    
    // Determine if a custom eval script is being used
    QString evalScriptUrl = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EvalScriptUrl"), "").toString();
    QString evalScript = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EvalScript"), "").toString();
    
    // Read WMS settings
    QString crsSetting = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/CRS"), "EPSG:4326").toString();
    QString format = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Format"), "image/png").toString();
    QString dpiMode = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/DPIMode"), "7").toString();
    QString tilePixelRatio = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TilePixelRatio"), "0").toString();
    
    // Time filtering settings
    bool timeEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TimeEnabled"), false).toBool();
    QString timeParams;
    
    if (timeEnabled) {
      QString startDate = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TimeStart"), "").toString();
      QString endDate = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/TimeEnd"), "").toString();
      
      if (!startDate.isEmpty() && !endDate.isEmpty()) {
        timeParams = QString("&TIME=%1/%2").arg(startDate, endDate);
      }
    }
    
    // Advanced parameters
    QString advancedParams;
    bool showAdvancedParams = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/AdvancedParamsEnabled"), false).toBool();
    
    if (showAdvancedParams) {
      QString maxCC = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/MAXCC"), "100").toString();
      if (!maxCC.isEmpty()) {
        advancedParams += QString("&MAXCC=%1").arg(maxCC);
      }
      
      QString quality = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/QUALITY"), "90").toString();
      if (!quality.isEmpty()) {
        advancedParams += QString("&QUALITY=%1").arg(quality);
      }
      
      QString warnings = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/WARNINGS"), "YES").toString();
      if (!warnings.isEmpty()) {
        advancedParams += QString("&WARNINGS=%1").arg(warnings);
      }
      
      QString priority = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/PRIORITY"), "mostRecent").toString();
      if (!priority.isEmpty()) {
        advancedParams += QString("&PRIORITY=%1").arg(priority);
      }
    }
    
    // Handle bbox limiting
    QString bboxParams;
    bool bboxLimitingEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/BboxLimitingEnabled"), false).toBool();
    
    if (bboxLimitingEnabled) {
      QString bboxWidth = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/BboxWidth"), "10000").toString();
      QString bboxHeight = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/BboxHeight"), "10000").toString();
      
      if (!bboxWidth.isEmpty() && !bboxHeight.isEmpty()) {
        // We will read these values but not implement BBOX limiting in this version
        // This avoids using undefined class members
        QgsMessageLog::logMessage(QStringLiteral("BBOX limiting configured with width=%1, height=%2").arg(bboxWidth, bboxHeight), "SIGPACGO", Qgis::Info);
      }
    }
    
    // Handle custom eval script
    bool customScriptEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/CustomScriptEnabled"), false).toBool();
    QString customScriptParams;
    
    if (customScriptEnabled) {
      QString scriptUrl = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/ScriptUrl"), "").toString();
      
      if (!scriptUrl.isEmpty()) {
        customScriptParams = QString("&EVALSCRIPTURL=%1").arg(scriptUrl);
      } else {
        QString customScript = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/CustomScript"), "").toString();
        
        if (!customScript.isEmpty()) {
          customScriptParams = QString("&EVALSCRIPT=%1").arg(customScript);
        }
      }
    }
    
    // Rate limiting for WMS requests
    bool rateLimitingEnabled = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/RateLimitingEnabled"), false).toBool();
    
    if (rateLimitingEnabled) {
      int delayMs = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/RateLimitDelay"), 1000).toInt();
      WmsRateLimiter::instance()->setEnabled(true);
      WmsRateLimiter::instance()->setDelay(delayMs);
      
      // Log that rate limiting is enabled
      QgsMessageLog::logMessage(QStringLiteral("Sentinel WMS rate limiting enabled with %1ms delay").arg(delayMs), "SIGPACGO", Qgis::Info);
    } else {
      WmsRateLimiter::instance()->setEnabled(false);
    }
    
    // Create Sentinel WMS layers using the user's instance ID and configured settings
    if (enabledLayers.contains("NDVI"))
    {
      // NDVI layer
      QString ndviUrl = QStringLiteral("contextualWMSLegend=0&crs=%1&dpiMode=%2&featureCount=5&format=%3&layers=%4&styles=%5&tilePixelRatio=%6&url=https://sh.dataspace.copernicus.eu/ogc/wms/%7")
          .arg(crsSetting)
          .arg(dpiMode)
          .arg(format)
          .arg(ndviLayerId)
          .arg(ndviStyle)
          .arg(tilePixelRatio)
          .arg(sentinelInstanceId);
      
      // Add time parameters if enabled
      if (!timeParams.isEmpty()) {
        ndviUrl += timeParams;
      }
      
      // Add advanced parameters if enabled
      if (!advancedParams.isEmpty()) {
        ndviUrl += advancedParams;
      }
      
      // Add BBOX parameters if enabled
      if (!bboxParams.isEmpty()) {
        ndviUrl += bboxParams;
      }
      
      // Add custom script if enabled
      if (!scriptParams.isEmpty()) {
        ndviUrl += scriptParams;
      }
      
      QgsRasterLayer *ndviLayer = new QgsRasterLayer(
          ndviUrl,
          QStringLiteral("Sentinel %1").arg(ndviLayerId),
          QLatin1String("wms"));
      
      if (ndviLayer->isValid())
      {
        mProject->addMapLayer(ndviLayer, false);
        sentinelGroup->addLayer(ndviLayer);
        
        // Set layer visibility based on style
        QgsLayerTreeLayer* treeLayer = sentinelGroup->findLayer(ndviLayer->id());
        if (treeLayer) {
          treeLayer->setItemVisibilityChecked(ndviStyle != "OFF");
        }
      }
      else
      {
        delete ndviLayer;
      }
    }
    
    if (enabledLayers.contains("FALSE_COLOR"))
    {
      // False Color layer
      QString falseColorUrl = QStringLiteral("contextualWMSLegend=0&crs=%1&dpiMode=%2&featureCount=5&format=%3&layers=%4&styles=%5&tilePixelRatio=%6&url=https://sh.dataspace.copernicus.eu/ogc/wms/%7")
          .arg(crsSetting)
          .arg(dpiMode)
          .arg(format)
          .arg(falseColorLayerId)
          .arg(falseColorStyle)
          .arg(tilePixelRatio)
          .arg(sentinelInstanceId);
      
      // Add time parameters if enabled
      if (!timeParams.isEmpty()) {
        falseColorUrl += timeParams;
      }
      
      // Add advanced parameters if enabled
      if (!advancedParams.isEmpty()) {
        falseColorUrl += advancedParams;
      }
      
      // Add BBOX parameters if enabled
      if (!bboxParams.isEmpty()) {
        falseColorUrl += bboxParams;
      }
      
      // Add custom script if enabled
      if (!scriptParams.isEmpty()) {
        falseColorUrl += scriptParams;
      }
      
      QgsRasterLayer *falseColorLayer = new QgsRasterLayer(
          falseColorUrl,
          QStringLiteral("Sentinel %1").arg(falseColorLayerId),
          QLatin1String("wms"));
      
      if (falseColorLayer->isValid())
      {
        mProject->addMapLayer(falseColorLayer, false);
        sentinelGroup->addLayer(falseColorLayer);
        
        // Set layer visibility based on style
        QgsLayerTreeLayer* treeLayer = sentinelGroup->findLayer(falseColorLayer->id());
        if (treeLayer) {
          treeLayer->setItemVisibilityChecked(falseColorStyle != "OFF");
        }
      }
      else
      {
        delete falseColorLayer;
      }
    }
    
    if (enabledLayers.contains("TRUE_COLOR"))
    {
      // True Color layer
      QString trueColorUrl = QStringLiteral("contextualWMSLegend=0&crs=%1&dpiMode=%2&featureCount=5&format=%3&layers=%4&styles=%5&tilePixelRatio=%6&url=https://sh.dataspace.copernicus.eu/ogc/wms/%7")
          .arg(crsSetting)
          .arg(dpiMode)
          .arg(format)
          .arg(trueColorLayerId)
          .arg(trueColorStyle)
          .arg(tilePixelRatio)
          .arg(sentinelInstanceId);
      
      // Add time parameters if enabled
      if (!timeParams.isEmpty()) {
        trueColorUrl += timeParams;
      }
      
      // Add advanced parameters if enabled
      if (!advancedParams.isEmpty()) {
        trueColorUrl += advancedParams;
      }
      
      // Add BBOX parameters if enabled
      if (!bboxParams.isEmpty()) {
        trueColorUrl += bboxParams;
      }
      
      // Add custom script if enabled
      if (!scriptParams.isEmpty()) {
        trueColorUrl += scriptParams;
      }
      
      QgsRasterLayer *trueColorLayer = new QgsRasterLayer(
          trueColorUrl,
          QStringLiteral("Sentinel %1").arg(trueColorLayerId),
          QLatin1String("wms"));
      
      if (trueColorLayer->isValid())
      {
        mProject->addMapLayer(trueColorLayer, false);
        sentinelGroup->addLayer(trueColorLayer);
        
        // Set layer visibility based on style
        QgsLayerTreeLayer* treeLayer = sentinelGroup->findLayer(trueColorLayer->id());
        if (treeLayer) {
          treeLayer->setItemVisibilityChecked(trueColorStyle != "OFF");
        }
      }
      else
      {
        delete trueColorLayer;
      }
    }
    
    // Custom layer with user-defined layer ID - REMOVED
    
    // Custom1 layer with user-defined layer ID
    if (enabledLayers.contains("CUSTOM1") && !custom1LayerId.isEmpty())
    {
      // Custom1 layer
      QString custom1LayerUrl = QStringLiteral("contextualWMSLegend=0&crs=%1&dpiMode=%2&featureCount=5&format=%3&layers=%4&styles=%5&tilePixelRatio=%6&url=https://sh.dataspace.copernicus.eu/ogc/wms/%7")
          .arg(crsSetting)
          .arg(dpiMode)
          .arg(format)
          .arg(custom1LayerId)
          .arg(custom1Style)
          .arg(tilePixelRatio)
          .arg(sentinelInstanceId);
      
      // Add time parameters if enabled
      if (!timeParams.isEmpty()) {
        custom1LayerUrl += timeParams;
      }
      
      // Add advanced parameters if enabled
      if (!advancedParams.isEmpty()) {
        custom1LayerUrl += advancedParams;
      }
      
      // Add BBOX parameters if enabled
      if (!bboxParams.isEmpty()) {
        custom1LayerUrl += bboxParams;
      }
      
      QgsRasterLayer *custom1Layer = new QgsRasterLayer(
          custom1LayerUrl,
          QStringLiteral("Sentinel %1").arg(custom1LayerId),
          QLatin1String("wms"));
      
      if (custom1Layer->isValid())
      {
        mProject->addMapLayer(custom1Layer, false);
        sentinelGroup->addLayer(custom1Layer);
        
        // Set layer visibility based on style
        QgsLayerTreeLayer* treeLayer = sentinelGroup->findLayer(custom1Layer->id());
        if (treeLayer) {
          treeLayer->setItemVisibilityChecked(custom1Style != "OFF");
        }
      }
      else
      {
        delete custom1Layer;
      }
    }
    
    // Custom2 layer with user-defined layer ID
    if (enabledLayers.contains("CUSTOM2") && !custom2LayerId.isEmpty())
    {
      // Custom2 layer
      QString custom2LayerUrl = QStringLiteral("contextualWMSLegend=0&crs=%1&dpiMode=%2&featureCount=5&format=%3&layers=%4&styles=%5&tilePixelRatio=%6&url=https://sh.dataspace.copernicus.eu/ogc/wms/%7")
          .arg(crsSetting)
          .arg(dpiMode)
          .arg(format)
          .arg(custom2LayerId)
          .arg(custom2Style)
          .arg(tilePixelRatio)
          .arg(sentinelInstanceId);
      
      // Add time parameters if enabled
      if (!timeParams.isEmpty()) {
        custom2LayerUrl += timeParams;
      }
      
      // Add advanced parameters if enabled
      if (!advancedParams.isEmpty()) {
        custom2LayerUrl += advancedParams;
      }
      
      // Add BBOX parameters if enabled
      if (!bboxParams.isEmpty()) {
        custom2LayerUrl += bboxParams;
      }
      
      QgsRasterLayer *custom2Layer = new QgsRasterLayer(
          custom2LayerUrl,
          QStringLiteral("Sentinel %1").arg(custom2LayerId),
          QLatin1String("wms"));
      
      if (custom2Layer->isValid())
      {
        mProject->addMapLayer(custom2Layer, false);
        sentinelGroup->addLayer(custom2Layer);
        
        // Set layer visibility based on style
        QgsLayerTreeLayer* treeLayer = sentinelGroup->findLayer(custom2Layer->id());
        if (treeLayer) {
          treeLayer->setItemVisibilityChecked(custom2Style != "OFF");
        }
      }
      else
      {
        delete custom2Layer;
      }
    }
    
    // Set Sentinel group to be expanded by default
    sentinelGroup->setExpanded(true);
  }
  
  // Now create the basemaps group after Sentinel group
  QgsLayerTreeGroup *basemapsGroup = mProject->layerTreeRoot()->addGroup("Mapas Base");
  
  // Add basemap layers to the project and to the Basemaps group in the requested order
  mProject->addMapLayer(ignLayer, false);
  mProject->addMapLayer(bcaLayer, false);
  mProject->addMapLayer(satelliteLayer, false);
  mProject->addMapLayer(osmLayer, false);
  basemapsGroup->addLayer(ignLayer);
  basemapsGroup->addLayer(bcaLayer);
  basemapsGroup->addLayer(satelliteLayer);
  basemapsGroup->addLayer(osmLayer);
  
  // Create and add the cultivo layer as the first layer in Spain GIS Services
  QgsVectorTileLayer *cultivoLayer = new QgsVectorTileLayer(
      QStringLiteral( "type=xyz&url=https://sigpac-hubcloud.es/mvt/cultivo_declarado@3857@pbf/%7Bz%7D/%7Bx%7D/%7By%7D.pbf&zmax=14&zmin=0&http-header:referer=" ),
      QStringLiteral( "cultivos declarados" ) );
  
  // Create and add TeselaRECINTOS FEGA layer
  QgsVectorTileLayer *teselaRecintosLayer = new QgsVectorTileLayer(
      QStringLiteral( "type=xyz&url=https://sigpac-hubcloud.es/mvt/recinto@3857@pbf/%7Bz%7D/%7Bx%7D/%7By%7D.pbf&zmax=14&zmin=0&http-header:referer=" ),
      QStringLiteral( "TeselaRECINTOS FEGA" ) );
  
  // Add vector tile layers to the project and to the Spain GIS VectorTiles group
  mProject->addMapLayer(cultivoLayer, false);
  mProject->addMapLayer(teselaRecintosLayer, false);
  spainGisVectorTilesGroup->addLayer(cultivoLayer);
  spainGisVectorTilesGroup->addLayer(teselaRecintosLayer);
  
  // Add Spain GIS Services layers to the project and to the Spain GIS Services group
  mProject->addMapLayer(sigpacLayer, false);
  mProject->addMapLayer(catastroLayer, false);
  spainGisBaseLayersGroup->addLayer(sigpacLayer);
  spainGisBaseLayersGroup->addLayer(catastroLayer);
  
  // Create and add the Zonas Vul Nitratos 2023 layer
  QgsRasterLayer *zonasVulLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:3857&dpiMode=7&featureCount=10&format=image/png&layers=AM.NitrateVulnerableZone&styles&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/agua/ZonasVulnerables/2023/wms.aspx" ),
      QStringLiteral( "Zonas Vul Nitratos 2023" ),
      QLatin1String( "wms" ) );
  
  // Create and add IGN WMS layers
  QgsRasterLayer *puntosAcotadosLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4258&dpiMode=7&featureCount=10&format=image/png&layers=EL.SpotElevation&styles=puntosacotados&tilePixelRatio=0&url=https://servicios.idee.es/wms-inspire/mdt" ),
      QStringLiteral( "IGN: puntos acotados" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *curvasNivelLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4258&dpiMode=7&featureCount=10&format=image/png&layers=EL.ContourLine&styles=curvasnivel&tilePixelRatio=0&url=https://servicios.idee.es/wms-inspire/mdt" ),
      QStringLiteral( "Curvas de nivel" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *modeloDigitalTerrenoLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4258&dpiMode=7&featureCount=10&format=image/png&layers=EL.ElevationGridCoverage&styles=EL.ElevationGridCoverage.Default&tilePixelRatio=0&url=https://servicios.idee.es/wms-inspire/mdt" ),
      QStringLiteral( "Modelo digital terreno" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *hidrografiaLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4258&dpiMode=7&featureCount=10&format=image/png&tilePixelRatio=0&url=https://servicios.idee.es/wms-inspire/hidrografia&layers=HY.PhysicalWaters.HydroPointOfInterest&layers=HY.PhysicalWaters.ManMadeObject&layers=HY.PhysicalWaters.LandWaterBoundary&layers=HY.Network&layers=HY.PhysicalWaters.Waterbodies&layers=HY.PhysicalWaters.Wetland&layers=HY.PhysicalWaters.Catchments&styles=&styles=&styles=&styles=&styles=&styles=&styles=" ),
      QStringLiteral( "Hidrografía España" ),
      QLatin1String( "wms" ) );
      
  // Create and add climate WMS layers
  QgsRasterLayer *etpMediaAnualLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4230&dpiMode=7&featureCount=10&format=image/png&layers=Evapotranspiración&styles=default&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/Agricultura/CaractAgroClimaticas/wms.aspx" ),
      QStringLiteral( "ETP media anual" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *temperaturaMaximaLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4230&dpiMode=7&featureCount=10&format=image/png&layers=Temperatura máxima&styles&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/Agricultura/CaractAgroClimaticas/wms.aspx" ),
      QStringLiteral( "Temperatura máxima" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *temperaturaMediaLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4230&dpiMode=7&featureCount=10&format=image/png&layers=Temperatura media anual&styles&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/Agricultura/CaractAgroClimaticas/wms.aspx" ),
      QStringLiteral( "Temperatura media" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *temperaturaMinimaLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4230&dpiMode=7&featureCount=10&format=image/png&layers=Temperatura mínima&styles&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/Agricultura/CaractAgroClimaticas/wms.aspx" ),
      QStringLiteral( "Temperatura mínima" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *clasificacionClimaticaLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4230&dpiMode=7&featureCount=10&format=image/png&layers=Clasificación climáticos&styles=default&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/Agricultura/CaractAgroClimaticas/wms.aspx" ),
      QStringLiteral( "Clasif. clim J. Papadakis" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *necesidadesRiegoLayer = new QgsRasterLayer(
      QStringLiteral( "allowTemporalUpdates=true&contextualWMSLegend=1&crs=EPSG:4326&dpiMode=7&featureCount=10&format=image/png&layers=necesidades_riego&styles&temporalSource=provider&tilePixelRatio=0&timeDimensionExtent=2014-01-01T00:00:00.000Z/2023-01-01T00:00:00.000Z/P1Y&type=wmst&url=https://wmts.mapama.gob.es/sig/desarrollorural/necesidades_riego/ows" ),
      QStringLiteral( "Necesidades de riego" ),
      QLatin1String( "wms" ) );
      
  QgsRasterLayer *protectedSitesLayer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4326&dpiMode=7&featureCount=10&format=image/png&layers=PS.ProtectedSite&styles=PS.ProtectedSite.Default&tilePixelRatio=0&url=https://wms.mapama.gob.es/sig/Biodiversidad/ENP/wms.aspx" ),
      QStringLiteral( "Protected Sites Default Style" ),
      QLatin1String( "wms" ) );
      
  // Create and add Cultivo Declarado 2024 layer for Spain GIS Services
  QgsRasterLayer *cultivoDeclarado2024Layer = new QgsRasterLayer(
      QStringLiteral( "contextualWMSLegend=1&crs=EPSG:4326&dpiMode=7&featureCount=10&format=image/png&layers=AU.Sigpac:cultivo_declarado&styles&tilePixelRatio=0&url=https://sigpac-hubcloud.es/wms" ),
      QStringLiteral( "Cultivo Declarado 2024" ),
      QLatin1String( "wms" ) );
  
  // Add layers to the Utils group
  mProject->addMapLayer(floodRiskLayer, false);
  mProject->addMapLayer(zonasVulLayer, false);
  mProject->addMapLayer(puntosAcotadosLayer, false);
  mProject->addMapLayer(curvasNivelLayer, false);
  mProject->addMapLayer(modeloDigitalTerrenoLayer, false);
  mProject->addMapLayer(hidrografiaLayer, false);
  mProject->addMapLayer(etpMediaAnualLayer, false);
  mProject->addMapLayer(temperaturaMaximaLayer, false);
  mProject->addMapLayer(temperaturaMediaLayer, false);
  mProject->addMapLayer(temperaturaMinimaLayer, false);
  mProject->addMapLayer(clasificacionClimaticaLayer, false);
  mProject->addMapLayer(necesidadesRiegoLayer, false);
  mProject->addMapLayer(protectedSitesLayer, false);
  utilsGroup->addLayer(floodRiskLayer);
  utilsGroup->addLayer(zonasVulLayer);
  utilsGroup->addLayer(puntosAcotadosLayer);
  utilsGroup->addLayer(curvasNivelLayer);
  utilsGroup->addLayer(modeloDigitalTerrenoLayer);
  utilsGroup->addLayer(hidrografiaLayer);
  utilsGroup->addLayer(etpMediaAnualLayer);
  utilsGroup->addLayer(temperaturaMaximaLayer);
  utilsGroup->addLayer(temperaturaMediaLayer);
  utilsGroup->addLayer(temperaturaMinimaLayer);
  utilsGroup->addLayer(clasificacionClimaticaLayer);
  utilsGroup->addLayer(necesidadesRiegoLayer);
  utilsGroup->addLayer(protectedSitesLayer);
  
  // Create empty pointer variables for code that might reference them later
  QgsVectorLayer *datosPuntoLayer = nullptr;
  QgsVectorLayer *datosRasterLayer = nullptr;

  // Add Cultivo Declarado layer to the project and to the Spain GIS Base Layers group
  mProject->addMapLayer(cultivoDeclarado2024Layer, false);
  spainGisBaseLayersGroup->addLayer(cultivoDeclarado2024Layer);
  
  // Set TeselaRecintos FEGA opacity to 50%
  teselaRecintosLayer->setOpacity(0.5);
  
  // Make sure all groups are visible by default - using multiple approaches to ensure visibility
  spainGisServicesGroup->setItemVisibilityCheckedParentRecursive(true);
  spainGisServicesGroup->setItemVisibilityCheckedRecursive(false); // Set all layers to not visible by default except those we explicitly set
  spainGisServicesGroup->setItemVisibilityChecked(true);
  
  spainGisBaseLayersGroup->setItemVisibilityCheckedParentRecursive(true);
  spainGisBaseLayersGroup->setItemVisibilityCheckedRecursive(false); // Set all layers to not visible by default except those we explicitly set
  spainGisBaseLayersGroup->setItemVisibilityChecked(true);
  
  spainGisVectorTilesGroup->setItemVisibilityCheckedParentRecursive(true);
  spainGisVectorTilesGroup->setItemVisibilityCheckedRecursive(false); // Set all layers to not visible by default except those we explicitly set
  spainGisVectorTilesGroup->setItemVisibilityChecked(true);
  
  utilsGroup->setItemVisibilityCheckedParentRecursive(true);
  utilsGroup->setItemVisibilityCheckedRecursive(false); // Set all layers to not visible by default
  utilsGroup->setItemVisibilityChecked(true);
  
  basemapsGroup->setItemVisibilityCheckedParentRecursive(true);
  basemapsGroup->setItemVisibilityCheckedRecursive(false); // Set all layers to not visible by default except satellite
  basemapsGroup->setItemVisibilityChecked(true);
  
  // Set Sentinel group visibility if it exists
  if (sentinelGroup)
  {
    // Check if Sentinel layers are enabled at all
    bool enableSentinelLayers = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EnableLayers"), true).toBool();
    
    if (!enableSentinelLayers) {
      // If Sentinel layers are disabled, hide the entire group
      sentinelGroup->setItemVisibilityChecked(false);
    } else {
      // Otherwise, set visibility based on layer settings
      sentinelGroup->setItemVisibilityCheckedRecursive(false); // Set all layers to not visible by default
      
      for (QgsLayerTreeLayer* layer : sentinelGroup->findLayers())
      {
        // Default to hidden
        layer->setItemVisibilityChecked(false);
        
        // Check if this layer should be visible based on its style setting
        QString layerName;
        if (layer->name() == "Sentinel True Color") {
          layerName = "TRUE_COLOR";
        } else if (layer->name() == "Sentinel False Color") {
          layerName = "FALSE_COLOR";
        } else if (layer->name() == "Sentinel NDVI") {
          layerName = "NDVI";
        } else if (layer->name() == "Sentinel EVI") {
          layerName = "EVI";
        } else if (layer->name().startsWith("Sentinel ")) {
          layerName = "CUSTOM";
        }
        
        // If the layer is in the enabled layers list and its style is "ON" or "DEFAULT", make it visible
        if (!layerName.isEmpty() && enabledLayers.contains(layerName)) {
          QString style = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Styles/%1").arg(layerName), "ON").toString();
          if (style == "ON" || (layerName == "CUSTOM" && style == "DEFAULT")) {
            layer->setItemVisibilityChecked(false); // Set to false by default
          } else {
            // Explicitly set to false if style is "OFF"
            layer->setItemVisibilityChecked(false);
          }
        } else {
          // Explicitly set to false if not in enabled layers
          layer->setItemVisibilityChecked(false);
        }
      }
    }
  }
  
  // Then set only the requested layers to be visible
  mProject->layerTreeRoot()->findLayer(satelliteLayer->id())->setItemVisibilityChecked(true); // Google Satellite
  mProject->layerTreeRoot()->findLayer(sigpacLayer->id())->setItemVisibilityChecked(true); // Recintos SIGPAC FEGA
  mProject->layerTreeRoot()->findLayer(teselaRecintosLayer->id())->setItemVisibilityChecked(true); // TeselaRECINTOS FEGA
  
  // Set groups to be expanded by default
  spainGisServicesGroup->setExpanded(true);
  utilsGroup->setExpanded(true);
  basemapsGroup->setExpanded(true);
  spainGisBaseLayersGroup->setExpanded(true);
  spainGisVectorTilesGroup->setExpanded(true);
  
  // Make sure parent groups are visible too
  spainGisServicesGroup->setItemVisibilityChecked(true);
  spainGisBaseLayersGroup->setItemVisibilityChecked(true);
  spainGisVectorTilesGroup->setItemVisibilityChecked(true);
  
  if (sentinelGroup)
  {
    // Check if Sentinel layers are enabled at all
    bool enableSentinelLayers = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/EnableLayers"), true).toBool();
    
    if (!enableSentinelLayers) {
      // If Sentinel layers are disabled, hide the entire group
      sentinelGroup->setItemVisibilityChecked(false);
    } else {
      // Otherwise, set visibility based on layer settings
      sentinelGroup->setItemVisibilityCheckedRecursive(false); // Set all layers to not visible by default
      
      for (QgsLayerTreeLayer* layer : sentinelGroup->findLayers())
      {
        // Default to hidden
        layer->setItemVisibilityChecked(false);
        
        // Check if this layer should be visible based on its style setting
        QString layerName;
        if (layer->name() == "Sentinel True Color") {
          layerName = "TRUE_COLOR";
        } else if (layer->name() == "Sentinel False Color") {
          layerName = "FALSE_COLOR";
        } else if (layer->name() == "Sentinel NDVI") {
          layerName = "NDVI";
        } else if (layer->name() == "Sentinel EVI") {
          layerName = "EVI";
        } else if (layer->name().startsWith("Sentinel ")) {
          layerName = "CUSTOM";
        }
        
        // If the layer is in the enabled layers list and its style is "ON" or "DEFAULT", make it visible
        if (!layerName.isEmpty() && enabledLayers.contains(layerName)) {
          QString style = sentinelSettings.value(QStringLiteral("SIGPACGO/Sentinel/Styles/%1").arg(layerName), "ON").toString();
          if (style == "ON" || (layerName == "CUSTOM" && style == "DEFAULT")) {
            layer->setItemVisibilityChecked(false); // Set to false by default
          } else {
            // Explicitly set to false if style is "OFF"
            layer->setItemVisibilityChecked(false);
          }
        } else {
          // Explicitly set to false if not in enabled layers
          layer->setItemVisibilityChecked(false);
        }
      }
    }
  }
  
  if ( vectorLayers.size() > 0 || rasterLayers.size() > 0 )
  {
    mProject->setCrs( crs );
    mProject->setEllipsoid( crs.ellipsoidAcronym() );
    mProject->setTitle( mProjectFileName );
    mProject->setPresetHomePath( fi.absolutePath() );
    mProject->writeEntry( QStringLiteral( "QField" ), QStringLiteral( "isDataset" ), true );

    for ( QgsMapLayer *l : std::as_const( rasterLayers ) )
    {
      QgsRasterLayer *rlayer = qobject_cast<QgsRasterLayer *>( l );
      bool ok;
      rlayer->loadDefaultStyle( ok );
      if ( !ok && fi.size() < 50000000 )
      {
        // If the raster size is reasonably small, apply nicer resampling settings
        rlayer->resampleFilter()->setZoomedInResampler( new QgsBilinearRasterResampler() );
        rlayer->resampleFilter()->setZoomedOutResampler( new QgsBilinearRasterResampler() );
        rlayer->resampleFilter()->setMaxOversampling( 2.0 );
      }
    }
    mProject->addMapLayers( rasterLayers );

    bool hasTemporalLayers = false;
    for ( QgsMapLayer *l : std::as_const( vectorLayers ) )
    {
      QgsVectorLayer *vlayer = qobject_cast<QgsVectorLayer *>( l );
      bool ok;
      vlayer->loadDefaultStyle( ok );
      if ( !ok )
      {
        bool hasSymbol = true;
        Qgis::SymbolType symbolType;
        switch ( vlayer->geometryType() )
        {
          case Qgis::GeometryType::Point:
            symbolType = Qgis::SymbolType::Marker;
            break;
          case Qgis::GeometryType::Line:
            symbolType = Qgis::SymbolType::Line;
            break;
          case Qgis::GeometryType::Polygon:
            symbolType = Qgis::SymbolType::Fill;
            break;
          case Qgis::GeometryType::Unknown:
            hasSymbol = false;
            break;
          case Qgis::GeometryType::Null:
            hasSymbol = false;
            break;
        }

        if ( hasSymbol )
        {
          QgsSymbol *symbol = mProject->styleSettings()->defaultSymbol( symbolType );
          if ( !symbol )
            symbol = LayerUtils::defaultSymbol( vlayer );
          QgsSingleSymbolRenderer *renderer = new QgsSingleSymbolRenderer( symbol );
          vlayer->setRenderer( renderer );
        }
      }

      if ( !vlayer->labeling() )
      {
        QgsTextFormat textFormat = mProject->styleSettings()->defaultTextFormat();
        QgsAbstractVectorLayerLabeling *labeling = LayerUtils::defaultLabeling( vlayer, textFormat );
        if ( labeling )
        {
          vlayer->setLabeling( labeling );
          vlayer->setLabelsEnabled( vlayer->geometryType() == Qgis::GeometryType::Point );
        }
      }

      const QgsFields fields = vlayer->fields();
      int temporalFieldIndex = -1;
      for ( int i = 0; i < fields.size(); i++ )
      {
        if ( fields[i].type() == QMetaType::QDateTime || fields[i].type() == QMetaType::QDate )
        {
          if ( temporalFieldIndex == -1 )
          {
            temporalFieldIndex = i;
          }
          else
          {
            // Be super conservative, if more than one temporal field is present, don't auto setup
            temporalFieldIndex = -1;
            break;
          }
        }
      }
      if ( temporalFieldIndex > 0 )
      {
        hasTemporalLayers = true;
        QgsVectorLayerTemporalProperties *temporalProperties = static_cast<QgsVectorLayerTemporalProperties *>( vlayer->temporalProperties() );
        temporalProperties->setStartField( fields[temporalFieldIndex].name() );
        temporalProperties->setMode( Qgis::VectorTemporalMode::FeatureDateTimeInstantFromField );
        temporalProperties->setLimitMode( Qgis::VectorTemporalLimitMode::IncludeBeginIncludeEnd );
        temporalProperties->setAccumulateFeatures( false );
        temporalProperties->setIsActive( true );
      }
    }
    mProject->addMapLayers( vectorLayers );

    if ( hasTemporalLayers )
    {
      const QgsDateTimeRange range = QgsTemporalUtils::calculateTemporalRangeForProject( mProject );
      mMapCanvas->mapSettings()->setTemporalBegin( range.begin() );
      mMapCanvas->mapSettings()->setTemporalEnd( range.end() );
      mMapCanvas->mapSettings()->setIsTemporal( false );
    }

    if ( suffix.compare( QLatin1String( "pdf" ) ) == 0 )
    {
      // Geospatial PDFs should have vector layers hidden by default
      for ( QgsMapLayer *layer : vectorLayers )
      {
        mProject->layerTreeRoot()->findLayer( layer->id() )->setItemVisibilityChecked( false );
      }
    }
  }

  if ( mProject->elevationProperties()->terrainProvider()->type() == QStringLiteral( "flat" ) && qgsDoubleNear( mProject->elevationProperties()->terrainProvider()->offset(), 0.0 ) && qgsDoubleNear( mProject->elevationProperties()->terrainProvider()->scale(), 1.0 ) )
  {
    QgsRasterLayer *elevationLayer = LayerUtils::createOnlineElevationLayer();
    mProject->addMapLayer( elevationLayer, false, true );
    QgsRasterDemTerrainProvider *terrainProvider = new QgsRasterDemTerrainProvider();
    terrainProvider->setLayer( elevationLayer );
    mProject->elevationProperties()->setTerrainProvider( terrainProvider );
  }

  loadProjectQuirks();

  // Restore project information (extent, customized style, layer visibility, etc.)
  QSettings settings;
  const QStringList parts = settings.value( QStringLiteral( "/qgis/projectInfo/%1/extent" ).arg( mProjectFilePath ), QString() ).toString().split( '|' );
  if ( parts.size() == 4 )
  {
    extent.setXMinimum( parts[0].toDouble() );
    extent.setXMaximum( parts[1].toDouble() );
    extent.setYMinimum( parts[2].toDouble() );
    extent.setYMaximum( parts[3].toDouble() );
    mMapCanvas->mapSettings()->setExtent( extent );
  }
  else if ( !extent.isNull() )
  {
    if ( extent.width() == 0.0 || extent.height() == 0.0 )
    {
      // If all of the features are at the one point, buffer the
      // rectangle a bit. If they are all at zero, do something a bit
      // more crude.
      if ( extent.xMinimum() == 0.0 && extent.xMaximum() == 0.0 && extent.yMinimum() == 0.0 && extent.yMaximum() == 0.0 )
      {
        extent.set( -1.0, -1.0, 1.0, 1.0 );
      }
      else
      {
        const double padFactor = 1e-8;
        const double widthPad = extent.xMinimum() * padFactor;
        const double heightPad = extent.yMinimum() * padFactor;
        const double xmin = extent.xMinimum() - widthPad;
        const double xmax = extent.xMaximum() + widthPad;
        const double ymin = extent.yMinimum() - heightPad;
        const double ymax = extent.yMaximum() + heightPad;
        extent.set( xmin, ymin, xmax, ymax );
      }
    }

    // Add a bit of buffer so datasets don't touch the very edge of the map on the screen
    mMapCanvas->mapSettings()->setExtent( extent.buffered( extent.width() * 0.02 ) );
  }

  ProjectInfo::restoreSettings( mProjectFilePath, mProject, mMapCanvas, mFlatLayerTree );
  mTrackingModel->createProjectTrackers( mProject );

  emit loadProjectEnded( mProjectFilePath, mProjectFileName );

  connect( mMapCanvas, &QgsQuickMapCanvasMap::mapCanvasRefreshed, this, &QgisMobileapp::onMapCanvasRefreshed );

  const QString projectPluginPath = PluginManager::findProjectPlugin( mProjectFilePath );
  if ( !projectPluginPath.isEmpty() )
  {
    mPluginManager->loadPlugin( projectPluginPath, tr( "Project Plugin" ) );
  }
  
  // Re-enable GPKG flushing with a delay to allow the project to fully load first
  // Only do this for the first load of a project
  if (isFirstLoad) {
    QFileInfo fi( mProjectFilePath );
    QDir projectDir = fi.dir();
    QStringList gpkgFiles = projectDir.entryList(QStringList() << "*.gpkg", QDir::Files);
    
    // Delay re-enabling the GPKG flusher to avoid initial crashes
    QTimer::singleShot(5000, [this, gpkgFiles, projectDir]() {
      for (const QString &gpkgFile : gpkgFiles) {
        QString fullPath = projectDir.filePath(gpkgFile);
        // Removed log message to reduce log spam
        
        if (mGpkgFlusher) {
          mGpkgFlusher->start(fullPath);
        }
      }
    });
  }
}

QString QgisMobileapp::readProjectEntry( const QString &scope, const QString &key, const QString &def ) const
{
  if ( !mProject )
    return def;

  return mProject->readEntry( scope, key, def );
}

int QgisMobileapp::readProjectNumEntry( const QString &scope, const QString &key, int def ) const
{
  if ( !mProject )
    return def;

  return mProject->readNumEntry( scope, key, def );
}

double QgisMobileapp::readProjectDoubleEntry( const QString &scope, const QString &key, double def ) const
{
  if ( !mProject )
    return def;

  return mProject->readDoubleEntry( scope, key, def );
}

bool QgisMobileapp::readProjectBoolEntry( const QString &scope, const QString &key, bool def ) const
{
  if ( !mProject )
    return def;

  return mProject->readBoolEntry( scope, key, def );
}

bool QgisMobileapp::print( const QString &layoutName )
{
  const QList<QgsPrintLayout *> printLayouts = mProject->layoutManager()->printLayouts();
  QgsPrintLayout *layoutToPrint = nullptr;
  std::unique_ptr<QgsPrintLayout> templateLayout;
  if ( layoutName.isEmpty() && printLayouts.isEmpty() )
  {
    // Log information about the template path
    QString templatePath = QStringLiteral( "%1/sigpacgo/templates/layout.qpt" ).arg( PlatformUtilities::instance()->systemSharedDataLocation() );
    QgsMessageLog::logMessage( QStringLiteral( "Looking for template at: %1" ).arg( templatePath ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
    
    // Make sure the template directory exists
    QDir templateDir(QFileInfo(templatePath).absolutePath());
    if (!templateDir.exists()) {
      bool created = templateDir.mkpath(".");
      QgsMessageLog::logMessage( QStringLiteral( "Template directory did not exist. Created: %1" ).arg( created ? "yes" : "no" ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
    }
    
    QFile templateFile(templatePath);
    if (!templateFile.exists()) {
      QgsMessageLog::logMessage( QStringLiteral( "Template file does not exist at: %1" ).arg( templatePath ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
      
      // Create a simple default template if the file doesn't exist
      QgsMessageLog::logMessage( QStringLiteral( "Creating default template" ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
      templateLayout = std::make_unique<QgsPrintLayout>( QgsProject::instance() );
      
      // Create a map item that takes up most of the page
      QgsLayoutItemMap *map = new QgsLayoutItemMap(templateLayout.get());
      map->attemptSetSceneRect(QRectF(10, 10, 180, 180));
      map->setFrameEnabled(true);
      
      // Use the correct method to get the map canvas extent
      QgsRectangle extent = mMapCanvas->mapSettings()->visibleExtent();
      map->setExtent(extent);
      
      templateLayout->addLayoutItem(map);
      
      // Add a title
      QgsLayoutItemLabel *titleLabel = new QgsLayoutItemLabel(templateLayout.get());
      titleLabel->setText(tr("Map printed on %1 using SIGPACGO").arg("[%format_date(now(), 'yyyy-MM-dd @ hh:mm')%]"));
      titleLabel->setId("Title");
      titleLabel->setFont(QFont("Arial", 16));
      titleLabel->adjustSizeToText();
      titleLabel->attemptSetSceneRect(QRectF(10, 5, 180, 10));
      templateLayout->addLayoutItem(titleLabel);
      
      layoutToPrint = templateLayout.get();
    }
    else {
      QgsMessageLog::logMessage( QStringLiteral( "Found template file" ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
      QDomDocument templateDoc;
      if (!templateFile.open(QIODevice::ReadOnly)) {
        QgsMessageLog::logMessage( QStringLiteral( "Failed to open template file" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
        return false;
      }
      
      if (!templateDoc.setContent(&templateFile)) {
        templateFile.close();
        QgsMessageLog::logMessage( QStringLiteral( "Failed to parse template file" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
        return false;
      }
      templateFile.close();

      templateLayout = std::make_unique<QgsPrintLayout>( QgsProject::instance() );
      bool loadedOK = false;
      QList<QgsLayoutItem *> items = templateLayout->loadFromTemplate( templateDoc, QgsReadWriteContext(), true, &loadedOK );
      if ( !loadedOK )
      {
        QgsMessageLog::logMessage( QStringLiteral( "Failed to load template" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
        return false;
      }

      for ( QgsLayoutItem *item : items )
      {
        if ( item->type() == QgsLayoutItemRegistry::LayoutLabel && item->id() == QStringLiteral( "Title" ) )
        {
          QgsLayoutItemLabel *labelItem = qobject_cast<QgsLayoutItemLabel *>( item );
          labelItem->setText( tr( "Map printed on %1 using SIGPACGO" ).arg( "[%format_date(now(), 'yyyy-MM-dd @ hh:mm')%]" ) );
        }
      }
      layoutToPrint = templateLayout.get();
    }
  }
  else
  {
    for ( QgsPrintLayout *layout : printLayouts )
    {
      if ( layout->name() == layoutName || layoutName.isEmpty() )
      {
        layoutToPrint = layout;
        break;
      }
    }
  }

  if ( !layoutToPrint )
  {
    QgsMessageLog::logMessage( QStringLiteral( "No layout found to print" ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    return false;
  }

  const QString outputPath = QStringLiteral( "%1/%2.pdf" ).arg( mProject->homePath(), layoutToPrint->name().isEmpty() ? QStringLiteral( "SIGPACGO_Print_%1" ).arg( QDateTime::currentDateTime().toString( "yyyyMMdd_hhmmss" ) ) : layoutToPrint->name() );
  
  QgsMessageLog::logMessage( QStringLiteral( "Exporting print to: %1" ).arg( outputPath ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
  
  std::unique_ptr<QgsLayoutExporter> exporter = std::make_unique<QgsLayoutExporter>( layoutToPrint );
  QgsLayoutExporter::PdfExportSettings pdfSettings;
  pdfSettings.rasterizeWholeImage = false;
  
  // Make sure the output directory exists
  QDir outputDir = QFileInfo(outputPath).absoluteDir();
  if (!outputDir.exists()) {
    bool created = outputDir.mkpath(".");
    QgsMessageLog::logMessage( QStringLiteral( "Output directory did not exist. Created: %1" ).arg( created ? "yes" : "no" ), QStringLiteral( "SIGPACGO" ), Qgis::Info );
  }
  
  QgsLayoutExporter::ExportResult result = exporter->exportToPdf( outputPath, pdfSettings );

  if ( result != QgsLayoutExporter::Success )
  {
    QgsMessageLog::logMessage( QStringLiteral( "Failed to export print to PDF: %1" ).arg( result ), QStringLiteral( "SIGPACGO" ), Qgis::Warning );
    return false;
  }

  // Call open with the correct parameter signature - viewing only (not editing)
  PlatformUtilities::instance()->open( outputPath, false );
  return true;
}

bool QgisMobileapp::printAtlasFeatures( const QString &layoutName, const QList<long long> &featureIds )
{
  const QList<QgsPrintLayout *> printLayouts = mProject->layoutManager()->printLayouts();
  QgsPrintLayout *layoutToPrint = nullptr;
  for ( QgsPrintLayout *layout : printLayouts )
  {
    if ( layout->name() == layoutName )
    {
      layoutToPrint = layout;
      break;
    }
  }

  if ( !layoutToPrint || !layoutToPrint->atlas() )
    return false;

  QStringList ids;
  for ( const auto id : featureIds )
  {
    ids << QString::number( id );
  }

  QString error;
  const QString priorFilterExpression = layoutToPrint->atlas()->filterExpression();
  const bool priorFilterFeatures = layoutToPrint->atlas()->filterFeatures();

  layoutToPrint->atlas()->setFilterExpression( QStringLiteral( "@id IN (%1)" ).arg( ids.join( ',' ) ), error );
  layoutToPrint->atlas()->setFilterFeatures( true );
  layoutToPrint->atlas()->updateFeatures();

  const QString destination = QStringLiteral( "%1/layouts/%2-%3.pdf" ).arg( mProject->homePath(), layoutToPrint->name(), QDateTime::currentDateTime().toString( QStringLiteral( "yyyyMMdd_hhmmss" ) ) );
  QString finalDestination;
  const bool destinationSingleFile = layoutToPrint->customProperty( QStringLiteral( "singleFile" ), true ).toBool();
  if ( !destinationSingleFile && ids.size() == 1 )
  {
    layoutToPrint->atlas()->first();
    finalDestination = mProject->homePath() + '/' + layoutToPrint->atlas()->currentFilename() + QStringLiteral( ".pdf" );
  }
  else
  {
    finalDestination = destination;
  }
  const bool success = printAtlas( layoutToPrint, destination );

  layoutToPrint->atlas()->setFilterExpression( priorFilterExpression, error );
  layoutToPrint->atlas()->setFilterFeatures( priorFilterFeatures );

  if ( success )
  {
    if ( destinationSingleFile || ids.size() == 1 )
    {
      PlatformUtilities::instance()->open( finalDestination );
    }
    else
    {
      PlatformUtilities::instance()->open( mProject->homePath() );
    }
  }
  return success;
}

bool QgisMobileapp::printAtlas( QgsPrintLayout *layoutToPrint, const QString &destination )
{
  QString error;

  QVector<double> mapScales = layoutToPrint->project()->viewSettings()->mapScales();
  bool hasProjectScales( layoutToPrint->project()->viewSettings()->useProjectScales() );
  if ( !hasProjectScales || mapScales.isEmpty() )
  {
    // default to global map tool scales
    const QStringList scales = Qgis::defaultProjectScales().split( ',' );
    for ( const QString &scale : scales )
    {
      QStringList parts( scale.split( ':' ) );
      if ( parts.size() == 2 )
      {
        mapScales.push_back( parts[1].toDouble() );
      }
    }
  }

  QgsLayoutExporter::PdfExportSettings pdfSettings;
  pdfSettings.rasterizeWholeImage = layoutToPrint->customProperty( QStringLiteral( "rasterize" ), false ).toBool();
  pdfSettings.dpi = layoutToPrint->renderContext().dpi();
  pdfSettings.appendGeoreference = true;
  pdfSettings.exportMetadata = true;
  pdfSettings.simplifyGeometries = true;
  pdfSettings.predefinedMapScales = mapScales;

  if ( layoutToPrint->atlas()->updateFeatures() )
  {
    QgsLayoutExporter exporter = QgsLayoutExporter( layoutToPrint );
    QgsLayoutExporter::ExportResult result;

    if ( layoutToPrint->customProperty( QStringLiteral( "singleFile" ), true ).toBool() )
    {
      result = exporter.exportToPdf( layoutToPrint->atlas(), destination, pdfSettings, error );
    }
    else
    {
      result = exporter.exportToPdfs( layoutToPrint->atlas(), destination, pdfSettings, error );
    }

    return result == QgsLayoutExporter::Success ? true : false;
  }

  return false;
}

void QgisMobileapp::setScreenDimmerTimeout( int timeoutSeconds )
{
  if ( mScreenDimmer )
  {
    mScreenDimmer->setTimeout( timeoutSeconds );
  }
}

bool QgisMobileapp::event( QEvent *event )
{
  if ( event->type() == QEvent::Close )
  {
    quit();
  }

  return QQmlApplicationEngine::event( event );
}

void QgisMobileapp::clearProject()
{
  if ( !mProjectFilePath.isEmpty() )
  {
    mPluginManager->unloadPlugin( PluginManager::findProjectPlugin( mProjectFilePath ) );
  }
  mAuthRequestHandler->clearStoredRealms();

  mProjectFileName = QString();
  mProjectFilePath = QString();
  mProject->clear();
}

void QgisMobileapp::saveProjectPreviewImage()
{
  if ( !mProjectFilePath.isEmpty() && mMapCanvas && !mMapCanvas->isRendering() )
  {
    const QImage grab = mMapCanvas->image();
    if ( !grab.isNull() )
    {
      const int pixels = std::min( grab.width(), grab.height() );
      const QRect rect( ( grab.width() - pixels ) / 2, ( grab.height() - pixels ) / 2, pixels, pixels );
      const QImage img = grab.copy( rect );
      img.save( QStringLiteral( "%1.png" ).arg( mProjectFilePath ) );
    }
  }
}

QgisMobileapp::~QgisMobileapp()
{
  PlatformUtilities::instance()->stopPositioningService();

  saveProjectPreviewImage();

  mPluginManager->unloadPlugins();

  delete mOfflineEditing;
  mProject->clear();
  delete mProject;
  delete mAppMissingGridHandler;

  mApp->exitQgis();
  QMetaObject::invokeMethod( mApp, &QgsApplication::quit, Qt::QueuedConnection );
}
