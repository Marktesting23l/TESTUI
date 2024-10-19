/***************************************************************************
 trackingmodel.h - TrackingModel

 ---------------------
 begin                : 20.02.2020
 copyright            : (C) 2020 by David Signer
 email                : david (at) opengis.ch
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
#ifndef TRACKINGMODEL_H
#define TRACKINGMODEL_H

#include "tracker.h"

#include <QAbstractItemModel>

class RubberbandModel;
class Track;

/**
 * \ingroup core
 */
class TrackingModel : public QAbstractItemModel
{
    Q_OBJECT

  public:
    explicit TrackingModel( QObject *parent = nullptr );
    ~TrackingModel() override;

    enum TrackingRoles
    {
      DisplayString = Qt::UserRole,
      VectorLayer,            //! layer in the current tracking session
      RubberModel,            //! rubberbandmodel used in the current tracking session
      TimeInterval,           //! minimum time interval constraint between each tracked point
      MinimumDistance,        //! minimum distance constraint between each tracked point
      Conjunction,            //! if TRUE, all constraints needs to be fulfilled before tracking a point
      Visible,                //! if TRUE, the tracking session rubberband is visible
      Feature,                //! feature in the current tracking session
      StartPositionTimestamp, //! timestamp when the current tracking session started
      MeasureType,            //! measurement type used to set the measure value
      SensorCapture,          //! if TRUE, newly captured sensor data constraint will be required between each tracked point
      MaximumDistance,        //! maximum distance tolerated beyond which a position will be considered errenous
      IsActive,               //! if TRUE, the tracker has been started
    };

    QHash<int, QByteArray> roleNames() const override;
    QModelIndex index( int row, int column, const QModelIndex &parent = QModelIndex() ) const override;
    QModelIndex parent( const QModelIndex &index ) const override;
    int rowCount( const QModelIndex &parent = QModelIndex() ) const override;
    int columnCount( const QModelIndex &parent = QModelIndex() ) const override;
    QVariant data( const QModelIndex &index, int role = Qt::DisplayRole ) const override;
    virtual bool setData( const QModelIndex &index, const QVariant &value, int role ) override;

    //! Creates tracking sessions defined in a project being opened
    Q_INVOKABLE void createProjectTrackers( QgsProject *project );
    //! Creates a tracking session for the provided vector \a layer.
    Q_INVOKABLE QModelIndex createTracker( QgsVectorLayer *layer );
    //! Starts tracking for the provided vector \a layer provided it has a tracking session created.
    Q_INVOKABLE void startTracker( QgsVectorLayer *layer );
    //! Stops the tracking session of the provided vector \a layer.
    Q_INVOKABLE void stopTracker( QgsVectorLayer *layer );
    //! Sets whether the tracking session rubber band is \a visible.
    Q_INVOKABLE void setTrackerVisibility( QgsVectorLayer *layer, bool visible );
    //! Returns TRUE if the \a featureId is attached to a vector \a layer tracking session.
    Q_INVOKABLE bool featureInTracking( QgsVectorLayer *layer, QgsFeatureId featureId );
    //! Returns TRUE if the list of \a features is attached to a vector \a layer tracking session.
    Q_INVOKABLE bool featuresInTracking( QgsVectorLayer *layer, const QList<QgsFeature> &features );
    //! Returns TRUE if the vector \a layer has a tracking session.
    Q_INVOKABLE bool layerInTracking( QgsVectorLayer *layer );
    //! Returns the tracker for the vector \a layer if a tracking session is present, otherwise returns NULLPTR.
    Tracker *trackerForLayer( QgsVectorLayer *layer );

    void reset();

    /**
     * Forwards a tracking setup request to the user interface consisting of a settings panel followed by
     * a feature form (unless suppressed by the project configuration).
     * \a layer the vector layer associated with the tracking
     * \a skipSettings set to TRUE if the settings panel should be omitted and only show the feature form
     */
    Q_INVOKABLE void requestTrackingSetup( QgsVectorLayer *layer, bool skipSettings = false );

  signals:

    void layerInTrackingChanged( QgsVectorLayer *layer, bool tracking );

    void trackingSetupRequested( QModelIndex trackerIndex, bool skipSettings );

  private:
    QList<Tracker *> mTrackers;
    QList<Tracker *>::const_iterator trackerIterator( QgsVectorLayer *layer )
    {
      return std::find_if( mTrackers.constBegin(), mTrackers.constEnd(), [layer]( const Tracker *tracker ) { return tracker->layer() == layer; } );
    }
};


#endif // TRACKINGMODEL_H
