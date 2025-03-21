/***************************************************************************
                            appinterface.h
                              -------------------
              begin                : 10.12.2014
              copyright            : (C) 2014 by Matthias Kuhn
              email                : matthias.kuhn (at) opengis.ch
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef APPINTERFACE_H
#define APPINTERFACE_H

#include <QObject>
#include <QPointF>
#include <QQmlComponent>
#include <QStandardItemModel>

class QgisMobileapp;
class QgsRectangle;
class QgsFeature;
class QQuickItem;

/**
 * \ingroup core
 */
class AppInterface : public QObject
{
    Q_OBJECT

  public:
    explicit AppInterface( QgisMobileapp *app );
    AppInterface()
    {
      // You shouldn't get here, this constructor only exists that we can register it as a QML type
      Q_ASSERT( false );
    }

    Q_INVOKABLE void importUrl( const QString &url );

    Q_INVOKABLE bool hasProjectOnLaunch() const;
    Q_INVOKABLE bool loadFile( const QString &path, const QString &name = QString() );
    Q_INVOKABLE void reloadProject();
    Q_INVOKABLE void readProject();
    Q_INVOKABLE void removeRecentProject( const QString &path );

    Q_INVOKABLE QString readProjectEntry( const QString &scope, const QString &key, const QString &def = QString() ) const;
    Q_INVOKABLE int readProjectNumEntry( const QString &scope, const QString &key, int def = 0 ) const;
    Q_INVOKABLE double readProjectDoubleEntry( const QString &scope, const QString &key, double def = 0.0 ) const;
    Q_INVOKABLE bool readProjectBoolEntry( const QString &scope, const QString &key, bool def = false ) const;

    Q_INVOKABLE bool print( const QString &layoutName );
    Q_INVOKABLE bool printAtlasFeatures( const QString &layoutName, const QList<long long> &featureIds );

    Q_INVOKABLE void setScreenDimmerTimeout( int timeoutSeconds );

    /**
     * \param parameters A map of parameter name/value pairs
     */
    Q_INVOKABLE void setCustomWmsParameters( const QVariantMap &parameters );

    Q_INVOKABLE QVariantMap availableLanguages() const;

    Q_INVOKABLE bool isFileExtensionSupported( const QString &filename ) const;

    /**
     * Adds a log \a message that will be visible to the user through the
     * message log panel, as well as added into the device's system logs
     * which will be captured by the sentry's reporting framework when enabled.
     */
    Q_INVOKABLE void logMessage( const QString &message );

    /**
     * Outputs the current runtime profiler model content into the message log
     * panel, as well as added into the device's system logs
     * which will be captured by the sentry's reporting framework when enabled.
     */
    Q_INVOKABLE void logRuntimeProfiler();

    /**
     * Sends a logs reporting through to sentry when enabled.
     */
    Q_INVOKABLE void sendLog( const QString &message, const QString &cloudUser );

    /**
     * Initalizes sentry connection.
     */
    Q_INVOKABLE void initiateSentry() const;

    /**
     * Closes active sentry connection.
     */
    Q_INVOKABLE void closeSentry() const;

    /**
     * Clears the currently opened project
     */
    Q_INVOKABLE void clearProject() const;

    /**
     * Returns the item matching the provided object \a name
     */
    Q_INVOKABLE QObject *findItemByObjectName( const QString &name ) const;

    /**
     * Adds an \a item in the plugins toolbar container
     */
    Q_INVOKABLE void addItemToPluginsToolbar( QQuickItem *item ) const;

    /**
     * Adds an \a item in the map canvas menu's action toolbar container
     */
    Q_INVOKABLE void addItemToCanvasActionsToolbar( QQuickItem *item ) const;

    /**
     * Adds an \a item in the dashboard's action toolbar container
     */
    Q_INVOKABLE void addItemToDashboardActionsToolbar( QQuickItem *item ) const;

    /**
     * Adds an \a item in the dashboard's action toolbar container
     * \note This function is deprecated and will be removed in the future, use
     * the addItemToDashboardActionsToolbar function instead
     */
    Q_INVOKABLE void addItemToMainMenuActionsToolbar( QQuickItem *item ) const;

    /**
     * Returns a list of layers in a GeoPackage file
     * @param gpkgPath The path to the GeoPackage file
     * @return A list of layer objects with name and type properties
     */
    Q_INVOKABLE QVariantList getLayersInGeoPackage( const QString &gpkgPath ) const;
    
    /**
     * Adds a layer from a GeoPackage file to the current project
     * @param gpkgPath The path to the GeoPackage file
     * @param layerName The name of the layer to add
     * @param layerType The type of the layer (vector or raster)
     * @return True if the layer was successfully added, false otherwise
     */
    Q_INVOKABLE bool addLayerFromGeoPackage( const QString &gpkgPath, const QString &layerName, const QString &layerType ) const;
    
    /**
     * Removes a layer from the current project
     * @param layerId The ID of the layer to remove
     * @return True if the layer was successfully removed, false otherwise
     */
    Q_INVOKABLE bool removeLayerFromProject( const QString &layerId ) const;
    
    /**
     * Returns a list of all layers in the current project
     * @return A list of layer objects with id, name, and type properties
     */
    Q_INVOKABLE QVariantList getProjectLayers() const;

    /**
     * Returns a list of all layer groups in the current project
     * @return A list of group objects with id and name properties
     */
    Q_INVOKABLE QVariantList getLayerGroups() const;
    
    /**
     * Adds a layer from a GeoPackage file to a specific group in the current project
     * @param gpkgPath The path to the GeoPackage file
     * @param layerName The name of the layer to add
     * @param layerType The type of the layer (vector or raster)
     * @param groupName The name of the group to add the layer to (empty for root group)
     * @return True if the layer was successfully added, false otherwise
     */
    Q_INVOKABLE bool addLayerToGroup( const QString &gpkgPath, const QString &layerName, const QString &layerType, const QString &groupName ) const;

    /**
     * Removes a layer group from the current project
     * @param groupName The name of the group to remove
     * @return True if the group was successfully removed, false otherwise
     */
    Q_INVOKABLE bool removeLayerGroup( const QString &groupName ) const;

    /**
     * Creates a backup of a folder and all its contents
     * @param sourceFolderPath The path to the folder to backup
     * @param destinationFolderPath The path where the backup will be saved (if empty, uses default location)
     * @return The path to the created backup file, or empty string if backup failed
     */
    Q_INVOKABLE QString createFolderBackup( const QString &sourceFolderPath, const QString &destinationFolderPath = QString() ) const;

    /**
     * Returns the main window.
     */
    Q_INVOKABLE QObject *mainWindow() const;

    /**
     * Returns the main map canvas.
     */
    Q_INVOKABLE QObject *mapCanvas() const;

    static void setInstance( AppInterface *instance ) { sAppInterface = instance; }
    static AppInterface *instance() { return sAppInterface; }

  public slots:
    void openFeatureForm();

  signals:
    void openFeatureFormRequested();

    /**
     * Emitted when a dataset or project import has been triggered.
     * \param name a indentifier-friendly string (e.g. a file being imported)
     */
    void importTriggered( const QString &name );

    /**
     * Emitted when an ongoing import reports its \a progress.
     * \note when an import is started, its progress will be indefinite by default
     */
    void importProgress( double progress );

    /**
     * Emitted when an import has ended.
     * \param path the path within which the imported dataset or project has been copied into
     * \note if the import was not successful, the path value will be an empty string
     */
    void importEnded( const QString &path = QString() );

    /**
     * Emitted when a project has begin loading.
     */
    void loadProjectTriggered( const QString &path, const QString &name );

    /**
     * Emitted when a project loading has ended.
     */
    void loadProjectEnded( const QString &path, const QString &name );

    //! Requests QField to set its map to the provided \a extent.
    void setMapExtent( const QgsRectangle &extent );

    //! Requests QField to open its local data picker screen to show the \a path content.
    void openPath( const QString &path );

    //! Emitted when a volume key is pressed while QField is set to handle those keys.
    void volumeKeyDown( int volumeKeyCode );

    //! Emitted when a volume key is pressed while QField is set to handle those keys.
    void volumeKeyUp( int volumeKeyCode );

  private:
    static AppInterface *sAppInterface;

    QgisMobileapp *mApp = nullptr;
};

#endif // APPINTERFACE_H
