#ifndef SENTINELPROCESSING_H
#define SENTINELPROCESSING_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QgsRasterLayer>
#include <QgsProcessingAlgorithm>
#include <QgsProcessingContext>
#include <QgsProcessingFeedback>

/**
 * @brief The SentinelProcessing class provides methods for processing Sentinel-2 imagery
 * directly in the mobile app using QGIS processing algorithms.
 */
class SentinelProcessing : public QObject
{
    Q_OBJECT

public:
    explicit SentinelProcessing(QObject *parent = nullptr);
    ~SentinelProcessing();

    /**
     * @brief Calculate NDVI from a Sentinel-2 raster layer
     * @param layer The input raster layer
     * @param outputName The name for the output layer
     * @param addToProject Whether to add the result to the current project
     * @param saveToFile Whether to save the result to a file
     * @param outputFormat The format to save the result in (if saveToFile is true)
     * @return A map containing success status, message, and output layer
     */
    Q_INVOKABLE QVariantMap calculateNDVI(QgsRasterLayer *layer, 
                                         const QString &outputName,
                                         bool addToProject = true,
                                         bool saveToFile = false,
                                         const QString &outputFormat = "GeoTIFF");

    /**
     * @brief Calculate NDWI from a Sentinel-2 raster layer
     * @param layer The input raster layer
     * @param outputName The name for the output layer
     * @param addToProject Whether to add the result to the current project
     * @param saveToFile Whether to save the result to a file
     * @param outputFormat The format to save the result in (if saveToFile is true)
     * @return A map containing success status, message, and output layer
     */
    Q_INVOKABLE QVariantMap calculateNDWI(QgsRasterLayer *layer,
                                         const QString &outputName,
                                         bool addToProject = true,
                                         bool saveToFile = false,
                                         const QString &outputFormat = "GeoTIFF");

    /**
     * @brief Calculate NDBI from a Sentinel-2 raster layer
     * @param layer The input raster layer
     * @param outputName The name for the output layer
     * @param addToProject Whether to add the result to the current project
     * @param saveToFile Whether to save the result to a file
     * @param outputFormat The format to save the result in (if saveToFile is true)
     * @return A map containing success status, message, and output layer
     */
    Q_INVOKABLE QVariantMap calculateNDBI(QgsRasterLayer *layer,
                                         const QString &outputName,
                                         bool addToProject = true,
                                         bool saveToFile = false,
                                         const QString &outputFormat = "GeoTIFF");

    /**
     * @brief Create a false color composite from a Sentinel-2 raster layer
     * @param layer The input raster layer
     * @param outputName The name for the output layer
     * @param addToProject Whether to add the result to the current project
     * @param saveToFile Whether to save the result to a file
     * @param outputFormat The format to save the result in (if saveToFile is true)
     * @return A map containing success status, message, and output layer
     */
    Q_INVOKABLE QVariantMap createFalseColor(QgsRasterLayer *layer,
                                            const QString &outputName,
                                            bool addToProject = true,
                                            bool saveToFile = false,
                                            const QString &outputFormat = "GeoTIFF");

    /**
     * @brief Create a true color composite from a Sentinel-2 raster layer
     * @param layer The input raster layer
     * @param outputName The name for the output layer
     * @param addToProject Whether to add the result to the current project
     * @param saveToFile Whether to save the result to a file
     * @param outputFormat The format to save the result in (if saveToFile is true)
     * @return A map containing success status, message, and output layer
     */
    Q_INVOKABLE QVariantMap createTrueColor(QgsRasterLayer *layer,
                                           const QString &outputName,
                                           bool addToProject = true,
                                           bool saveToFile = false,
                                           const QString &outputFormat = "GeoTIFF");

    /**
     * @brief Execute a QGIS processing algorithm with the given parameters
     * @param algorithmId The ID of the algorithm to execute
     * @param parameters The parameters for the algorithm
     * @return A map containing success status, message, and output layer
     */
    Q_INVOKABLE QVariantMap executeProcessingAlgorithm(const QString &algorithmId,
                                                      const QVariantMap &parameters);

    /**
     * @brief Compare two raster layers (e.g., NDVI from different dates)
     * @param layer1 The first raster layer
     * @param layer2 The second raster layer
     * @param outputName The name for the output layer
     * @param operation The operation to perform (subtract, divide, etc.)
     * @param addToProject Whether to add the result to the current project
     * @param saveToFile Whether to save the result to a file
     * @param outputFormat The format to save the result in (if saveToFile is true)
     * @return A map containing success status, message, and output layer
     */
    Q_INVOKABLE QVariantMap compareRasters(QgsRasterLayer *layer1,
                                          QgsRasterLayer *layer2,
                                          const QString &outputName,
                                          const QString &operation = "subtract",
                                          bool addToProject = true,
                                          bool saveToFile = false,
                                          const QString &outputFormat = "GeoTIFF");

private:
    QgsProcessingContext mProcessingContext;
    QgsProcessingFeedback *mProcessingFeedback;

    /**
     * @brief Apply a color ramp to a raster layer
     * @param layer The layer to apply the color ramp to
     * @param rampType The type of color ramp to apply
     */
    void applyColorRamp(QgsRasterLayer *layer, const QString &rampType);

    /**
     * @brief Save a raster layer to a file
     * @param layer The layer to save
     * @param filePath The path to save the layer to
     * @param format The format to save the layer in
     * @return True if the layer was saved successfully, false otherwise
     */
    bool saveRasterLayer(QgsRasterLayer *layer, const QString &filePath, const QString &format);
};

#endif // SENTINELPROCESSING_H 