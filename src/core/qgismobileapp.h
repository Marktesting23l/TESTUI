/***************************************************************************
                            qgismobileapp.h
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

#ifndef QGISMOBILEAPP_H
#define QGISMOBILEAPP_H

// Qt includes
#include <QtQml/QQmlApplicationEngine>

// QGIS includes
#include <qgsapplication.h>
#include <qgsconfig.h>
#include <qgsexiftools.h>
#include <qgsmaplayerproxymodel.h>
#include <qgsunittypes.h>

// QField includes
#include "appcoordinateoperationhandlers.h"
#include "bookmarkmodel.h"
#include "clipboardmanager.h"
#include "drawingtemplatemodel.h"
#include "pluginmanager.h"
#include "qfield_core_export.h"
#include "qfieldappauthrequesthandler.h"
#include "qgsgpkgflusher.h"
#include "screendimmer.h"
#include "settings.h"

class AppInterface;
class AppMissingGridHandler;
class QgsOfflineEditing;
class QgsQuickMapCanvasMap;
class LayerTreeMapCanvasBridge;
class FlatLayerTreeModel;
class LayerTreeModel;
class LegendImageProvider;
class LocalFilesImageProvider;
class ProjectsImageProvider;
class TrackingModel;
class LocatorFiltersModel;
class QgsProject;
class LayerObserver;
class FeatureHistory;
class MessageLogModel;
class QgsPrintLayout;

#define REGISTER_SINGLETON( uri, _class, name ) qmlRegisterSingletonType<_class>( uri, 1, 0, name, []( QQmlEngine *engine, QJSEngine *scriptEngine ) -> QObject * { Q_UNUSED(engine); Q_UNUSED(scriptEngine); return new _class(); } )

/**
 * \defgroup core
 * \brief QField C++ classes
 */

/**
 * \ingroup core
 */
class QFIELD_CORE_EXPORT QgisMobileapp : public QQmlApplicationEngine
{
    Q_OBJECT
  public:
    friend class FeatureModel; // Allow FeatureModel to access mGpkgFlusher directly for flushes
    
    //! Constructor
    explicit QgisMobileapp( QgsApplication *app, QObject *parent = nullptr );
    //! Destructor
    ~QgisMobileapp() override;

    /**
     * Returns the singleton instance of QgisMobileapp.
     * This is useful for other classes that need to access the app instance.
     */
    static QgisMobileapp* instance() { return sInstance; }

    /**
     * Returns a list of recent projects.
     */
    QList<QPair<QString, QString>> recentProjects();

    /**
     * Saves a list of recent \a projects.
     */
    void saveRecentProjects( QList<QPair<QString, QString>> &projects );

    /**
     * Removes the project with a given \a path from the list of recent projects
     */
    void removeRecentProject( const QString &path );

    /**
     * Set the project or dataset file path to be loaded.
     *
     * \param path The project or dataset file to load
     * \param name The project name
     * \note The actual loading is done in readProjectFile
     */
    bool loadProjectFile( const QString &path, const QString &name = QString() );

    /**
     * Reloads the current project
     *
     * \note It does not reset the Auth Request Handler.
     * \note The actual loading is done in readProjectFile
     */
    void reloadProjectFile();

    /**
     * Saves the current layer visibility states to be restored after project reload
     */
    void saveLayerVisibilityState();

    /**
     * This will restore the layer visibility state from the saved map
     */
    void restoreLayerVisibilityState();

    /**
     * Reads and opens the project file set in the loadProjectFile function
     */
    void readProjectFile();

    /**
     * Reads a string from the specified \a scope and \a key from the currently opened project
     *
     * \param scope entry scope (group) name
     * \param key entry key name. Keys are '/'-delimited entries, implying a hierarchy of keys and corresponding values
     * \param def default value to return if the specified \a key does not exist within the \a scope
     *
     * \returns entry value as string from \a scope given its \a key
     */
    QString readProjectEntry( const QString &scope, const QString &key, const QString &def = QString() ) const;

    /**
     * Reads an integer from the specified \a scope and \a key from the currently opened project
     *
     * \param scope entry scope (group) name
     * \param key entry key name. Keys are '/'-delimited entries, implying a hierarchy of keys and corresponding values
     * \param def default value to return if the specified \a key does not exist within the \a scope
     *
     * \returns entry value as integer from \a scope given its \a key
     */
    int readProjectNumEntry( const QString &scope, const QString &key, int def = 0 ) const;

    /**
     * Reads a double from the specified \a scope and \a key from the currently opened project
     *
     * \param scope entry scope (group) name
     * \param key entry key name. Keys are '/'-delimited entries, implying a hierarchy of keys and corresponding values
     * \param def default value to return if the specified \a key does not exist within the \a scope
     *
     * \returns entry value as double from \a scope given its \a key
     */
    double readProjectDoubleEntry( const QString &scope, const QString &key, double def = 0.0 ) const;

    /**
     * Reads a boolean from the specified \a scope and \a key from the currently opened project
     *
     * \param scope entry scope (group) name
     * \param key entry key name. Keys are '/'-delimited entries, implying a hierarchy of keys and corresponding values
     * \param def default value to return if the specified \a key does not exist within the \a scope
     *
     * \returns entry value as boolean from \a scope given its \a key
     */
    bool readProjectBoolEntry( const QString &scope, const QString &key, bool def = false ) const;

    /**
     * Prints a given layout from the currently opened project to a PDF file
     * \param layoutName the layout name that will be printed
     * \return TRUE if the layout was successfully printed
     */
    bool print( const QString &layoutName );

    /**
     * Prints a given atlas-driven layout from the currently opened project to one or more PDF files
     * \param layoutName the layout name that will be printed
     * \param featureIds the features from the atlas coverage vector layer that will be used to print the layout
     * \return TRUE if the layout was successfully printed
     */
    bool printAtlasFeatures( const QString &layoutName, const QList<long long> &featureIds );

    /**
     * Sets the screen dimmer timeout in seconds
     * \note setting the timeout value to 0 will disable the screen dimmer
     */
    void setScreenDimmerTimeout( int timeoutSeconds );

    /**
     * Creates a custom Sentinel layer with the provided URL, name, and instance ID
     */
    void createCustomSentinelLayer(const QString &url, const QString &name, const QString &instanceId);

    bool event( QEvent *event ) override;

    /**
     * Clear the currently opened project back to a blank project
     */
    Q_INVOKABLE void clearProject();

    static void initDeclarative( QQmlEngine *engine );

    void loadTestingData(); // Only for desktop builds - will be removed

    void setMapExtentFromSettings();

    /**
     * Helper to ensure GPKG flusher is enabled for a file.
     * This is needed to ensure changes to GPKG files are properly saved.
     */
    void ensureGpkgFlusherEnabled( const QString &filePath );

    /**
     * Ensures all GPKG flushers in the project are enabled
     * Called after project is fully loaded to make sure all 
     * GPKG files can be properly edited and saved
     */
    void ensureAllGpkgFlushersEnabled();

    /**
     * Helper to get all GPKG files from a QgsVectorLayer
     * \param layer The vector layer to check
     * \return List of GPKG file paths used by the layer
     */
    QStringList getGpkgFilesFromLayer(QgsVectorLayer* layer);

    /**
     * Flushes all GPKG files and saves the project
     * This ensures that all changes are properly written to disk
     * before saving the project file.
     */
    void flushAllGpkgFilesAndSaveProject();

  signals:
    /**
     * Emitted when a project file is being loaded
     *
     * @param filename The filename of the project that is being loaded
     * @param name The project name that is being loaded
     */
    void loadProjectTriggered( const QString &filename, const QString &name );

    /**
     * Emitted when the project is fully loaded
     */
    void loadProjectEnded( const QString &filename, const QString &name );

    /**
     * Emitted when a map canvas extent change is needed
     */
    void setMapExtent( const QgsRectangle &extent );

    /**
     * Emitted when a message needs to be displayed to the user
     */
    void messageEmitted( const QString &message, const QString &type = QString() );

  private slots:

    void onAfterFirstRendering();
    void onMapCanvasRefreshed();

  private:
    void registerGlobalVariables();
    void loadProjectQuirks();
    void saveProjectPreviewImage();
    bool printAtlas( QgsPrintLayout *layoutToPrint, const QString &destination );

    void initDeclarative();
    void addVirtualLayers();
    void loadProjectFile();
    void loadLastProject();
    
    QgsOfflineEditing *mOfflineEditing = nullptr;
    LayerTreeMapCanvasBridge *mLayerTreeCanvasBridge = nullptr;
    FlatLayerTreeModel *mFlatLayerTree = nullptr;
    QgsMapLayerProxyModel *mLayerList = nullptr;
    AppInterface *mIface = nullptr;
    Settings mSettings;
    QPointer<QgsQuickMapCanvasMap> mMapCanvas;
    bool mFirstRenderingFlag;
    bool mProjectLoaded = false;
    LegendImageProvider *mLegendImageProvider = nullptr;
    LocalFilesImageProvider *mLocalFilesImageProvider = nullptr;
    ProjectsImageProvider *mProjectsImageProvider = nullptr;

    QgsProject *mProject = nullptr;
    QString mProjectFilePath;
    QString mProjectFileName;

    std::unique_ptr<QgsGpkgFlusher> mGpkgFlusher;
    std::unique_ptr<LayerObserver> mLayerObserver;
    std::unique_ptr<FeatureHistory> mFeatureHistory;
    std::unique_ptr<ClipboardManager> mClipboardManager;

    QFieldAppAuthRequestHandler *mAuthRequestHandler = nullptr;

    BookmarkModel *mBookmarkModel = nullptr;
    DrawingTemplateModel *mDrawingTemplateModel = nullptr;
    MessageLogModel *mMessageLogModel = nullptr;

    PluginManager *mPluginManager = nullptr;

    // Dummy objects. We are not able to call static functions from QML, so we need something here.
    QgsCoordinateReferenceSystem mCrsFactory;
    QgsUnitTypes mUnitTypes;
    QgsExifTools mExifTools;

    TrackingModel *mTrackingModel = nullptr;

    AppMissingGridHandler *mAppMissingGridHandler = nullptr;

    std::unique_ptr<ScreenDimmer> mScreenDimmer;
    QgsApplication *mApp;

    // Map to store layer visibility states
    QMap<QString, bool> mSavedLayerVisibility;

    QPointF mStartPointMapCoordinates;
    QPointF mPreviousMovePointMapCoordinates;
    QPoint mStartPointScreenCoordinates;
    QgsVectorLayer *mMovingLayer = nullptr;
    const QgsFeature *mMovingFeature = nullptr;
    QgsFeatureId mMovingFeatureId;
    
    bool mSkipHardcodedLayers = false;

    // Comment out these problematic lines that are causing compilation errors
    // std::unique_ptr<QgsVertexMarker> mCenter = nullptr;
    // std::unique_ptr<QgsGpsConnection> mGpsConnection = nullptr;
    // QgsQuickCoordinateTransformerGpsDataProvider mGpsProvider;

    static QgisMobileapp* sInstance;
};

/**
 * This class handles rate limiting for WMS requests to prevent excessive credit usage
 * with services like Sentinel Hub.
 */
class WmsRateLimiter : public QObject
{
    Q_OBJECT

  public:
    explicit WmsRateLimiter(QObject *parent = nullptr);
    
    /**
     * Sets the delay between requests in milliseconds
     */
    void setDelay(int delayMs);
    
    /**
     * Returns whether rate limiting is enabled
     */
    bool isEnabled() const;
    
    /**
     * Enables or disables rate limiting
     */
    void setEnabled(bool enabled);
    
    /**
     * Static instance accessor
     */
    static WmsRateLimiter *instance();
    
  private:
    static WmsRateLimiter *sInstance;
    bool mEnabled;
    int mDelayMs;
};

Q_DECLARE_METATYPE( QgsFeatureId )
Q_DECLARE_METATYPE( QgsAttributes )
Q_DECLARE_METATYPE( QgsFieldConstraints )

#endif // QGISMOBILEAPP_H
