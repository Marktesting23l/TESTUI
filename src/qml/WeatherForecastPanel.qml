import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtCharts 2.3
import Theme
import "." as QFieldItems  // Import local components

Drawer {
    id: weatherForecastPanel
    
    // Add a property to access the position source from the main application
    property var positionSource: null
    
    property bool isLoading: false
    property var forecastData: null
    property string errorMessage: ""
    property bool hasError: errorMessage !== ""
    property double currentLatitude: 0
    property double currentLongitude: 0
    property string locationName: "Ubicación actual"
    
    // Model for daily forecast data
    property ListModel dailyForecastModel: ListModel {}
    
    // Auto-collapse sections on small screens
    property bool isSmallScreen: width < 500
    
    width: parent.width * 0.9
    height: parent.height
    edge: Qt.RightEdge
    
    // Update isSmallScreen when the panel is resized
    onWidthChanged: {
        if (width < 500 && !isSmallScreen) {
            isSmallScreen = true
        } else if (width >= 500 && isSmallScreen) {
            isSmallScreen = false
        }
    }
    
    // Apply theme styling
    Material.elevation: 6
    background: Rectangle {
        color: Theme.mainBackgroundColor
        border.color: Theme.accentColor
        border.width: 1
        radius: 4
    }
    
    // Initialize with default values if needed
    Component.onCompleted: {
        // Initialize the daily forecast model
        dailyForecastModel = Qt.createQmlObject('import QtQuick 2.12; ListModel {}', weatherForecastPanel);
        
        // Set default location to Almeria if no location is specified
        if (currentLatitude === 0 && currentLongitude === 0) {
            currentLatitude = 36.84;
            currentLongitude = -2.46;
            locationName = "Almería";
        }
        
        // Set the location box to expanded by default
        locationBox.expanded = true;
    }
    
    // Function to update the time range of the hourly chart
    function updateHourlyChartTimeRange() {
        if (!forecastData || !forecastData.hourly || !Array.isArray(forecastData.hourly) || forecastData.hourly.length === 0) {
            return;
        }
        
        var hours = timeRangeCombo.model[timeRangeCombo.currentIndex].value;
        console.log("Updating hourly chart time range to " + hours + " hours");
        
        var startTime = forecastData.hourly[0].time;
        
        // Round startTime to the nearest hour
        startTime.setMinutes(0);
        startTime.setSeconds(0);
        startTime.setMilliseconds(0);
        
        var endTime = new Date(startTime);
        endTime.setHours(endTime.getHours() + hours);
        
        hourlyAxisX.min = startTime;
        hourlyAxisX.max = endTime;
        
        // Adjust tick count based on time range to show hours ending in 00
        if (hours <= 24) {
            hourlyAxisX.tickCount = Math.ceil(hours / 4) + 1; // Show every 4 hours
        } else if (hours <= 48) {
            hourlyAxisX.tickCount = Math.ceil(hours / 6) + 1; // Show every 6 hours
        } else if (hours <= 72) {
            hourlyAxisX.tickCount = Math.ceil(hours / 8) + 1; // Show every 8 hours
        } else {
            hourlyAxisX.tickCount = Math.ceil(hours / 12) + 1; // Show every 12 hours
        }
        
        // Update format based on time range
        if (hours > 72) {
            hourlyAxisX.format = "dd/MM HH:00";
        } else {
            hourlyAxisX.format = "HH:00";
        }
    }
    
    // Function to update the hourly chart based on selected variable
    function updateHourlyChart() {
        console.log("updateHourlyChart called")
        
        if (!forecastData || !forecastData.hourly || !Array.isArray(forecastData.hourly) || forecastData.hourly.length === 0) {
            console.log("No forecast data available")
            return;
        }
        
        // Clear existing series
        hourlyChart.removeAllSeries();
        
        var selectedVariable = chartVariableCombo.model[chartVariableCombo.currentIndex].value;
        console.log("Selected variable: " + selectedVariable);
        
        // Create a new line series
        var series = hourlyChart.createSeries(ChartView.SeriesTypeLine, selectedVariable, hourlyAxisX, hourlyAxisY);
        
        // Make the line thicker and set a nice color
        series.width = 3;
        series.color = Theme.accentColor;
        
        // Set up the data for the selected variable
        var minValue = Number.MAX_VALUE;
        var maxValue = Number.MIN_VALUE;
        var hasValidData = false;
        
        for (var i = 0; i < forecastData.hourly.length; i++) {
            var hourData = forecastData.hourly[i];
            var value = hourData[selectedVariable];
            
            // Check if the value is valid (not undefined, null, NaN, Inf, or -Inf)
            if (value !== undefined && value !== null && 
                !isNaN(value) && isFinite(value)) {
                series.append(hourData.time, value);
                
                if (value < minValue) minValue = value;
                if (value > maxValue) maxValue = value;
                hasValidData = true;
            }
        }
        
        // Only set axis range if we have valid data
        if (hasValidData) {
            // Set up the Y axis range with some padding
            var padding = (maxValue - minValue) * 0.1;
            if (padding === 0) padding = 1; // Ensure some padding even if all values are the same
            
            hourlyAxisY.min = minValue - padding;
            hourlyAxisY.max = maxValue + padding;
        } else {
            // Default range if no valid data
            hourlyAxisY.min = 0;
            hourlyAxisY.max = 10;
        }
        
        // Set up the Y axis label based on the selected variable
        if (selectedVariable === "temperature_2m") {
            hourlyAxisY.titleText = "Temperatura (°C)";
        } else if (selectedVariable === "rain") {
            hourlyAxisY.titleText = "Precipitación (mm)";
        } else if (selectedVariable === "precipitation_probability") {
            hourlyAxisY.titleText = "Prob. Precipitación (%)";
        } else if (selectedVariable === "relative_humidity_2m") {
            hourlyAxisY.titleText = "Humedad (%)";
        } else if (selectedVariable === "wind_speed_10m") {
            hourlyAxisY.titleText = "Velocidad Viento (km/h)";
        } else if (selectedVariable === "wind_direction_10m") {
            hourlyAxisY.titleText = "Dirección Viento (°)";
        } else if (selectedVariable === "soil_temperature_0cm") {
            hourlyAxisY.titleText = "Temp. Suelo 0cm (°C)";
        } else if (selectedVariable === "soil_temperature_18cm") {
            hourlyAxisY.titleText = "Temp. Suelo 18cm (°C)";
        } else if (selectedVariable === "soil_moisture_0_1cm") {
            hourlyAxisY.titleText = "Hum. Suelo 0-1cm (m³/m³)";
        } else if (selectedVariable === "soil_moisture_3_9cm") {
            hourlyAxisY.titleText = "Hum. Suelo 3-9cm (m³/m³)";
        } else if (selectedVariable === "surface_pressure") {
            hourlyAxisY.titleText = "Presión (hPa)";
        } else if (selectedVariable === "vapour_pressure_deficit") {
            hourlyAxisY.titleText = "Déficit Presión Vapor (kPa)";
        } else if (selectedVariable === "dewpoint_2m") {
            hourlyAxisY.titleText = "Punto de Rocío (°C)";
        } else if (selectedVariable === "wet_bulb_temperature_2m") {
            hourlyAxisY.titleText = "Temp. Bulbo Húmedo (°C)";
        } else {
            hourlyAxisY.titleText = selectedVariable;
        }
        
        // Update the time range
        updateHourlyChartTimeRange();
    }
    
    // Function to handle when forecast data is loaded
    function onForecastLoaded(data) {
        console.log("Forecast data loaded")
        forecastData = data
        
        // Update the hourly chart
        updateHourlyChart()
        
        // Update the current weather display
        updateCurrentWeather()
        
        // Update the daily forecast
        updateDailyForecast()
        
        // Show the panel
        visible = true
    }
    
    // Create an instance of the Open-Meteo Weather Service
    OpenMeteoWeatherService {
        id: openMeteoService
        
        onForecastLoaded: function(data) {
            forecastData = data
            isLoading = false
            console.log("Forecast data loaded")
        }
        
        onErrorOccurred: function(message) {
            errorMessage = message
            isLoading = false
        }
    }
    
    // Function to load forecast when the panel is opened
    function open() {
        isLoading = true
        errorMessage = ""
        visible = true
        
        // Use the current position if available and no location has been set yet
        if (currentLatitude === 0 && currentLongitude === 0 && 
            positionSource && positionSource.positionInformation && 
            positionSource.positionInformation.latitudeValid && 
            positionSource.positionInformation.longitudeValid) {
            
            currentLatitude = positionSource.positionInformation.latitude;
            currentLongitude = positionSource.positionInformation.longitude;
            locationName = "Mi ubicación";
        }
        
        // Load forecast for the current location
        openMeteoService.loadForecast(currentLatitude, currentLongitude)
    }
    
    // Function to update location and reload forecast
    function updateLocation(latitude, longitude, name) {
        currentLatitude = latitude
        currentLongitude = longitude
        locationName = name || "Ubicación personalizada"
        
        if (visible) {
            isLoading = true
            errorMessage = ""
            openMeteoService.loadForecast(currentLatitude, currentLongitude)
        }
    }
    
    // Function to convert wind direction degrees to text
    function getWindDirectionText(degrees) {
        if (degrees === null || degrees === undefined) return "";
        
        // Define direction ranges
        var directions = [
            { name: "N", min: 348.75, max: 360 },
            { name: "N", min: 0, max: 11.25 },
            { name: "NNE", min: 11.25, max: 33.75 },
            { name: "NE", min: 33.75, max: 56.25 },
            { name: "ENE", min: 56.25, max: 78.75 },
            { name: "E", min: 78.75, max: 101.25 },
            { name: "ESE", min: 101.25, max: 123.75 },
            { name: "SE", min: 123.75, max: 146.25 },
            { name: "SSE", min: 146.25, max: 168.75 },
            { name: "S", min: 168.75, max: 191.25 },
            { name: "SSO", min: 191.25, max: 213.75 },
            { name: "SO", min: 213.75, max: 236.25 },
            { name: "OSO", min: 236.25, max: 258.75 },
            { name: "O", min: 258.75, max: 281.25 },
            { name: "ONO", min: 281.25, max: 303.75 },
            { name: "NO", min: 303.75, max: 326.25 },
            { name: "NNO", min: 326.25, max: 348.75 }
        ];
        
        // Find the matching direction
        for (var i = 0; i < directions.length; i++) {
            var dir = directions[i];
            if (degrees >= dir.min && degrees < dir.max) {
                return dir.name;
            }
        }
        
        return "";
    }
    
    // Function to update the daily forecast
    function updateDailyForecast() {
        console.log("Updating daily forecast")
        
        if (!forecastData || !forecastData.daily || !Array.isArray(forecastData.daily)) {
            console.log("No daily forecast data available")
            return
        }
        
        // Clear existing model
        dailyForecastModel.clear()
        
        // Add data to model
        for (var i = 0; i < forecastData.daily.length; i++) {
            var day = forecastData.daily[i]
            console.log("Day " + i + " weather icon: " + day.weatherIcon)
            
            dailyForecastModel.append({
                date: day.date,
                dayOfWeek: getDayOfWeek(day.date),
                maxTemp: day.temperature_2m_max,
                minTemp: day.temperature_2m_min,
                precipitation: day.precipitation_sum,
                weatherIcon: day.weatherIcon,
                weatherDescription: day.weatherDescription,
                maxWindSpeed: day.wind_speed_10m_max,
                windDirection: day.wind_direction_10m_dominant,
                precipitationHours: day.precipitation_hours
            })
        }
        
        console.log("Daily forecast updated with " + dailyForecastModel.count + " days")
    }
    
    // Function to update the current weather display
    function updateCurrentWeather() {
        console.log("Updating current weather display")
        
        if (!forecastData || !forecastData.current) {
            console.log("No current weather data available")
            return
        }
        
        // Update current weather display
        console.log("Current weather icon path: " + forecastData.current.weatherIcon)
        currentWeatherIcon.source = forecastData.current.weatherIcon
        currentWeatherDescription.text = forecastData.current.weatherDescription
        currentTemperature.text = forecastData.current.temperature.toFixed(1) + "°C"
        
        // Wind information
        currentWindSpeed.text = "Viento: " + forecastData.current.windspeed.toFixed(1) + " km/h"
        currentWindSpeed.visible = forecastData.current.windspeed !== null && forecastData.current.windspeed !== undefined
        
        // Update additional current weather info
        // Humidity (now directly from current data)
        currentHumidity.visible = forecastData.current.humidity !== null && forecastData.current.humidity !== undefined
        if (currentHumidity.visible) {
            currentHumidity.text = "Hum: " + forecastData.current.humidity.toFixed(0) + "%"
        }
        
        // Rain
        var rainVisible = forecastData.current.rain !== null && forecastData.current.rain !== undefined
        if (rainVisible) {
            currentRain.text = "Lluvia: " + forecastData.current.rain.toFixed(1) + " mm"
            currentRain.visible = true
        } else {
            currentRain.visible = false
        }
        
        // Pressure
        var pressureVisible = forecastData.current.pressure !== null && forecastData.current.pressure !== undefined
        if (pressureVisible) {
            currentPressure.text = "Presión: " + forecastData.current.pressure.toFixed(0) + " hPa"
            currentPressure.visible = true
        } else {
            currentPressure.visible = false
        }
        
        console.log("Current weather display updated")
    }
    
    // Helper function to get day of week in Spanish
    function getDayOfWeek(date) {
        var days = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];
        return days[date.getDay()];
    }
    
    // Main content - Make scrollable
    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentColumn.height
        clip: true
        
        ColumnLayout {
            id: contentColumn
            width: scrollView.width
            spacing: 4  // Reduced spacing between elements
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 8
                spacing: 8
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Label {
                        text: "Pronóstico del Tiempo"
                        font.pixelSize: isSmallScreen ? 16 : 18
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: locationName
                        font.pixelSize: isSmallScreen ? 12 : 14
                        color: Theme.accentColor
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "Datos de <a href='https://open-meteo.com/'>Open-Meteo</a>"
                        onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                        font.pixelSize: isSmallScreen ? 10 : 12
                        color: Theme.accentColor
                        Layout.fillWidth: true
                        textFormat: Text.RichText
                    }
                }
                
                Button {
                    text: "Cerrar"
                    icon.source: "qrc:///icons/mActionRemove.svg"
                    Material.background: Theme.mainColor
                    Material.foreground: Theme.buttonTextColor
                    implicitWidth: 80  // Wider button for better readability
                    implicitHeight: 36
                    padding: 4
                    onClicked: weatherForecastPanel.visible = false
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
                Layout.margins: 8
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
                Layout.margins: 8
            }
            
            // Current weather - Compact version
            GroupBox {
                id: currentWeatherBox
                title: "Tiempo Actual"
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                Layout.margins: 8
                visible: forecastData !== null && !isLoading
                padding: 8
                
                background: Rectangle {
                    color: Theme.controlBackgroundColor
                    border.color: Theme.controlBorderColor
                    border.width: 1
                    radius: 4
                    y: parent.topPadding - parent.bottomPadding
                    width: parent.width
                    height: parent.height - parent.topPadding + parent.bottomPadding
                }
                
                label: Label {
                    x: parent.leftPadding
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: parent.title
                    color: Theme.accentColor
                    font.bold: true
                    font.pixelSize: 14
                }
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    // Weather icon
                    Image {
                        id: currentWeatherIcon
                        source: forecastData ? forecastData.current.weatherIcon : ""
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        sourceSize.width: 48
                        sourceSize.height: 48
                        
                        // Fallback icon if the weather icon fails to load
                        onStatusChanged: {
                            if (status === Image.Error) {
                                console.error("Failed to load weather icon: " + source);
                                source = "qrc:/themes/sigpacgo/nodpi/weather.svg";
                            }
                        }
                    }
                    
                    // Weather details - Simplified for mobile
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Label {
                                id: currentWeatherDescription
                                text: forecastData ? forecastData.current.weatherDescription : ""
                                font.bold: true
                                font.pixelSize: 14
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                id: currentTemperature
                                text: forecastData && forecastData.current ? forecastData.current.temperature.toFixed(1) + "°C" : ""
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }
                        
                        // Key weather info in a compact row
                        Flow {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            Label {
                                id: currentWindSpeed
                                text: forecastData && forecastData.current ? "Viento: " + forecastData.current.windspeed.toFixed(1) + " km/h" : ""
                                font.pixelSize: 12
                                visible: forecastData && forecastData.current && forecastData.current.windspeed !== null
                            }
                            
                            Label {
                                id: currentHumidity
                                text: forecastData && forecastData.current ? "Hum: " + forecastData.current.humidity.toFixed(0) + "%" : ""
                                font.pixelSize: 12
                                visible: forecastData && forecastData.current && forecastData.current.humidity !== null
                            }
                            
                            Label {
                                id: currentRain
                                text: forecastData && forecastData.current ? "Lluvia: " + forecastData.current.rain.toFixed(1) + " mm" : ""
                                font.pixelSize: 12
                                visible: forecastData && forecastData.current && forecastData.current.rain !== null
                            }
                            
                            Label {
                                id: currentPressure
                                text: forecastData && forecastData.current ? "Presión: " + forecastData.current.pressure.toFixed(0) + " hPa" : ""
                                font.pixelSize: 12
                                visible: forecastData && forecastData.current && forecastData.current.pressure !== null
                            }
                        }
                    }
                }
            }
            
            // Hourly forecast chart - Increased height
            GroupBox {
                id: hourlyForecastBox
                title: "Pronóstico"
                Layout.fillWidth: true
                Layout.preferredHeight: 310  // Increased height for better visibility
                Layout.margins: 4
                visible: forecastData !== null && !isLoading
                padding: 4
                
                background: Rectangle {
                    color: Theme.controlBackgroundColor
                    border.color: Theme.controlBorderColor
                    border.width: 1
                    radius: 4
                    y: parent.topPadding - parent.bottomPadding
                    width: parent.width
                    height: parent.height - parent.topPadding + parent.bottomPadding
                }
                
                label: RowLayout {
                    x: parent.leftPadding
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    
                    Label {
                        text: parent.parent.title
                        color: Theme.accentColor
                        font.bold: true
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    
                    ComboBox {
                        id: timeRangeCombo
                        Layout.preferredWidth: 120
                        model: [
                            { text: "24 horas", value: 24 },
                            { text: "48 horas", value: 48 },
                            { text: "72 horas", value: 72 },
                            { text: "7 días", value: 168 }
                        ]
                        textRole: "text"
                        currentIndex: 0
                        onCurrentIndexChanged: {
                            updateHourlyChartTimeRange()
                            
                            // Set vertical labels for 7-day view
                            if (currentIndex === 3) { // 7 days option
                                hourlyAxisX.labelsAngle = 90;
                            } else {
                                hourlyAxisX.labelsAngle = 45;
                            }
                        }
                    }
                    
                    ComboBox {
                        id: chartVariableCombo
                        Layout.preferredWidth: 180
                        model: [
                            { text: "Temperatura", value: "temperature_2m" },
                            { text: "Precipitación", value: "rain" },
                            { text: "Prob. Precipitación", value: "precipitation_probability" },
                            { text: "Humedad", value: "relative_humidity_2m" },
                            { text: "Viento", value: "wind_speed_10m" },
                            { text: "Dir. Viento", value: "wind_direction_10m" },
                            { text: "Temp. Suelo 0cm", value: "soil_temperature_0cm" },
                            { text: "Temp. Suelo 18cm", value: "soil_temperature_18cm" },
                            { text: "Hum. Suelo 0-1cm", value: "soil_moisture_0_1cm" },
                            { text: "Hum. Suelo 3-9cm", value: "soil_moisture_3_9cm" },
                            { text: "Presión", value: "surface_pressure" },
                            { text: "Déficit Presión Vapor", value: "vapour_pressure_deficit" },
                            { text: "Punto de Rocío", value: "dewpoint_2m" },
                            { text: "Temp. Bulbo Húmedo", value: "wet_bulb_temperature_2m" }
                        ]
                        textRole: "text"
                        currentIndex: 0
                        onCurrentIndexChanged: {
                            updateHourlyChart()
                        }
                    }
                }
                
                // Container for the chart to ensure proper positioning
                Item {
                    anchors.fill: parent
                    anchors.topMargin: 5  // Space for the combo boxes
                    anchors.bottomMargin: 2
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    
                    ChartView {
                        id: hourlyChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"
                        
                        // Set margins to 0 to maximize chart area
                        margins {
                            top: 0
                            bottom: 0
                            left: 0
                            right: 0
                        }
                        
                        // Add a border to make the chart more visible
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Theme.controlBorderColor
                            border.width: 1
                            z: -1
                        }
                        
                        DateTimeAxis {
                            id: hourlyAxisX
                            format: "HH:00"  // Fixed to show hours ending in 00
                            tickCount: 6
                            labelsFont.pixelSize: 10
                            gridVisible: true
                            minorGridVisible: false
                            titleText: "Hora"
                            titleFont.pixelSize: 12
                            titleFont.bold: true
                            labelsAngle: 45  // Rotate labels by 45 degrees
                            labelsColor: Theme.mainTextColor
                            gridLineColor: Theme.controlBorderColor
                        }
                        
                        ValueAxis {
                            id: hourlyAxisY
                            labelsFont.pixelSize: 10
                            gridVisible: true
                            minorGridVisible: false
                            titleText: "Temperatura (°C)"
                            titleFont.pixelSize: 12
                            titleFont.bold: true
                            labelsColor: Theme.mainTextColor
                            gridLineColor: Theme.controlBorderColor
                        }
                    }
                }
                
                // Update chart when forecast data changes
                Connections {
                    target: weatherForecastPanel
                    function onForecastDataChanged() {
                        if (forecastData) {
                            updateHourlyChart()
                            
                            // Set vertical labels for 7-day view
                            if (timeRangeCombo.currentIndex === 3) { // 7 days option
                                hourlyAxisX.labelsAngle = 90;
                            } else {
                                hourlyAxisX.labelsAngle = 45;
                            }
                        }
                    }
                }
            }
            
            // Daily forecast - Horizontal list
            ListView {
                id: dailyForecastList
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                Layout.margins: 8
                visible: forecastData !== null && !isLoading && dailyForecastModel.count > 0
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                model: dailyForecastModel
                
                delegate: Rectangle {
                    width: 100
                    height: dailyForecastList.height
                    color: Theme.controlBackgroundAlternateColor
                    border.color: Theme.controlBorderColor
                    border.width: 1
                    radius: 4
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2
                        
                        Label {
                            text: model.dayOfWeek
                            font.bold: true
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            color: Theme.mainTextColor
                        }
                        
                        Image {
                            source: model.weatherIcon
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                            sourceSize.width: 40
                            sourceSize.height: 40
                            
                            // Fallback icon if the weather icon fails to load
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    console.error("Failed to load daily weather icon: " + source);
                                    source = "qrc:/themes/sigpacgo/nodpi/weather.svg";
                                }
                            }
                        }
                        
                        Label {
                            text: model.weatherDescription
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            color: Theme.mainTextColor
                        }
                        
                        Label {
                            text: model.maxTemp.toFixed(1) + "° / " + model.minTemp.toFixed(1) + "°"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            color: Theme.mainTextColor
                        }
                        
                        Label {
                            text: model.precipitation > 0 ? model.precipitation.toFixed(1) + " mm" : ""
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            visible: model.precipitation > 0
                            color: Theme.mainTextColor
                        }
                    }
                }
            }
            
            GroupBox {
                id: locationBox
                title: "Ubicación"
                Layout.fillWidth: true
                Layout.preferredHeight: locationBox.expanded ? 180 : 40
                Layout.margins: 2
                
                property bool expanded: true  // Set to true by default
                
                background: Rectangle {
                    color: Theme.controlBackgroundColor
                    border.color: Theme.controlBorderColor
                    border.width: 1
                    radius: 4
                    y: parent.topPadding - parent.bottomPadding
                    width: parent.width
                    height: parent.height - parent.topPadding + parent.bottomPadding
                }
                
                label: RowLayout {
                    x: parent.leftPadding
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: parent.topPadding
                    
                    Label {
                        text: parent.parent.title
                        color: Theme.accentColor
                        font.bold: true
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillWidth: true
                    }
                    
                    Button {
                        text: locationBox.expanded ? "▲" : "▼"
                        flat: true
                        padding: 2
                        implicitWidth: 24
                        implicitHeight: 24
                        onClicked: locationBox.expanded = !locationBox.expanded
                    }
                }
                
                GridLayout {
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 8
                    anchors.fill: parent
                    visible: locationBox.expanded
                    
                    Label { text: "Latitud:" }
                    TextField {
                        id: latitudeField
                        Layout.fillWidth: true
                        placeholderText: "Ej: 37.38"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        text: currentLatitude.toString()
                    }
                    
                    Label { text: "Longitud:" }
                    TextField {
                        id: longitudeField
                        Layout.fillWidth: true
                        placeholderText: "Ej: -5.97"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        text: currentLongitude.toString()
                    }
                    
                    Label { text: "Nombre:" }
                    TextField {
                        id: locationNameField
                        Layout.fillWidth: true
                        placeholderText: "Nombre de la ubicación"
                        text: locationName
                    }
                    
                    Button {
                        text: "Ubicación actual"
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Material.background: Theme.accentColor
                        Material.foreground: Theme.buttonTextColor
                        onClicked: {
                            // Use the positioning system to get the current location
                            if (positionSource && positionSource.positionInformation && 
                                positionSource.positionInformation.latitudeValid && 
                                positionSource.positionInformation.longitudeValid) {
                                
                                latitudeField.text = positionSource.positionInformation.latitude.toFixed(6);
                                longitudeField.text = positionSource.positionInformation.longitude.toFixed(6);
                                locationNameField.text = "Mi ubicación";
                                
                                // Update the forecast immediately
                                var lat = parseFloat(latitudeField.text);
                                var lon = parseFloat(longitudeField.text);
                                var name = locationNameField.text;
                                
                                if (!isNaN(lat) && !isNaN(lon)) {
                                    updateLocation(lat, lon, name);
                                }
                            } else {
                                // Fallback to Almería if positioning is not available
                                latitudeField.text = "36.84";
                                longitudeField.text = "-2.46";
                                locationNameField.text = "Almería";
                                
                                // Show a message to the user
                                errorMessage = "No se pudo obtener la ubicación actual. Usando ubicación predeterminada.";
                                
                                // Update the forecast with the default location
                                updateLocation(36.84, -2.46, "Almería");
                            }
                        }
                    }
                    
                    Button {
                        text: "Actualizar"
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Material.background: Theme.mainColor
                        Material.foreground: Theme.buttonTextColor
                        enabled: !isLoading
                        onClicked: {
                            var lat = parseFloat(latitudeField.text)
                            var lon = parseFloat(longitudeField.text)
                            var name = locationNameField.text
                            
                            if (!isNaN(lat) && !isNaN(lon)) {
                                updateLocation(lat, lon, name)
                            } else {
                                errorMessage = "Por favor, introduce coordenadas válidas"
                            }
                        }
                    }
                }
            }
        }
    }
} 