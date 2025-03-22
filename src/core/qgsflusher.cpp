#include "qgsflusher.h"
#include <QFileInfo>
#include <QMutexLocker>
#include <qgsmessagelog.h>
#include <qgssqliteutils.h>
#include <sqlite3.h>

// Make sure SQLITE constants are defined
#ifndef SQLITE_OPEN_READWRITE
#define SQLITE_OPEN_READWRITE 0x00000002
#endif

void Flusher::scheduleFlush( const QString &filename )
{
  if ( mStoppedFlushes.value( filename, false ) )
    return;

  // Use shorter delay for critical files
  int delayMs = 250; // Default to shorter delay for all files
  
  // For any other file, use the previous 500ms delay
  if (!filename.contains("Mis_Datos.gpkg", Qt::CaseInsensitive)) {
    delayMs = 500;
  }

  if ( mScheduledFlushes.contains( filename ) )
  {
    mScheduledFlushes.value( filename )->start( delayMs );
  }
  else
  {
    QTimer *timer = new QTimer();
    connect( timer, &QTimer::timeout, this, [this, filename]() { flush( filename ); } );
    timer->setSingleShot( true );
    mScheduledFlushes.insert( filename, timer );
    timer->start( delayMs );
  }
}

void Flusher::flush( const QString &filename )
{
  if ( mStoppedFlushes.value( filename, false ) )
    return;

  QMutexLocker<QMutex> locker( &mMutex );

  // Check if the file exists and is accessible before attempting to open it
  QFileInfo fileInfo(filename);
  if (!fileInfo.exists() || !fileInfo.isReadable() || !fileInfo.isWritable()) 
  {
    // Only log critical errors with Qgis::Critical level
    QgsMessageLog::logMessage( QObject::tr( "Cannot flush database - file not accessible: %1" ).arg( filename ), QString(), Qgis::Critical );
    if ( mScheduledFlushes.contains(filename) )
    {
      // Use shorter retry for critical files
      int retryDelayMs = filename.contains("Mis_Datos.gpkg", Qt::CaseInsensitive) ? 500 : 1000;
      
      // Re-schedule for later if file might become available
      mScheduledFlushes[filename]->start( retryDelayMs );
    }
    return;
  }

  // Add extra try-catch to prevent crashes on Android
  try 
  {
    sqlite3_database_unique_ptr db;
    int status = db.open_v2( filename, SQLITE_OPEN_READWRITE, nullptr );
    if ( status != SQLITE_OK )
    {
      // Only log critical errors with Qgis::Critical level
      QgsMessageLog::logMessage( QObject::tr( "There was an error opening the database <b>%1</b>: %2" ).arg( filename, db.errorMessage() ), QString(), Qgis::Critical );
      
      // If we can't open the database, try again later rather than crashing
      if ( mScheduledFlushes.contains(filename) )
      {
        // Use shorter retry for critical files
        int retryDelayMs = filename.contains("Mis_Datos.gpkg", Qt::CaseInsensitive) ? 500 : 1000;
        
        mScheduledFlushes[filename]->start( retryDelayMs );
      }
      return;
    }

    QString error;
    // Add PRAGMA to optimize SQLite on Android
    db.exec( "PRAGMA journal_mode=WAL;", error );
    db.exec( "PRAGMA synchronous=NORMAL;", error );
    db.exec( "PRAGMA wal_checkpoint;", error );

    if ( error.isEmpty() )
    {
      if ( mScheduledFlushes.contains(filename) )
      {
        delete mScheduledFlushes[filename];
        mScheduledFlushes.remove( filename );
      }
    }
    else
    {
      // Only log critical errors with Qgis::Critical level
      QgsMessageLog::logMessage( QObject::tr( "Could not flush database %1 (%2) " ).arg( filename, error ), QString(), Qgis::Critical );
      if ( mScheduledFlushes.contains(filename) )
      {
        // Use shorter retry for critical files
        int retryDelayMs = filename.contains("Mis_Datos.gpkg", Qt::CaseInsensitive) ? 500 : 1000;
        
        mScheduledFlushes[filename]->start( retryDelayMs );
      }
    }
  }
  catch (const std::exception& e)
  {
    // Only log critical errors with Qgis::Critical level
    QgsMessageLog::logMessage( QObject::tr( "Exception while flushing database %1: %2" ).arg( filename, e.what() ), QString(), Qgis::Critical );
    // Try again later
    if ( mScheduledFlushes.contains(filename) )
    {
      // Use shorter retry for critical files, but longer overall since this was an exception
      int retryDelayMs = filename.contains("Mis_Datos.gpkg", Qt::CaseInsensitive) ? 1000 : 2000;
      
      mScheduledFlushes[filename]->start( retryDelayMs );
    }
  }
  catch (...)
  {
    // Only log critical errors with Qgis::Critical level
    QgsMessageLog::logMessage( QObject::tr( "Unknown exception while flushing database %1" ).arg( filename ), QString(), Qgis::Critical );
    // Try again later with an increased delay
    if ( mScheduledFlushes.contains(filename) )
    {
      mScheduledFlushes[filename]->start( 2000 );
    }
  }

  // No need to unlock explicitly - QMutexLocker will do it automatically
}

void Flusher::stop( const QString &fileName )
{
  if ( !mScheduledFlushes.contains( fileName ) )
    return;

  mScheduledFlushes.value( fileName )->stop();
  mScheduledFlushes.remove( fileName );

  flush( fileName );

  mStoppedFlushes.insert( fileName, true );
}

void Flusher::start( const QString &fileName )
{
  mStoppedFlushes.remove( fileName );
}

bool Flusher::isStopped( const QString &fileName ) const
{
  return mStoppedFlushes.value( fileName, false );
} 