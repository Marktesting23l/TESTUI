#ifndef QGSFLUSHER_H
#define QGSFLUSHER_H

#include <QObject>
#include <QMap>
#include <QTimer>
#include <QMutex>
#include <QString>

/**
 * \brief The Flusher class handles SQLite flush operations for GeoPackage files.
 * 
 * This class schedules and executes flush operations for SQLite databases,
 * particularly GeoPackage files. It includes safety mechanisms to prevent crashes
 * on Android and other platforms by implementing delays and error checking.
 */
class Flusher : public QObject
{
    Q_OBJECT

  public slots:
    /**
     * Schedules a new flush for the given \a filename after 500ms.
     * If a new flush is scheduled for the same file before the actual flush is performed, the timer is reset to wait another 500ms.
     */
    void scheduleFlush( const QString &filename );

    /**
     * Flushes the contents of the given \a filename.
     */
    void flush( const QString &filename );

    /**
     * Immediately performs a flush for a given \a fileName and returns. If the flusher is stopped, flush for that \a fileName would be ignored.
     */
    void stop( const QString &fileName );

    /**
     * Reenables scheduling flushes for a given \a fileName.
     */
    void start( const QString &fileName );

    /**
     * Returns whether the flusher is stopped for a given \a fileName.
     */
    bool isStopped( const QString &fileName ) const;

  private:
    QMutex mMutex;
    QMap<QString, QTimer *> mScheduledFlushes;
    QMap<QString, bool> mStoppedFlushes;
};

#endif // QGSFLUSHER_H 