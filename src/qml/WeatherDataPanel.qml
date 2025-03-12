import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtCharts 2.3

Drawer {
    id: weatherDataPanel
    
    property bool isLoading: false
    property var selectedProvince: null
    property var selectedStation: null
    property var weatherData: null
    property string errorMessage: ""
    property bool hasError: errorMessage !== ""
    
    // Signal to zoom to station in QGIS
    signal zoomToStation(double latitude, double longitude)
    
    // List of Andalucía provinces IDs
    property var andaluciaProvinceIds: [4, 11, 14, 18, 21, 23, 29, 41] // Almería, Cádiz, Córdoba, Granada, Huelva, Jaén, Málaga, Sevilla
    
    // Selected variable for chart display
    property string selectedVariable: "temperature" // Default to temperature
    
    width: parent.width * 0.9
    height: parent.height
    edge: Qt.RightEdge
    
    // Create an instance of the RIA Weather Service
    RIAWeatherService {
        id: riaService
        
        onProvincesLoaded: function(provinces) {
            provincesModel.clear()
            // Only add the 8 provinces of Andalucía
            provinces.forEach(function(province) {
                // Filter to only include Andalucía provinces
                if (andaluciaProvinceIds.indexOf(province.id) !== -1) {
                provincesModel.append({
                    id: province.id,
                    name: province.nombre
                })
                }
            })
            isLoading = false
        }
        
        onStationsLoaded: function(stations) {
            stationsModel.clear()
            stations.forEach(function(station) {
                stationsModel.append({
                    code: station.codigoEstacion,
                    name: station.nombre,
                    latitude: station.latitud,
                    longitude: station.longitud,
                    altitude: station.altitud
                })
            })
            isLoading = false
        }
        
        onDailyDataLoaded: function(dailyData) {
            weatherData = dailyData
            isLoading = false
            updateChartData()
        }
        
        onMonthlyDataLoaded: function(monthlyData) {
            weatherData = monthlyData
            isLoading = false
            console.log("Monthly data loaded: " + JSON.stringify(monthlyData))
            updateChartData()
        }
        
        onErrorOccurred: function(message) {
            errorMessage = message
            isLoading = false
        }
    }
    
    // Models for the ComboBoxes
    ListModel {
        id: provincesModel
    }
    
    ListModel {
        id: stationsModel
    }
    
    // Function to load provinces when the panel is opened
    function open() {
        isLoading = true
        errorMessage = ""
        riaService.loadProvinces()
        visible = true
        
        // Initialize date fields with current date
        var today = new Date()
        var year = today.getFullYear()
        var month = today.getMonth() + 1
        
        // Set start date to first day of current month
        var formattedMonth = month < 10 ? "0" + month : month
        var startDate = year + "-" + formattedMonth + "-01"
        
        // Set end date to current day
        var day = today.getDate()
        var formattedDay = day < 10 ? "0" + day : day
        var endDate = year + "-" + formattedMonth + "-" + formattedDay
        
        startDateField.text = startDate
        endDateField.text = endDate
    }
    
    // Function to format date for API requests
    function formatDateForAPI(date) {
        // The API expects ISO format without milliseconds and with 'Z' timezone
        var isoString = date.toISOString();
        // Remove milliseconds part and ensure 'Z' is present
        return isoString.split('.')[0] + "Z";
    }
    
    // Function to update chart data
    function updateChartData() {
        if (!weatherData) return
        
        // Clear existing series
        dataChart.removeAllSeries()
        
        // Create appropriate series based on selected variable
        var series
        var yAxisTitle
        var yAxisMax
        
        // Debug the weatherData to check values
        console.log("Weather data type: " + (Array.isArray(weatherData) ? "Array" : "Object"))
        if (Array.isArray(weatherData)) {
            console.log("Weather data length: " + weatherData.length)
            if (weatherData.length > 0) {
                console.log("First item: " + JSON.stringify(weatherData[0]))
            }
        } else {
            console.log("Single weather data: " + JSON.stringify(weatherData))
        }
        
        // Check if we're dealing with monthly data
        var isMonthlyData = false
        if (Array.isArray(weatherData) && weatherData.length > 0) {
            isMonthlyData = weatherData[0].hasOwnProperty('mes') && weatherData[0].hasOwnProperty('anyo')
        } else if (weatherData) {
            isMonthlyData = weatherData.hasOwnProperty('mes') && weatherData.hasOwnProperty('anyo')
        }
        
        console.log("Is monthly data: " + isMonthlyData)
        
        // Calculate accumulated values if needed
        var accumulatedET0 = 0
        var thermalIntegral = 0
        var radiationIntegral = 0
        
        if (Array.isArray(weatherData)) {
            weatherData.forEach(function(data) {
                // Calculate thermal integral (average temperature accumulation)
                if (data.tempMedia) {
                    thermalIntegral += data.tempMedia
                }
                
                // Calculate radiation integral
                if (data.radiacion) {
                    radiationIntegral += data.radiacion
                }
                
                // Calculate ET0 accumulation
                if (data.et0) {
                    accumulatedET0 += data.et0
                }
            })
        } else {
            if (weatherData.tempMedia) {
                thermalIntegral = weatherData.tempMedia
            }
            if (weatherData.radiacion) {
                radiationIntegral = weatherData.radiacion
            }
            if (weatherData.et0) {
                accumulatedET0 = weatherData.et0
            }
        }
        
        if (selectedVariable === "temperature") {
            // Temperature data
            var tempMaxSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Temp. Máxima", dataAxisX, dataAxisY)
            var tempMinSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Temp. Mínima", dataAxisX, dataAxisY)
            var tempMedSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Temp. Media", dataAxisX, dataAxisY)
            
            yAxisTitle = "Temperatura (°C)"
            
            // Find min and max temperature to set Y axis range
            var minTemp = 0
            var maxTemp = 40
            
            if (Array.isArray(weatherData)) {
                weatherData.forEach(function(data) {
                    if (data.tempMin && data.tempMin < minTemp) {
                        minTemp = data.tempMin
                    }
                    if (data.tempMax && data.tempMax > maxTemp) {
                        maxTemp = data.tempMax
                    }
                })
            } else if (weatherData) {
                if (weatherData.tempMin && weatherData.tempMin < minTemp) {
                    minTemp = weatherData.tempMin
                }
                if (weatherData.tempMax && weatherData.tempMax > maxTemp) {
                    maxTemp = weatherData.tempMax
                }
            }
            
            // Ensure min temp is at least 5 degrees below 0 if negative
            if (minTemp < 0) {
                minTemp = Math.floor(minTemp / 5) * 5
            } else {
                minTemp = 0
            }
            
            // Round max temp up to nearest 5
            maxTemp = Math.ceil(maxTemp / 5) * 5
            
            yAxisMax = maxTemp
            dataAxisY.min = minTemp
            
            // Add data points
            if (Array.isArray(weatherData)) {
                weatherData.forEach(function(data, index) {
                    tempMaxSeries.append(index, data.tempMax || 0)
                    tempMinSeries.append(index, data.tempMin || 0)
                    tempMedSeries.append(index, data.tempMedia || 0)
                })
                dataAxisX.max = weatherData.length - 1
            } else {
                tempMaxSeries.append(0, weatherData.tempMax || 0)
                tempMinSeries.append(0, weatherData.tempMin || 0)
                tempMedSeries.append(0, weatherData.tempMedia || 0)
                dataAxisX.max = 1
            }
        } else if (selectedVariable === "humidity") {
            // Humidity data
            var humMaxSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Hum. Máxima", dataAxisX, dataAxisY)
            var humMinSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Hum. Mínima", dataAxisX, dataAxisY)
            var humMedSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Hum. Media", dataAxisX, dataAxisY)
            
            yAxisTitle = "Humedad (%)"
            yAxisMax = 100
            
            // Add data points
            if (Array.isArray(weatherData)) {
                weatherData.forEach(function(data, index) {
                    humMaxSeries.append(index, data.humedadMax || 0)
                    humMinSeries.append(index, data.humedadMin || 0)
                    humMedSeries.append(index, data.humedadMedia || 0)
                })
                dataAxisX.max = weatherData.length - 1
            } else {
                humMaxSeries.append(0, weatherData.humedadMax || 0)
                humMinSeries.append(0, weatherData.humedadMin || 0)
                humMedSeries.append(0, weatherData.humedadMedia || 0)
                dataAxisX.max = 1
            }
        } else if (selectedVariable === "radiation") {
            // Radiation data
            var radSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Radiación", dataAxisX, dataAxisY)
            
            yAxisTitle = "Radiación (MJ/m²)"
            yAxisMax = 35
            
            // Add data points
            if (Array.isArray(weatherData)) {
                weatherData.forEach(function(data, index) {
                    radSeries.append(index, data.radiacion || 0)
                })
                dataAxisX.max = weatherData.length - 1
            } else {
                radSeries.append(0, weatherData.radiacion || 0)
                dataAxisX.max = 1
            }
        } else if (selectedVariable === "et0") {
            // ET0 data - only available for daily data
            if (isMonthlyData) {
                // Show message that ET0 is not available for monthly data
                var noDataSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "ET0 no disponible", dataAxisX, dataAxisY)
                noDataSeries.visible = false
                
                // Add a label to the chart
                dataChart.title = "ET0 no disponible para datos mensuales"
                yAxisTitle = "ET0 (mm)"
                yAxisMax = 10
            } else {
                var et0Series = dataChart.createSeries(ChartView.SeriesTypeLine, "ET0", dataAxisX, dataAxisY)
                
                yAxisTitle = "ET0 (mm)"
                yAxisMax = 10
                
                // Add data points
                if (Array.isArray(weatherData)) {
                    weatherData.forEach(function(data, index) {
                        et0Series.append(index, data.et0 || 0)
                    })
                    dataAxisX.max = weatherData.length - 1
                } else {
                    et0Series.append(0, weatherData.et0 || 0)
                    dataAxisX.max = 1
                }
            }
        } else if (selectedVariable === "precipitation") {
            // Precipitation data using LineSeries
            console.log("Creating precipitation chart with LineSeries")
            
            yAxisTitle = "Precipitación (mm)"
            yAxisMax = 50
            
            // Process the data first to calculate max precipitation
            var maxPrecip = 0
            
            if (Array.isArray(weatherData)) {
                console.log("Processing array data with length: " + weatherData.length)
                
                // Calculate max precipitation for scaling
                for (var i = 0; i < weatherData.length; i++) {
                    try {
                        var data = weatherData[i]
                        var precip = 0
                        
                        // Safely parse precipitation value
                        if (data.precipitacion !== undefined && data.precipitacion !== null) {
                            if (typeof data.precipitacion === 'string') {
                                precip = parseFloat(data.precipitacion.replace(',', '.'))
                                if (isNaN(precip)) precip = 0
                            } else {
                                precip = Number(data.precipitacion)
                                if (isNaN(precip)) precip = 0
                            }
                        }
                        
                        // Track maximum value for Y axis scaling
                        if (precip > maxPrecip) {
                            maxPrecip = precip
                        }
                    } catch (e) {
                        console.error("Error processing precipitation data at index " + i + ": " + e)
                    }
                }
                
                // Set Y axis range based on data
                if (maxPrecip > 0) {
                    yAxisMax = Math.ceil(maxPrecip / 5) * 5 // Round up to nearest 5
                } else {
                    yAxisMax = 5 // Default if no precipitation
                }
                
                // Create a LineSeries for precipitation
                var precipSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Precipitación", dataAxisX, dataAxisY)
                precipSeries.width = 3
                
                // Add data points to the series
                for (var j = 0; j < weatherData.length; j++) {
                    try {
                        var dataPoint = weatherData[j]
                        var precipValue = 0
                        
                        // Safely parse precipitation value
                        if (dataPoint.precipitacion !== undefined && dataPoint.precipitacion !== null) {
                            if (typeof dataPoint.precipitacion === 'string') {
                                precipValue = parseFloat(dataPoint.precipitacion.replace(',', '.'))
                                if (isNaN(precipValue)) precipValue = 0
                            } else {
                                precipValue = Number(dataPoint.precipitacion)
                                if (isNaN(precipValue)) precipValue = 0
                            }
                        }
                        
                        // Use append with numeric values
                        precipSeries.append(j, precipValue)
                        console.log("Added precipitation point at index " + j + " with value " + precipValue)
                    } catch (e) {
                        console.error("Error adding precipitation point at index " + j + ": " + e)
                    }
                }
            } else if (weatherData) {
                console.log("Processing single data point")
                try {
                    var singlePrecip = 0
                    
                    // Safely parse precipitation value
                    if (weatherData.precipitacion !== undefined && weatherData.precipitacion !== null) {
                        if (typeof weatherData.precipitacion === 'string') {
                            singlePrecip = parseFloat(weatherData.precipitacion.replace(',', '.'))
                            if (isNaN(singlePrecip)) singlePrecip = 0
                        } else {
                            singlePrecip = Number(weatherData.precipitacion)
                            if (isNaN(singlePrecip)) singlePrecip = 0
                        }
                    }
                    
                    console.log("Single precipitation data: " + JSON.stringify(weatherData.precipitacion) + " parsed as: " + singlePrecip)
                    
                    // Set Y axis range based on data
                    if (singlePrecip > 0) {
                        yAxisMax = Math.ceil(singlePrecip / 5) * 5 // Round up to nearest 5
                    } else {
                        yAxisMax = 5 // Default if no precipitation
                    }
                    
                    // Create a LineSeries for precipitation
                    var singlePrecipSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Precipitación", dataAxisX, dataAxisY)
                    singlePrecipSeries.width = 3
                    
                    // Add the single data point
                    singlePrecipSeries.append(0, singlePrecip)
                    console.log("Added single precipitation point with value " + singlePrecip)
                } catch (e) {
                    console.error("Error processing single precipitation data: " + e)
                }
            }
        } else if (selectedVariable === "thermal_integral") {
            // Thermal integral data - not applicable for monthly data
            if (isMonthlyData) {
                // Show message that thermal integral is not available for monthly data
                var noDataSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Integral Térmica no disponible", dataAxisX, dataAxisY)
                noDataSeries.visible = false
                
                // Add a label to the chart
                dataChart.title = "Integral Térmica no disponible para datos mensuales"
                yAxisTitle = "Integral Térmica (°C·día)"
                yAxisMax = 10
            } else {
                var thermalSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Integral Térmica", dataAxisX, dataAxisY)
                
                yAxisTitle = "Integral Térmica (°C·día)"
                yAxisMax = Math.ceil(thermalIntegral / 10) * 10
                
                // Add accumulated points
                var accumTemp = 0
                if (Array.isArray(weatherData)) {
                    weatherData.forEach(function(data, index) {
                        if (data.tempMedia) {
                            accumTemp += data.tempMedia
                        }
                        thermalSeries.append(index, accumTemp)
                    })
                    dataAxisX.max = weatherData.length - 1
                } else {
                    thermalSeries.append(0, weatherData.tempMedia || 0)
                    dataAxisX.max = 1
                }
            }
        } else if (selectedVariable === "radiation_integral") {
            // Radiation integral data - not applicable for monthly data
            if (isMonthlyData) {
                // Show message that radiation integral is not available for monthly data
                var noDataSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Integral Radiación no disponible", dataAxisX, dataAxisY)
                noDataSeries.visible = false
                
                // Add a label to the chart
                dataChart.title = "Integral Radiación no disponible para datos mensuales"
                yAxisTitle = "Integral Radiación (MJ/m²·día)"
                yAxisMax = 10
            } else {
                var radIntSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "Integral Radiación", dataAxisX, dataAxisY)
                
                yAxisTitle = "Integral Radiación (MJ/m²·día)"
                yAxisMax = Math.ceil(radiationIntegral / 10) * 10
                
                // Add accumulated points
                var accumRad = 0
                if (Array.isArray(weatherData)) {
                    weatherData.forEach(function(data, index) {
                        if (data.radiacion) {
                            accumRad += data.radiacion
                        }
                        radIntSeries.append(index, accumRad)
                    })
                    dataAxisX.max = weatherData.length - 1
                } else {
                    radIntSeries.append(0, weatherData.radiacion || 0)
                    dataAxisX.max = 1
                }
            }
        } else if (selectedVariable === "et0_accumulated") {
            // Accumulated ET0 data - not applicable for monthly data
            if (isMonthlyData) {
                // Show message that ET0 accumulated is not available for monthly data
                var noDataSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "ET0 Acumulada no disponible", dataAxisX, dataAxisY)
                noDataSeries.visible = false
                
                // Add a label to the chart
                dataChart.title = "ET0 Acumulada no disponible para datos mensuales"
                yAxisTitle = "ET0 Acumulada (mm)"
                yAxisMax = 10
            } else {
                var et0AccumSeries = dataChart.createSeries(ChartView.SeriesTypeLine, "ET0 Acumulada", dataAxisX, dataAxisY)
                
                yAxisTitle = "ET0 Acumulada (mm)"
                yAxisMax = Math.ceil(accumulatedET0 / 10) * 10
                if (yAxisMax < 10) yAxisMax = 10 // Ensure minimum scale
                
                // Add accumulated points
                var accumET0 = 0
                if (Array.isArray(weatherData)) {
                    weatherData.forEach(function(data, index) {
                        if (data.et0) {
                            accumET0 += data.et0
                        }
                        et0AccumSeries.append(index, accumET0)
                    })
                    dataAxisX.max = weatherData.length - 1
                } else {
                    et0AccumSeries.append(0, weatherData.et0 || 0)
                    dataAxisX.max = 1
                }
            }
        }
        
        // Update axis labels
        dataAxisY.titleText = yAxisTitle
        dataAxisY.max = yAxisMax
        
        // For temperature, we might have set a custom min value
        if (selectedVariable !== "temperature") {
            dataAxisY.min = 0
        }
        
        // Update X axis labels
        if (Array.isArray(weatherData) && weatherData.length > 0) {
            // Create labels for X axis
            var labels = []
            
            // Handle monthly data differently
            if (isMonthlyData) {
                weatherData.forEach(function(data) {
                    var monthNames = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", 
                                     "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
                    var monthIndex = data.mes - 1 // Months are 1-indexed in the API
                    var monthName = monthNames[monthIndex]
                    labels.push(monthName)
                })
            } else {
                weatherData.forEach(function(data) {
                    var date = new Date(data.fecha)
                    var day = date.getDate()
                    var month = date.getMonth() + 1
                    labels.push(day + "/" + month)
                })
            }
            
            // Update chart title with month/year
            var titleYear = ""
            if (isMonthlyData && weatherData.length > 0) {
                titleYear = weatherData[0].anyo.toString()
            } else if (weatherData.length > 0) {
                var firstDate = new Date(weatherData[0].fecha)
                var monthNames = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
                                 "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
                var monthYear = monthNames[firstDate.getMonth()] + " " + firstDate.getFullYear()
                titleYear = monthYear
            }
            
            // Set chart title based on selected variable
            var variableTitle = ""
            if (selectedVariable === "temperature") variableTitle = "Temperatura"
            else if (selectedVariable === "humidity") variableTitle = "Humedad"
            else if (selectedVariable === "radiation") variableTitle = "Radiación"
            else if (selectedVariable === "et0") variableTitle = "ET0"
            else if (selectedVariable === "precipitation") variableTitle = "Precipitación"
            else if (selectedVariable === "thermal_integral") variableTitle = "Integral Térmica"
            else if (selectedVariable === "radiation_integral") variableTitle = "Integral Radiación"
            else if (selectedVariable === "et0_accumulated") variableTitle = "ET0 Acumulada"
            
            // Set all categories first - this ensures bars are positioned correctly
            dataAxisX.categories = labels
            
            // Add date information to chart title for clarity
            if (weatherData.length > 1) {
                if (isMonthlyData) {
                    dataChart.title = variableTitle + " - Datos mensuales " + titleYear
                } else {
                    var firstDateStr = labels[0]
                    var lastDateStr = labels[labels.length - 1]
                    dataChart.title = variableTitle + " - " + firstDateStr + " a " + lastDateStr + " " + titleYear
                }
            } else {
                dataChart.title = variableTitle + " - " + labels[0] + " " + titleYear
            }
        } else if (weatherData) {
            // Set up X axis for single data point
            var label = ""
            if (isMonthlyData) {
                var monthNames = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", 
                                 "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
                var monthIndex = weatherData.mes - 1 // Months are 1-indexed in the API
                label = monthNames[monthIndex]
            } else {
                var singleDate = new Date(weatherData.fecha)
                var singleDay = singleDate.getDate()
                var singleMonth = singleDate.getMonth() + 1
                label = singleDay + "/" + singleMonth
            }
            
            // Set the categories
            dataAxisX.categories = [label]
            
            // Set chart title based on selected variable
            var variableTitle = ""
            if (selectedVariable === "temperature") variableTitle = "Temperatura"
            else if (selectedVariable === "humidity") variableTitle = "Humedad"
            else if (selectedVariable === "radiation") variableTitle = "Radiación"
            else if (selectedVariable === "et0") variableTitle = "ET0"
            else if (selectedVariable === "precipitation") variableTitle = "Precipitación"
            else if (selectedVariable === "thermal_integral") variableTitle = "Integral Térmica"
            else if (selectedVariable === "radiation_integral") variableTitle = "Integral Radiación"
            else if (selectedVariable === "et0_accumulated") variableTitle = "ET0 Acumulada"
            
            // Use date in title for single data point
            if (isMonthlyData) {
                dataChart.title = variableTitle + " - " + label + " " + weatherData.anyo
            } else {
                var singleDate = new Date(weatherData.fecha)
                dataChart.title = variableTitle + " - " + label + " " + singleDate.getFullYear()
            }
        }
    }
    
    // Main content
    ColumnLayout {
        anchors.fill: parent
        // Reduce padding to create more space
        anchors.margins: 8
        spacing: 8
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
            
                Label {
                    text: "Datos Meteorológicos RIA"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "Datos IFAPA Andalucía - <a href='https://www.juntadeandalucia.es/agriculturaypesca/ifapa/riaweb/web/datosabiertos'>Más información</a>"
                    onLinkActivated: Qt.openUrlExternally(link)
                    font.pixelSize: 12
                    color: Material.accent
                }
            }
            
            // Add location button
            Button {
                id: locationButton
                text: "Ver ubicación"
                visible: selectedStation !== null
                onClicked: {
                    if (selectedStation && selectedStation.latitude && selectedStation.longitude) {
                        zoomToStation(selectedStation.latitude, selectedStation.longitude)
                    }
                }
                ToolTip.visible: hovered
                ToolTip.text: "Centrar el mapa en la ubicación de la estación"
            }
            
            Button {
                text: "Cerrar"
                onClicked: weatherDataPanel.visible = false
            }
        }
        
        // Error message
        Rectangle {
            visible: hasError
            color: "#FFEBEE"
            border.color: "#D32F2F"
            border.width: 1
            radius: 4
            Layout.fillWidth: true
            height: errorLabel.height + 16
            
            Label {
                id: errorLabel
                text: errorMessage
                color: "#D32F2F"
                anchors.centerIn: parent
                anchors.margins: 8
                wrapMode: Text.WordWrap
                width: parent.width - 16
            }
        }
        
        // Loading indicator
        BusyIndicator {
            visible: isLoading
            running: isLoading
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Selection controls
        GroupBox {
            title: "Selección"
            Layout.fillWidth: true
            padding: 4
            
            GridLayout {
                columns: 2
                rowSpacing: 4
                columnSpacing: 4
                anchors.fill: parent
                
                Label { text: "Provincia:" }
                ComboBox {
                    id: provinceComboBox
                    Layout.fillWidth: true
                    model: provincesModel
                    textRole: "name"
                    valueRole: "id"
                    enabled: !isLoading && provincesModel.count > 0
                    
                    onActivated: {
                        selectedProvince = provincesModel.get(currentIndex)
                        selectedStation = null
                        isLoading = true
                        errorMessage = ""
                        riaService.loadStations(selectedProvince.id)
                    }
                }
                
                Label { text: "Estación:" }
                ComboBox {
                    id: stationComboBox
                    Layout.fillWidth: true
                    model: stationsModel
                    textRole: "name"
                    valueRole: "code"
                    enabled: !isLoading && stationsModel.count > 0 && selectedProvince !== null
                    
                    onActivated: {
                        selectedStation = stationsModel.get(currentIndex)
                    }
                }
            }
        }
        
        // Date selection
        GroupBox {
            title: "Periodo"
            Layout.fillWidth: true
            enabled: selectedStation !== null
            padding: 4
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 4
                
                // Data type selection
                ButtonGroup { id: dataTypeGroup }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                
                RadioButton {
                        id: dailyDataRadio
                        text: "Datos diarios"
                    checked: true
                        ButtonGroup.group: dataTypeGroup
                    }
                    
                    RadioButton {
                        id: monthlyDataRadio
                        text: "Datos mensuales"
                        ButtonGroup.group: dataTypeGroup
                        onCheckedChanged: {
                            // Disable ET0 checkbox when monthly data is selected
                            if (checked) {
                                calculateEt0CheckBox.checked = false
                            }
                        }
                    }
                }
                
                // Daily data options
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: dailyDataRadio.checked
                    
                    ButtonGroup { id: dailyPeriodGroup }
                    
                    // Put all options in a single row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        RadioButton {
                            id: lastDataDayRadio
                            text: "Último día con datos"
                            checked: true
                            ButtonGroup.group: dailyPeriodGroup
                        }
                        
                        RadioButton {
                            id: yesterdayRadio
                            text: "14 días"
                            ButtonGroup.group: dailyPeriodGroup
                }
                
                RadioButton {
                    id: last7DaysRadio
                            text: "7 días"
                            ButtonGroup.group: dailyPeriodGroup
                }
                
                RadioButton {
                    id: customRangeRadio
                            text: "Rango"
                            ButtonGroup.group: dailyPeriodGroup
                        }
                }
                
                GridLayout {
                        columns: 4
                    Layout.fillWidth: true
                    visible: customRangeRadio.checked
                        rowSpacing: 4
                        columnSpacing: 4
                    
                        Label { text: "Inicio:" }
                    TextField {
                        id: startDateField
                        Layout.fillWidth: true
                        placeholderText: "YYYY-MM-DD"
                        inputMethodHints: Qt.ImhDate
                    }
                    
                        Label { text: "Fin:" }
                    TextField {
                        id: endDateField
                        Layout.fillWidth: true
                        placeholderText: "YYYY-MM-DD"
                        inputMethodHints: Qt.ImhDate
                        }
                    }
                }
                
                // Monthly data options
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: monthlyDataRadio.checked
                    
                    GridLayout {
                        columns: 4
                        Layout.fillWidth: true
                        rowSpacing: 4
                        columnSpacing: 4
                        
                        Label { text: "Año:" }
                        ComboBox {
                            id: yearComboBox
                            Layout.fillWidth: true
                            model: {
                                var years = [];
                                var currentYear = new Date().getFullYear();
                                for (var i = currentYear; i >= 2000; i--) {
                                    years.push(i);
                                }
                                return years;
                            }
                        }
                        
                        Label { text: "Mes:" }
                        ComboBox {
                            id: monthComboBox
                            Layout.fillWidth: true
                            model: [
                                { text: "Enero", value: 1 },
                                { text: "Febrero", value: 2 },
                                { text: "Marzo", value: 3 },
                                { text: "Abril", value: 4 },
                                { text: "Mayo", value: 5 },
                                { text: "Junio", value: 6 },
                                { text: "Julio", value: 7 },
                                { text: "Agosto", value: 8 },
                                { text: "Septiembre", value: 9 },
                                { text: "Octubre", value: 10 },
                                { text: "Noviembre", value: 11 },
                                { text: "Diciembre", value: 12 }
                            ]
                            textRole: "text"
                            valueRole: "value"
                            
                            Component.onCompleted: {
                                // Set to current month
                                var currentMonth = new Date().getMonth();
                                currentIndex = currentMonth;
                            }
                        }
                    }
                    
                    // Note about ET0 for monthly data
                    Label {
                        text: "Nota: Los datos mensuales no incluyen ET0 desde la API"
                        font.italic: true
                        font.pixelSize: 10
                        color: "#666666"
                    }
                }
                
                CheckBox {
                    id: calculateEt0CheckBox
                    text: "Calcular ET0 (Penman-Monteith)"
                    checked: true
                    visible: dailyDataRadio.checked
                    ToolTip.visible: hovered
                    ToolTip.text: "La ET0 (Evapotranspiración de referencia) se calcula mediante el algoritmo de Penman-Monteith"
                }
                
                Button {
                    text: "Cargar datos"
                    Layout.fillWidth: true
                    enabled: !isLoading && selectedStation !== null
                    
                    onClicked: {
                        isLoading = true
                        errorMessage = ""
                        
                        if (dailyDataRadio.checked) {
                            // Daily data
                            if (lastDataDayRadio.checked) {
                                // Load data from 2 days ago
                                var twoDaysAgo = new Date()
                                twoDaysAgo.setDate(twoDaysAgo.getDate() - 2)
                                // Set time to noon to avoid timezone issues
                                twoDaysAgo.setHours(12, 0, 0, 0)
                                
                                riaService.loadDailyData(
                                    selectedProvince.id,
                                    selectedStation.code,
                                    twoDaysAgo,
                                    calculateEt0CheckBox.checked
                                )
                            } else if (yesterdayRadio.checked) {
                                // Load last 14 days data
                                var endDate = new Date()
                                endDate.setDate(endDate.getDate() - 1) // Yesterday
                                // Set time to noon to avoid timezone issues
                                endDate.setHours(12, 0, 0, 0)
                                
                                var startDate = new Date()
                                startDate.setDate(startDate.getDate() - 14) // 14 days ago
                                // Set time to noon to avoid timezone issues
                                startDate.setHours(12, 0, 0, 0)
                                
                                riaService.loadDailyDataRange(
                                    selectedProvince.id,
                                    selectedStation.code,
                                    startDate,
                                    endDate,
                                calculateEt0CheckBox.checked
                            )
                        } else if (last7DaysRadio.checked) {
                            // Load last 7 days data
                            var endDate = new Date()
                                endDate.setDate(endDate.getDate() - 1) // Yesterday
                                // Set time to noon to avoid timezone issues
                                endDate.setHours(12, 0, 0, 0)
                                
                            var startDate = new Date()
                                startDate.setDate(startDate.getDate() - 7) // 7 days ago
                                // Set time to noon to avoid timezone issues
                                startDate.setHours(12, 0, 0, 0)
                            
                            riaService.loadDailyDataRange(
                                selectedProvince.id,
                                selectedStation.code,
                                startDate,
                                endDate,
                                calculateEt0CheckBox.checked
                            )
                        } else if (customRangeRadio.checked) {
                            // Load custom range data
                            if (startDateField.text && endDateField.text) {
                                var customStartDate = new Date(startDateField.text)
                                    // Set time to noon to avoid timezone issues
                                    customStartDate.setHours(12, 0, 0, 0)
                                    
                                var customEndDate = new Date(endDateField.text)
                                    // Set time to noon to avoid timezone issues
                                    customEndDate.setHours(12, 0, 0, 0)
                                
                                riaService.loadDailyDataRange(
                                    selectedProvince.id,
                                    selectedStation.code,
                                    customStartDate,
                                    customEndDate,
                                    calculateEt0CheckBox.checked
                                )
                            } else {
                                isLoading = false
                                errorMessage = "Por favor, introduce fechas de inicio y fin válidas"
                            }
                            }
                        } else {
                            // Monthly data
                            var year = yearComboBox.currentText
                            var month = monthComboBox.currentValue
                            
                            riaService.loadMonthlyData(
                                selectedProvince.id,
                                selectedStation.code,
                                year,
                                month
                            )
                        }
                    }
                }
            }
        }
        
        // Data visualization
        TabBar {
            id: dataTabBar
            Layout.fillWidth: true
            visible: weatherData !== null
            
            TabButton {
                text: "Gráfico"
            }
            
            TabButton {
                text: "Tabla"
            }
        }
        
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: dataTabBar.currentIndex
            visible: weatherData !== null
            
            // Chart tab
            ColumnLayout {
                spacing: 8
                
                // Single chart for all data types
                ChartView {
                    id: dataChart
                    title: "Datos meteorológicos"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    antialiasing: true
                    legend.visible: true
                    legend.alignment: Qt.AlignBottom
                    margins.top: 0
                    margins.bottom: 0
                    margins.left: 0
                    margins.right: 0
                    
                    // Reduce spacing between bars for better mobile display
                    Component.onCompleted: {
                        // Access internal properties to adjust spacing
                        if (dataChart.__plotArea) {
                            dataChart.__plotArea.spacing = 0.1 // Reduce spacing between bars even more
                        }
                    }
                    
                    BarCategoryAxis {
                        id: dataAxisX
                        titleText: "Fecha"
                        labelsFont.pixelSize: 10 // Smaller font for better fit
                        // Categories will be set in updateChartData
                        gridVisible: true
                        minorGridVisible: false
                        labelsAngle: -45 // Angle labels for better readability
                    }
                    
                    ValueAxis {
                        id: dataAxisY
                        min: 0
                        max: 50
                        titleText: "Valor"
                    }
                }
                
                // X-axis legend for mobile
                Label {
                    id: axisLegendLabel
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Los valores en el eje X representan fechas (día/mes)"
                    font.italic: true
                    font.pixelSize: 10
                    color: "#666666"
                    visible: Array.isArray(weatherData) && weatherData.length > 1
                }
                
                // Variable selection buttons
                ButtonGroup { id: variableGroup }
                
                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    RadioButton {
                        text: "Temperatura"
                        checked: selectedVariable === "temperature"
                        ButtonGroup.group: variableGroup
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "temperature"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "Humedad"
                        ButtonGroup.group: variableGroup
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "humidity"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "Radiación"
                        ButtonGroup.group: variableGroup
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "radiation"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "ET0"
                        ButtonGroup.group: variableGroup
                        enabled: !isMonthlyData
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "et0"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "Precipitación"
                        ButtonGroup.group: variableGroup
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "precipitation"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "Integral Térmica"
                        ButtonGroup.group: variableGroup
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "thermal_integral"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "Integral Radiación"
                        ButtonGroup.group: variableGroup
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "radiation_integral"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "ET0 Acumulada"
                        ButtonGroup.group: variableGroup
                        enabled: !isMonthlyData
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "et0_accumulated"
                                updateChartData()
                            }
                        }
                    }
                }
            }
            
            // Table tab
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ListView {
                    id: dataListView
                    anchors.fill: parent
                    model: weatherData !== null ? (Array.isArray(weatherData) ? weatherData : [weatherData]) : []
                    
                    delegate: ItemDelegate {
                        width: dataListView.width
                        height: dataColumn.height + 8
                        
                        ColumnLayout {
                            id: dataColumn
                            width: parent.width - 8
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Label {
                                text: {
                                    var date = new Date(modelData.fecha)
                                    return date.toLocaleDateString()
                                }
                                font.bold: true
                                font.pixelSize: 14
                            }
                            
                            GridLayout {
                                columns: 2
                                columnSpacing: 4
                                rowSpacing: 2
                                Layout.fillWidth: true
                                
                                Label { text: "Temp. Máxima:" }
                                Label { text: modelData.tempMax + " °C" }
                                
                                Label { text: "Temp. Mínima:" }
                                Label { text: modelData.tempMin + " °C" }
                                
                                Label { text: "Temp. Media:" }
                                Label { text: modelData.tempMedia + " °C" }
                                
                                Label { text: "Hum. Máxima:" }
                                Label { text: modelData.humedadMax + " %" }
                                
                                Label { text: "Hum. Mínima:" }
                                Label { text: modelData.humedadMin + " %" }
                                
                                Label { text: "Hum. Media:" }
                                Label { text: modelData.humedadMedia + " %" }
                                
                                Label { text: "Precipitación:" }
                                Label { 
                                    text: {
                                        var precip = 0;
                                        if (modelData.precipitacion !== undefined && modelData.precipitacion !== null) {
                                            if (typeof modelData.precipitacion === 'string') {
                                                precip = parseFloat(modelData.precipitacion.replace(',', '.'));
                                                if (isNaN(precip)) precip = 0;
                                            } else {
                                                precip = Number(modelData.precipitacion);
                                                if (isNaN(precip)) precip = 0;
                                            }
                                        }
                                        return precip.toFixed(1) + " mm";
                                    }
                                }
                                
                                Label { text: "Radiación:" }
                                Label { text: modelData.radiacion + " MJ/m²" }
                                
                                Label { text: "Vel. Viento:" }
                                Label { text: modelData.velViento + " m/s" }
                                
                                Label { text: "ET0:" }
                                Label { 
                                    text: modelData.et0 !== undefined ? modelData.et0.toFixed(2) + " mm" : "N/A"  // Format with 2 decimal places and handle undefined
                                }
                            }
                            
                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: "#DDDDDD"
                                visible: index < dataListView.count - 1
                            }
                        }
                    }
                }
            }
        }
    }
}

