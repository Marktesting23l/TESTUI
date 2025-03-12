/***************************************************************************
  featureutils.h - FeatureUtils

 ---------------------
 begin                : 05.03.2020
 copyright            : (C) 2020 by Denis Rouzaud
 email                : denis@opengis.ch
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
#ifndef FEATUREUTILS_H
#define FEATUREUTILS_H

#include "qfield_core_export.h"

#include <QObject>
#include <qgsfeature.h>
#include <qgsgeometry.h>

class QgsVectorLayer;
class QgsQuickMapSettings;

/**
 * \ingroup core
 */
class QFIELD_CORE_EXPORT FeatureUtils : public QObject
{
    Q_OBJECT
  public:
    explicit FeatureUtils( QObject *parent = nullptr );

    /**
     * Returns a new feature with its \a fields completely blank.
     */
    static Q_INVOKABLE QgsFeature createBlankFeature( const QgsFields &fields = QgsFields(), const QgsGeometry &geometry = QgsGeometry() );

    /**
     * Returns a new feature with its fields set to default values.
     */
    static Q_INVOKABLE QgsFeature createFeature( QgsVectorLayer *layer, const QgsGeometry &geometry = QgsGeometry() );

    /**
    * Returns the display name of a given feature.
    * \param layer the vector layer containing the feature
    * \param feature the feature to be named
    */
    static Q_INVOKABLE QString displayName( QgsVectorLayer *layer, const QgsFeature &feature );

    /**
     * Returns the map extent encompassig a given feature.
     * \param mapSettings the map settings used to determine the CRS
     * \param layer the vector layer containing the feature
     * \param feature the feature from which the geometry will be used
     * \returns a QgsRectangle extent
     */
    static Q_INVOKABLE QgsRectangle extent( QgsQuickMapSettings *mapSettings, QgsVectorLayer *layer, const QgsFeature &feature );

    /**
     * Returns a list of features while attempting to parse a GeoJSON \a string. If the string could not
     * be parsed, an enmpty list will be returned.
     */
    static Q_INVOKABLE QList<QgsFeature> featuresFromJsonString( const QString &string );
    
    /**
     * Returns a list of unique values for a given field in a vector layer.
     * \param layer the vector layer
     * \param fieldName the name of the field
     * \returns a list of unique values
     */
    static Q_INVOKABLE QVariantList getUniqueValues( QgsVectorLayer *layer, const QString &fieldName );
    
    /**
     * Returns a list of unique values for a given field in a vector layer, filtered by an expression.
     * \param layer the vector layer
     * \param fieldName the name of the field
     * \param filterExpression the filter expression
     * \returns a list of unique values
     */
    static Q_INVOKABLE QVariantList getUniqueValuesFiltered( QgsVectorLayer *layer, const QString &fieldName, const QString &filterExpression );
    
    /**
     * Returns a list of features filtered by an expression.
     * \param layer the vector layer
     * \param filterExpression the filter expression
     * \returns a list of features
     */
    static Q_INVOKABLE QList<QgsFeature> getFilteredFeatures( QgsVectorLayer *layer, const QString &filterExpression );
    
    /**
     * Returns a feature by its ID.
     * \param layer the vector layer
     * \param featureId the feature ID
     * \returns the feature
     */
    static Q_INVOKABLE QgsFeature getFeatureById( QgsVectorLayer *layer, int featureId );
    
    /**
     * Returns the map extent encompassing a list of features.
     * \param mapSettings the map settings used to determine the CRS
     * \param layer the vector layer containing the features
     * \param features the list of features
     * \returns a QgsRectangle extent
     */
    static Q_INVOKABLE QgsRectangle extentOfFeatures( QgsQuickMapSettings *mapSettings, QgsVectorLayer *layer, const QList<QgsFeature> &features );
};

#endif // FEATUREUTILS_H
