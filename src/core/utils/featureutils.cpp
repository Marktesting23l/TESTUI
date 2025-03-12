/***************************************************************************
  featureutils.cpp - FeatureUtils

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

#include "featureutils.h"
#include "qgsquickmapsettings.h"

#include <qgsexpressioncontextutils.h>
#include <qgsjsonutils.h>
#include <qgsproject.h>
#include <qgsvectorlayer.h>
#include <qgsvectorlayerutils.h>
#include <qgsfeaturerequest.h>

FeatureUtils::FeatureUtils( QObject *parent )
  : QObject( parent )
{
}

QgsFeature FeatureUtils::createBlankFeature( const QgsFields &fields, const QgsGeometry &geometry )
{
  QgsFeature feature( fields );
  feature.setGeometry( geometry );
  return feature;
}

QgsFeature FeatureUtils::createFeature( QgsVectorLayer *layer, const QgsGeometry &geometry )
{
  QgsFeature feature;
  QgsAttributeMap attributes;
  QgsExpressionContext context = layer->createExpressionContext();
  feature = QgsVectorLayerUtils::createFeature( layer, geometry, attributes, &context );
  return feature;
}

QString FeatureUtils::displayName( QgsVectorLayer *layer, const QgsFeature &feature )
{
  if ( !layer )
    return QString();

  QgsExpressionContext context = QgsExpressionContext()
                                 << QgsExpressionContextUtils::globalScope()
                                 << QgsExpressionContextUtils::projectScope( QgsProject::instance() )
                                 << QgsExpressionContextUtils::layerScope( layer );
  context.setFeature( feature );

  QString name = QgsExpression( layer->displayExpression() ).evaluate( &context ).toString();
  if ( name.isEmpty() )
    name = QString::number( feature.id() );

  return name;
}

QgsRectangle FeatureUtils::extent( QgsQuickMapSettings *mapSettings, QgsVectorLayer *layer, const QgsFeature &feature )
{
  if ( mapSettings && layer && layer->geometryType() != Qgis::GeometryType::Unknown && layer->geometryType() != Qgis::GeometryType::Null )
  {
    QgsCoordinateTransform transf( layer->crs(), mapSettings->destinationCrs(), mapSettings->mapSettings().transformContext() );
    QgsGeometry geom( feature.geometry() );
    if ( !geom.isNull() )
    {
      geom.transform( transf );

      QgsRectangle extent;
      if ( geom.type() == Qgis::GeometryType::Point )
      {
        extent = mapSettings->extent();
        QgsVector delta = QgsPointXY( geom.asPoint() ) - extent.center();
        const double deltaX = delta.x();
        const double deltaY = delta.y();
        extent.setXMinimum( extent.xMinimum() + deltaX );
        extent.setXMaximum( extent.xMaximum() + deltaX );
        extent.setYMinimum( extent.yMinimum() + deltaY );
        extent.setYMaximum( extent.yMaximum() + deltaY );
      }
      else
      {
        extent = geom.boundingBox();
        extent = extent.buffered( std::max( extent.width(), extent.height() ) / 6.0 );
      }

      return extent;
    }
  }

  return QgsRectangle();
}

QList<QgsFeature> FeatureUtils::featuresFromJsonString( const QString &string )
{
  const QgsFields fields = QgsJsonUtils::stringToFields( string );
  return QgsJsonUtils::stringToFeatureList( string, fields );
}

QVariantList FeatureUtils::getUniqueValues( QgsVectorLayer *layer, const QString &fieldName )
{
  QVariantList uniqueValues;
  
  if (!layer)
    return uniqueValues;
  
  // Get the field index
  int fieldIndex = layer->fields().indexOf(fieldName);
  if (fieldIndex < 0)
    return uniqueValues;
  
  // Create a request to get unique values
  QgsFeatureRequest request;
  // Only request the specific field we need
  request.setSubsetOfAttributes(QgsAttributeList() << fieldIndex);
  
  // Get all features
  QgsFeatureIterator features = layer->getFeatures(request);
  QgsFeature feature;
  QSet<QVariant> valueSet;
  
  // Collect unique values
  while (features.nextFeature(feature))
  {
    QVariant value = feature.attribute(fieldIndex);
    if (!value.isNull() && value.isValid() && !valueSet.contains(value))
    {
      valueSet.insert(value);
    }
  }
  
  // Convert set to list
  uniqueValues = valueSet.values();
  
  return uniqueValues;
}

QVariantList FeatureUtils::getUniqueValuesFiltered( QgsVectorLayer *layer, const QString &fieldName, const QString &filterExpression )
{
  QVariantList uniqueValues;
  
  if (!layer)
    return uniqueValues;
  
  // Get the field index
  int fieldIndex = layer->fields().indexOf(fieldName);
  if (fieldIndex < 0)
    return uniqueValues;
  
  // Create a request to get unique values with filter
  QgsFeatureRequest request;
  // Only request the specific field we need
  request.setSubsetOfAttributes(QgsAttributeList() << fieldIndex);
  
  // Set the filter expression
  if (!filterExpression.isEmpty())
  {
    request.setFilterExpression(filterExpression);
  }
  
  // Get all features
  QgsFeatureIterator features = layer->getFeatures(request);
  QgsFeature feature;
  QSet<QVariant> valueSet;
  
  // Collect unique values
  while (features.nextFeature(feature))
  {
    QVariant value = feature.attribute(fieldIndex);
    if (!value.isNull() && value.isValid() && !valueSet.contains(value))
    {
      valueSet.insert(value);
    }
  }
  
  // Convert set to list
  uniqueValues = valueSet.values();
  
  return uniqueValues;
}

QList<QgsFeature> FeatureUtils::getFilteredFeatures( QgsVectorLayer *layer, const QString &filterExpression )
{
  QList<QgsFeature> filteredFeatures;
  
  if (!layer)
    return filteredFeatures;
  
  // Create a request with filter
  QgsFeatureRequest request;
  
  // Set the filter expression
  if (!filterExpression.isEmpty())
  {
    request.setFilterExpression(filterExpression);
  }
  
  // Get all features
  QgsFeatureIterator features = layer->getFeatures(request);
  QgsFeature feature;
  
  // Collect features
  while (features.nextFeature(feature))
  {
    filteredFeatures.append(feature);
  }
  
  return filteredFeatures;
}

QgsFeature FeatureUtils::getFeatureById( QgsVectorLayer *layer, int featureId )
{
  QgsFeature feature;
  
  if (!layer)
    return feature;
  
  // Create a request with feature ID filter
  QgsFeatureRequest request;
  request.setFilterFid(featureId);
  
  // Get the feature
  layer->getFeatures(request).nextFeature(feature);
  
  return feature;
}

QgsRectangle FeatureUtils::extentOfFeatures( QgsQuickMapSettings *mapSettings, QgsVectorLayer *layer, const QList<QgsFeature> &features )
{
  if (!mapSettings || !layer || features.isEmpty())
    return QgsRectangle();
  
  QgsRectangle extent;
  bool firstFeature = true;
  
  // Transform coordinates to map CRS
  QgsCoordinateTransform transf(layer->crs(), mapSettings->destinationCrs(), mapSettings->mapSettings().transformContext());
  
  // Calculate the combined extent of all features
  for (const QgsFeature &feature : features)
  {
    QgsGeometry geom(feature.geometry());
    if (!geom.isNull())
    {
      geom.transform(transf);
      
      if (firstFeature)
      {
        extent = geom.boundingBox();
        firstFeature = false;
      }
      else
      {
        extent.combineExtentWith(geom.boundingBox());
      }
    }
  }
  
  // Buffer the extent for better visibility
  if (!extent.isNull())
  {
    extent = extent.buffered(std::max(extent.width(), extent.height()) / 10.0);
  }
  
  return extent;
}
