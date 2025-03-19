/***************************************************************************
                          qgsgpkgflusher.cpp
                             -------------------
  begin                : Oct 2019
  copyright            : (C) 2019 by Matthias Kuhn
  email                : matthias@opengis.ch
***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/


#include "qgsgpkgflusher.h"
#include "qgsflusher.h"

#include <QObject>
#include <QRegularExpression>
#include <QTimer>
#include <qgsmessagelog.h>
#include <qgsproject.h>
#include <qgsvectorlayer.h>

#include <sqlite3.h>

QgsGpkgFlusher::QgsGpkgFlusher( QgsProject *project )
  : QObject()
{
  connect( project, &QgsProject::layersAdded, this, &QgsGpkgFlusher::onLayersAdded );
  mFlusher = new Flusher();
  mFlusher->moveToThread( &mFlusherThread );
  connect( this, &QgsGpkgFlusher::requestFlush, mFlusher, &Flusher::scheduleFlush );
  mFlusherThread.start();
}

QgsGpkgFlusher::~QgsGpkgFlusher()
{
  mFlusherThread.quit();
  mFlusherThread.wait();
}

void QgsGpkgFlusher::onLayersAdded( const QList<QgsMapLayer *> &layers )
{
  for ( QgsMapLayer *layer : layers )
  {
    QgsVectorLayer *vl = dynamic_cast<QgsVectorLayer *>( layer );
    if ( vl && vl->dataProvider() )
    {
      QString dataSourceUri = vl->dataProvider()->dataSourceUri();

      QString filePath;
      if ( dataSourceUri.contains( QStringLiteral( ".sqlite" ), Qt::CaseInsensitive ) )
      {
        //sqlite source
        QRegularExpression re( ".*dbname='(?<filepath>[^']*).*" );
        QRegularExpressionMatch match = re.match( dataSourceUri );
        if ( match.hasMatch() )
          filePath = match.captured( QStringLiteral( "filepath" ) );
      }
      else if ( dataSourceUri.contains( QStringLiteral( ".gpkg" ), Qt::CaseInsensitive ) )
      {
        //gpkg source
        filePath = dataSourceUri.left( dataSourceUri.indexOf( '|' ) );
        
        // Extra handling for GPKG files to prevent crashes
        QFileInfo fi( filePath );
        QgsMessageLog::logMessage( QStringLiteral( "Added GPKG layer: %1" ).arg( filePath ) );
        
        // Temporarily stop the flusher for this file to prevent first-time crashes
        // We'll start it again after a delay
        stop( filePath );
        
        // Schedule to start the flusher after some time to allow the database to initialize
        QTimer::singleShot(2000, this, [this, filePath]() {
          QgsMessageLog::logMessage( QStringLiteral( "Starting flusher for: %1" ).arg( filePath ) );
          start( filePath );
        });
      }
      else
      {
        //other source (e.g. postgres or shape)
        continue;
      }
      QFileInfo fi( filePath );
      if ( fi.isFile() )
      {
        connect( vl, &QgsVectorLayer::editingStopped, [this, filePath]() { emit requestFlush( filePath ); } );
      }
    }
  }
}

void QgsGpkgFlusher::stop( const QString &fileName )
{
  mFlusher->stop( fileName );
}

void QgsGpkgFlusher::start( const QString &fileName )
{
  mFlusher->start( fileName );
}

bool QgsGpkgFlusher::isStopped( const QString &fileName ) const
{
  return mFlusher->isStopped( fileName );
}
