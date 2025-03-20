import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtCharts 2.3
import QtPositioning 5.12
import "imports/Theme" as AppTheme

Drawer {
    id: weatherDataPanel
    
    property bool isLoading: false
    property var selectedProvince: null
    property var selectedStation: null
    property var weatherData: null
    property string errorMessage: ""
    property bool hasError: errorMessage !== ""
    
    signal zoomToStation(double latitude, double longitude)
    
    // List of Andalucía provinces IDs
    property var andaluciaProvinceIds: [4, 11, 14, 18, 21, 23, 29, 41] // Almería, Cádiz, Córdoba, Granada, Huelva, Jaén, Málaga, Sevilla
    
    // Selected variable for chart display
    property string selectedVariable: "temperature" // Default to temperature
    
    // Auto-collapse sections on small screens
    property bool isSmallScreen: width < 500
    
    // Property to store user's current position
    property double userLatitude: 0
    property double userLongitude: 0
    
    // Property to track if we've already found the nearest station
    property bool hasFoundNearestStation: false
    
    // Hardcoded station coordinates from the TSV file
    property var stationCoordinates: [
        // Almería
        { provinceId: 4, code: "1", name: "La Mojonera", latitude: 36.7856, longitude: -2.7042 },
        { provinceId: 4, code: "2", name: "Almería", latitude: 36.8353, longitude: -2.4022 },
        { provinceId: 4, code: "4", name: "Tabernas", latitude: 37.0911, longitude: -2.3022 },
        { provinceId: 4, code: "5", name: "Fiñana", latitude: 37.1567, longitude: -2.8386 },
        { provinceId: 4, code: "6", name: "Virgen de Fátima-Cuevas de Almanzora", latitude: 37.3889, longitude: -1.7703 },
        { provinceId: 4, code: "7", name: "Huércal-Overa", latitude: 37.4122, longitude: -1.8842 },
        { provinceId: 4, code: "8", name: "Cuevas de Almanzora", latitude: 37.2567, longitude: -1.8003 },
        { provinceId: 4, code: "10", name: "Adra", latitude: 36.7467, longitude: -3.0089 },
        { provinceId: 4, code: "11", name: "Níjar", latitude: 36.9506, longitude: -2.1581 },
        { provinceId: 4, code: "12", name: "Tíjola", latitude: 37.3783, longitude: -2.4594 },
        // Cádiz
        { provinceId: 11, code: "1", name: "Basurta-Jerez de la Frontera", latitude: 36.7569, longitude: -6.0172 },
        { provinceId: 11, code: "2", name: "Jerez de la Frontera", latitude: 36.6425, longitude: -6.0133 },
        { provinceId: 11, code: "4", name: "Villamartín", latitude: 36.8431, longitude: -5.6236 },
        { provinceId: 11, code: "5", name: "Conil de la Frontera", latitude: 36.3328, longitude: -6.1325 },
        { provinceId: 11, code: "6", name: "Vejer de la Frontera", latitude: 36.2850, longitude: -5.8400 },
        { provinceId: 11, code: "7", name: "Jimena de la Frontera", latitude: 36.4136, longitude: -5.3836 },
        { provinceId: 11, code: "10", name: "Puerto de Santa María", latitude: 36.6044, longitude: -6.1715 },
        { provinceId: 11, code: "11", name: "Sanlúcar de Barrameda", latitude: 36.7189, longitude: -6.3300 },
        { provinceId: 11, code: "101", name: "IFAPA Centro de Chipiona", latitude: 36.7508, longitude: -6.3997 },
        // Córdoba
        { provinceId: 14, code: "1", name: "Belmez", latitude: 38.2542, longitude: -5.2094 },
        { provinceId: 14, code: "3", name: "Palma del Río", latitude: 37.7256, longitude: -5.2269 },
        { provinceId: 14, code: "4", name: "Hornachuelos", latitude: 37.7197, longitude: -5.1600 },
        { provinceId: 14, code: "5", name: "El Carpio", latitude: 37.9139, longitude: -4.5039 },
        { provinceId: 14, code: "6", name: "Córdoba", latitude: 37.8569, longitude: -4.8028 },
        { provinceId: 14, code: "7", name: "Santaella", latitude: 37.5222, longitude: -4.8853 },
        { provinceId: 14, code: "8", name: "Baena", latitude: 37.6914, longitude: -4.3058 },
        { provinceId: 14, code: "9", name: "Palma del Rio", latitude: 37.7256, longitude: -5.2269 },
        { provinceId: 14, code: "101", name: "IFAPA Centro de Cabra", latitude: 37.4981, longitude: -4.4308 },
        { provinceId: 14, code: "102", name: "IFAPA Centro de Hinojosa del Duque", latitude: 38.4961, longitude: -5.1153 },
        // Granada
        { provinceId: 18, code: "1", name: "Baza", latitude: 37.5644, longitude: -2.7675 },
        { provinceId: 18, code: "2", name: "Puebla de Don Fadrique", latitude: 37.8758, longitude: -2.3817 },
        { provinceId: 18, code: "3", name: "Loja", latitude: 37.1692, longitude: -4.1381 },
        { provinceId: 18, code: "5", name: "Iznalloz", latitude: 37.4164, longitude: -3.5514 },
        { provinceId: 18, code: "6", name: "Jerez del Marquesado", latitude: 37.1903, longitude: -3.1497 },
        { provinceId: 18, code: "7", name: "Cádiar", latitude: 36.9231, longitude: -3.1839 },
        { provinceId: 18, code: "8", name: "Zafarraya", latitude: 36.9903, longitude: -4.1536 },
        { provinceId: 18, code: "10", name: "Padul", latitude: 37.0186, longitude: -3.6003 },
        { provinceId: 18, code: "11", name: "Almuñecar", latitude: 36.7517, longitude: -3.6789 },
        { provinceId: 18, code: "12", name: "Pinos Puente Casanueva", latitude: 37.2419, longitude: -3.7856 },
        { provinceId: 18, code: "101", name: "IFAPA Centro Camino del Purchil", latitude: 37.1719, longitude: -3.6383 },
        { provinceId: 18, code: "102", name: "Huéneja", latitude: 37.2150, longitude: -2.9635 },
        // Huelva
        { provinceId: 21, code: "3", name: "Gibraleón", latitude: 37.4122, longitude: -7.0597 },
        { provinceId: 21, code: "5", name: "Niebla", latitude: 37.3469, longitude: -6.7353 },
        { provinceId: 21, code: "6", name: "Aroche", latitude: 37.9581, longitude: -6.9450 },
        { provinceId: 21, code: "7", name: "La Puebla de Guzmán", latitude: 37.5519, longitude: -7.2483 },
        { provinceId: 21, code: "8", name: "El Campillo", latitude: 37.6608, longitude: -6.5992 },
        { provinceId: 21, code: "9", name: "La Palma del Condado", latitude: 37.3669, longitude: -6.5414 },
        { provinceId: 21, code: "10", name: "Almonte", latitude: 37.1481, longitude: -6.4764 },
        { provinceId: 21, code: "11", name: "Gibraleón - Manzorrales", latitude: 37.3089, longitude: -7.0154 },
        { provinceId: 21, code: "12", name: "Moguer El Fresno", latitude: 37.1916, longitude: -6.8383 },
        { provinceId: 21, code: "101", name: "IFAPA Centro Huelva. Finca El Cebollar", latitude: 37.2403, longitude: -6.8022 },
        // Jaén
        { provinceId: 23, code: "1", name: "Huesa", latitude: 37.7472, longitude: -3.0617 },
        { provinceId: 23, code: "2", name: "Pozo Alcón", latitude: 37.6717, longitude: -2.9300 },
        { provinceId: 23, code: "3", name: "San José de los Propios", latitude: 37.8578, longitude: -3.2303 },
        { provinceId: 23, code: "4", name: "Sabiote", latitude: 38.0794, longitude: -3.2353 },
        { provinceId: 23, code: "5", name: "Torreblascopedro", latitude: 37.9886, longitude: -3.6892 },
        { provinceId: 23, code: "6", name: "Alcaudete", latitude: 37.5772, longitude: -4.0783 },
        { provinceId: 23, code: "7", name: "Mancha Real", latitude: 37.9164, longitude: -3.5964 },
        { provinceId: 23, code: "8", name: "Ubeda", latitude: 37.9428, longitude: -3.3003 },
        { provinceId: 23, code: "11", name: "Chiclana de Segura", latitude: 38.3028, longitude: -2.9964 },
        { provinceId: 23, code: "12", name: "La Higuera de Arjona", latitude: 37.9486, longitude: -4.0075 },
        { provinceId: 23, code: "14", name: "Santo Tomé", latitude: 38.0292, longitude: -3.0828 },
        { provinceId: 23, code: "15", name: "Jaén", latitude: 37.8906, longitude: -3.7711 },
        { provinceId: 23, code: "16", name: "Marmolejo", latitude: 38.0489, longitude: -4.1825 },
        { provinceId: 23, code: "17", name: "Linares", latitude: 38.0840, longitude: -3.5746 },
        { provinceId: 23, code: "101", name: "Torreperogil", latitude: 38.0242, longitude: -3.2439 },
        { provinceId: 23, code: "102", name: "Villacarrillo", latitude: 38.0633, longitude: -3.2003 },
        { provinceId: 23, code: "103", name: "Jódar", latitude: 37.8783, longitude: -3.3342 },
        { provinceId: 23, code: "104", name: "IFAPA Centro Mengibar", latitude: 37.9408, longitude: -3.7875 },
        // Málaga
        { provinceId: 29, code: "1", name: "Málaga", latitude: 36.7564, longitude: -4.5375 },
        { provinceId: 29, code: "2", name: "Vélez-Málaga", latitude: 36.7958, longitude: -4.1314 },
        { provinceId: 29, code: "4", name: "Estepona", latitude: 36.4444, longitude: -5.2097 },
        { provinceId: 29, code: "6", name: "Sierra Yeguas", latitude: 37.1383, longitude: -4.8358 },
        { provinceId: 29, code: "7", name: "IFAPA Churriana", latitude: 36.6736, longitude: -4.5031 },
        { provinceId: 29, code: "8", name: "Pizarra", latitude: 36.7667, longitude: -4.7150 },
        { provinceId: 29, code: "9", name: "Cártama", latitude: 36.7167, longitude: -4.6781 },
        { provinceId: 29, code: "10", name: "Antequera", latitude: 37.0342, longitude: -4.5625 },
        { provinceId: 29, code: "11", name: "Archidona", latitude: 37.1039, longitude: -4.4183 },
        { provinceId: 29, code: "101", name: "IFAPA Centro de Campanillas", latitude: 36.7289, longitude: -4.5606 },
        // Sevilla
        { provinceId: 41, code: "3", name: "Lebrija I", latitude: 36.9764, longitude: -6.1261 },
        { provinceId: 41, code: "5", name: "Aznalcázar", latitude: 37.1517, longitude: -6.2733 },
        { provinceId: 41, code: "7", name: "La Puebla del Río", latitude: 37.2258, longitude: -6.1336 },
        { provinceId: 41, code: "8", name: "La Puebla del Río II", latitude: 37.0800, longitude: -6.0464 },
        { provinceId: 41, code: "9", name: "Ecija", latitude: 37.5928, longitude: -5.0769 },
        { provinceId: 41, code: "10", name: "La Luisiana", latitude: 37.5250, longitude: -5.2281 },
        { provinceId: 41, code: "11", name: "Osuna", latitude: 37.2550, longitude: -5.1347 },
        { provinceId: 41, code: "12", name: "La Rinconada", latitude: 37.4567, longitude: -5.9247 },
        { provinceId: 41, code: "13", name: "Sanlúcar La Mayor", latitude: 37.4217, longitude: -6.2550 },
        { provinceId: 41, code: "15", name: "Lora del Río", latitude: 37.6608, longitude: -5.5406 },
        { provinceId: 41, code: "16", name: "Los Molares", latitude: 37.1761, longitude: -5.6728 },
        { provinceId: 41, code: "17", name: "Guillena", latitude: 37.5144, longitude: -6.0642 },
        { provinceId: 41, code: "18", name: "Puebla Cazalla", latitude: 37.2181, longitude: -5.3508 },
        { provinceId: 41, code: "19", name: "IFAPA Centro Las Torres-Tomejil", latitude: 37.5125, longitude: -5.9639 },
        { provinceId: 41, code: "20", name: "Isla Mayor", latitude: 37.1136, longitude: -6.1211 },
        { provinceId: 41, code: "21", name: "IFAPA Centro de Los Palacios", latitude: 37.1861, longitude: -5.9458 },
        { provinceId: 41, code: "22", name: "Villanueva del Río y Minas", latitude: 37.5925, longitude: -5.6886 },
        { provinceId: 41, code: "101", name: "IFAPA Centro Las Torres-Tomejil. Finca Tomejil", latitude: 37.4008, longitude: -5.5875 }
    ]
    
    PositionSource {
        id: positionSource
        active: false
        updateInterval: 1000
        preferredPositioningMethods: PositionSource.AllPositioningMethods
        
        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                userLatitude = position.coordinate.latitude
                userLongitude = position.coordinate.longitude
                console.log("Position updated: " + userLatitude + ", " + userLongitude)
            }
        }
    }
    
    width: parent.width * 0.9
    height: parent.height
    edge: Qt.RightEdge
    
    // Function to find the nearest station to the user's location
    function findNearestStation() {
        // Reset the flag when manually requesting to find nearest station
        hasFoundNearestStation = false
        
        // Check if we have user's position
        if (userLatitude === 0 && userLongitude === 0) {
            // Try to get user's position
            if (positionSource) {
                positionSource.update();
                if (positionSource.position.latitudeValid && positionSource.position.longitudeValid) {
                    userLatitude = positionSource.position.coordinate.latitude;
                    userLongitude = positionSource.position.coordinate.longitude;
                } else {
                    // Default to center of Andalucía if position is not available
                    userLatitude = 37.5;
                    userLongitude = -4.7;
                    errorMessage = "No se pudo obtener tu ubicación. Usando ubicación predeterminada en el centro de Andalucía.";
                }
            } else {
                // Default to center of Andalucía if position source is not available
                userLatitude = 37.5;
                userLongitude = -4.7;
                errorMessage = "No se pudo obtener tu ubicación. Usando ubicación predeterminada en el centro de Andalucía.";
            }
        }
        
        // Find the nearest station
        var nearestDistance = Number.MAX_VALUE;
        var nearestStation = null;
        var nearestProvinceId = 0;
        
        for (var i = 0; i < stationCoordinates.length; i++) {
            var station = stationCoordinates[i];
            var distance = calculateDistance(
                userLatitude, userLongitude,
                station.latitude, station.longitude
            );
            
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestStation = station;
                nearestProvinceId = station.provinceId;
            }
        }
        
        if (nearestStation) {
            console.log("Nearest station: " + nearestStation.name + 
                       " (ID: " + nearestStation.code + ")" +
                       " in province: " + nearestProvinceId +
                       " at distance: " + nearestDistance.toFixed(2) + " km");
            
            // Select the province first
            for (var j = 0; j < provincesModel.count; j++) {
                if (provincesModel.get(j).id === nearestProvinceId) {
                    provinceComboBox.currentIndex = j;
                    selectedProvince = provincesModel.get(j);
                    break;
                }
            }
            
            // Load stations for this province
            isLoading = true;
            errorMessage = "";
            riaService.loadStations(nearestProvinceId);
            
            // Set a timer to select the station after stations are loaded
            var selectStationTimer = Qt.createQmlObject(
                'import QtQuick 2.12; Timer {interval: 1000; repeat: false; running: true;}', 
                weatherDataPanel
            );
            
            selectStationTimer.triggered.connect(function() {
                // Find the station in the model
                for (var k = 0; k < stationsModel.count; k++) {
                    if (stationsModel.get(k).code === nearestStation.code) {
                        stationComboBox.currentIndex = k;
                        selectedStation = stationsModel.get(k);
                        hasFoundNearestStation = true;
                        break;
                    }
                }
                
                // If we found the station, load its data
                if (selectedStation) {
                    // Load data for the last day
                    var twoDaysAgo = new Date();
                    twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
                    twoDaysAgo.setHours(12, 0, 0, 0);
                    
                    isLoading = true;
                    riaService.loadDailyData(
                        selectedProvince.id,
                        selectedStation.code,
                        twoDaysAgo,
                        calculateEt0CheckBox.checked
                    );
                }
            });
        } else {
            errorMessage = "No se pudo encontrar una estación cercana.";
        }
    }
    
    // Function to calculate distance between two coordinates using Haversine formula
    function calculateDistance(lat1, lon1, lat2, lon2) {
        var R = 6371; // Radius of the earth in km
        var dLat = deg2rad(lat2 - lat1);
        var dLon = deg2rad(lon2 - lon1);
        var a = 
            Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
            Math.sin(dLon/2) * Math.sin(dLon/2); 
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
        var d = R * c; // Distance in km
        return d;
    }
    
    // Helper function to convert degrees to radians
    function deg2rad(deg) {
        return deg * (Math.PI/180);
    }
    
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
        color: AppTheme.Theme.mainBackgroundColor
        border.color: AppTheme.Theme.accentColor
        border.width: 1
        radius: 4
    }
    
    RIAWeatherService {
        id: riaService
        
        onProvincesLoaded: function(provinces) {
            provincesModel.clear()
            // Only add the 8 provinces of Andalucía
            provinces.forEach(function(province) {
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
            var totalStations = 0;
            var activeStations = 0;
            var inactiveStations = 0;
            var greenhouseStations = 0;
            
            console.log("Processing " + (stations ? stations.length : 0) + " stations from API");
            
            stations.forEach(function(station) {
                totalStations++;
                
                // Check if station is active and not bajo plastico
                // Handle both string and boolean values
                var isActive = station.activa === true || station.activa === "Si";
                var isGreenhouse = station.bajoPlastico === true || station.bajoPlastico === "Si" || 
                                  station.bajoplastico === true || station.bajoplastico === "Si";
                
                // Log station details for debugging
                console.log("Station: " + station.nombre + 
                           " (ID: " + station.codigoEstacion + ")" +
                           " - Active: " + isActive + 
                           " - Greenhouse: " + isGreenhouse);
                
                if (!isActive) {
                    inactiveStations++;
                }
                
                if (isGreenhouse) {
                    greenhouseStations++;
                }
                
                // Only add active stations and exclude "bajo plastico" stations
                if (isActive && !isGreenhouse) {
                    activeStations++;
                    stationsModel.append({
                        code: station.codigoEstacion,
                        name: station.nombre,
                        latitude: station.latitud,
                        longitude: station.longitud,
                        altitude: station.altitud
                    })
                }
            })
            
            console.log("Filtered stations: " + activeStations + " active non-greenhouse stations out of " + totalStations + " total stations");
            console.log("Excluded: " + inactiveStations + " inactive stations, " + greenhouseStations + " greenhouse stations");
            
            // Show a message if there are no active stations
            if (activeStations === 0 && totalStations > 0) {
                errorMessage = "No hay estaciones activas disponibles para esta provincia. Se han excluido estaciones inactivas o bajo plástico.";
            }
            
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
        // Further reduce padding to create more space
        anchors.margins: 0
        spacing: 0
        
        // Header - Reduced size
        RowLayout {
            Layout.fillWidth: true
            spacing: 1
            
            Image {
                source: "qrc:/images/andalucia-logo.svg"
                width: 24
                height: 24
                Layout.leftMargin: 4
                Layout.alignment: Qt.AlignVCenter
                
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Layout.leftMargin: 4
            
                Label {
                    text: "Estaciones RIA"
                    font.pixelSize: 11
                    font.bold: true
                    Layout.fillWidth: true
                    color: AppTheme.Theme.mainTextColor
                }
                
                Label {
                    text: "<a href='https://www.juntadeandalucia.es/agriculturaypesca/ifapa/riaweb/web/estaciones'>IFAPA Junta de Andalucía</a>"
                    font.pixelSize: isSmallScreen ? 10 : 12
                    Layout.fillWidth: true
                    onLinkActivated: Qt.openUrlExternally(link)
                    color: AppTheme.Theme.accentColor
                }
            }
            
            // Nearest station button
            Button {
                text: "Más cercana"
                Material.background: AppTheme.Theme.accentColor
                Material.foreground: AppTheme.Theme.buttonTextColor
                implicitWidth: 120
                implicitHeight: 40
                padding: 0
                onClicked: {
                    positionSource.active = true
                    findNearestStation()
                }
                ToolTip.visible: hovered
                ToolTip.text: "Cargar la estación meteorológica más cercana a tu ubicación"
            }
            

            
            Button {
                text: "Cerrar"
                Material.background: AppTheme.Theme.mainColor
                Material.foreground: AppTheme.Theme.buttonTextColor
                implicitWidth: 70
                implicitHeight: 40
                padding: 0
                onClicked: weatherDataPanel.visible = false
            }
        }
        
        // Error message
        Rectangle {
            visible: hasError
            color: "#FFEBEE"
            border.color: AppTheme.Theme.errorColor
            border.width: 1
            radius: 4
            Layout.fillWidth: true
            height: errorLabel.height + 16
            
            Label {
                id: errorLabel
                text: errorMessage
                color: AppTheme.Theme.errorColor
                anchors.centerIn: parent
                anchors.margins: 8
                wrapMode: Text.WordWrap
                width: parent.width - 16
            }
        }
        
        BusyIndicator {
            visible: isLoading
            running: isLoading
            Layout.alignment: Qt.AlignHCenter
        }
        
        GroupBox {
            id: selectionGroupBox
            title: "Selección (otras comunidades próximamente"
            Layout.fillWidth: true
            padding: 0
            
            property bool expanded: true 
            
            background: Rectangle {
                color: AppTheme.Theme.controlBackgroundColor
                border.color: AppTheme.Theme.controlBorderColor
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
                    color: AppTheme.Theme.accentColor
                    font.bold: true
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
                
                Button {
                    text: selectionGroupBox.expanded ? "▲" : "▼"
                    flat: true
                    padding: 0
                    implicitWidth: 20
                    implicitHeight: 20
                    onClicked: selectionGroupBox.expanded = !selectionGroupBox.expanded
                }
            }
            
            GridLayout {
                columns: 2
                rowSpacing: 1
                columnSpacing: 1
                anchors.fill: parent
                visible: selectionGroupBox.expanded
                
                Label { 
                    text: "Provincia:" 
                    font.pixelSize: 10
                    color: AppTheme.Theme.mainTextColor
                }
                ComboBox {
                    id: provinceComboBox
                    Layout.fillWidth: true
                    model: provincesModel
                    textRole: "name"
                    valueRole: "id"
                    enabled: !isLoading && provincesModel.count > 0
                    font.pixelSize: 10
                    
                    onActivated: {
                        selectedProvince = provincesModel.get(currentIndex)
                        selectedStation = null
                        isLoading = true
                        errorMessage = ""
                        riaService.loadStations(selectedProvince.id)
                    }
                }
                
                Label { 
                    text: "Estación:" 
                    font.pixelSize: 10
                    color: AppTheme.Theme.mainTextColor
                }
                ComboBox {
                    id: stationComboBox
                    Layout.fillWidth: true
                    model: stationsModel
                    textRole: "name"
                    valueRole: "code"
                    enabled: !isLoading && stationsModel.count > 0 && selectedProvince !== null
                    font.pixelSize: 10
                    
                    onActivated: {
                        selectedStation = stationsModel.get(currentIndex)
                    }
                }
            }
        }
        
        // Date selection - Always visible by default
        GroupBox {
            id: periodGroupBox
            title: "Periodo (otras comunidades próximamente)"
            Layout.fillWidth: true
            enabled: selectedStation !== null
            padding: 0
            
            property bool expanded: true 
            
            background: Rectangle {
                color: AppTheme.Theme.controlBackgroundColor
                border.color: AppTheme.Theme.controlBorderColor
                border.width: 1
                radius: 4
                y: parent.topPadding - parent.bottomPadding
                width: parent.width
                height: parent.height - parent.topPadding + parent.bottomPadding
                opacity: parent.enabled ? 1.0 : 0.6
            }
            
            label: RowLayout {
                x: parent.leftPadding
                width: parent.width - parent.leftPadding - parent.rightPadding
                height: parent.topPadding
                opacity: parent.parent.enabled ? 1.0 : 0.6
                
                Label {
                    text: parent.parent.title
                    color: AppTheme.Theme.accentColor
                    font.bold: true
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
                
                Button {
                    text: periodGroupBox.expanded ? "▲" : "▼"
                    flat: true
                    padding: 0
                    implicitWidth: 20
                    implicitHeight: 20
                    onClicked: periodGroupBox.expanded = !periodGroupBox.expanded
                    enabled: parent.parent.parent.enabled
                }
            }
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 1
                visible: periodGroupBox.expanded
                
                // Data type selection
                ButtonGroup { id: dataTypeGroup }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                
                    RadioButton {
                        id: dailyDataRadio
                        text: "Datos diarios"
                        checked: true
                        ButtonGroup.group: dataTypeGroup
                        padding: 0
                        font.pixelSize: 10
                    }
                    
                    RadioButton {
                        id: monthlyDataRadio
                        text: "Datos mensuales"
                        ButtonGroup.group: dataTypeGroup
                        padding: 0
                        font.pixelSize: 10
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
                    spacing: 0
                    visible: dailyDataRadio.checked
                    
                    ButtonGroup { id: dailyPeriodGroup }
                    
                    // Put all options in a single row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        
                        RadioButton {
                            id: lastDataDayRadio
                            text: "Último día"
                            checked: true
                            ButtonGroup.group: dailyPeriodGroup
                            padding: 0
                            font.pixelSize: 10
                        }
                        
                        RadioButton {
                            id: yesterdayRadio
                            text: "14 días"
                            ButtonGroup.group: dailyPeriodGroup
                            padding: 0
                            font.pixelSize: 10
                        }
                
                        RadioButton {
                            id: last7DaysRadio
                            text: "7 días"
                            ButtonGroup.group: dailyPeriodGroup
                            padding: 0
                            font.pixelSize: 10
                        }
                
                        RadioButton {
                            id: customRangeRadio
                            text: "Rango"
                            ButtonGroup.group: dailyPeriodGroup
                            padding: 0
                            font.pixelSize: 10
                        }
                    }
                
                    GridLayout {
                        columns: 4
                        Layout.fillWidth: true
                        visible: customRangeRadio.checked
                        rowSpacing: 0
                        columnSpacing: 1
                    
                        Label { 
                            text: "Inicio:" 
                            font.pixelSize: 10
                        }
                        TextField {
                            id: startDateField
                            Layout.fillWidth: true
                            placeholderText: "YYYY-MM-DD"
                            inputMethodHints: Qt.ImhDate
                            font.pixelSize: 10
                        }
                    
                        Label { 
                            text: "Fin:" 
                            font.pixelSize: 10
                        }
                        TextField {
                            id: endDateField
                            Layout.fillWidth: true
                            placeholderText: "YYYY-MM-DD"
                            inputMethodHints: Qt.ImhDate
                            font.pixelSize: 10
                        }
                    }
                }
                
                // Monthly data options
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    visible: monthlyDataRadio.checked
                    
                    GridLayout {
                        columns: 4
                        Layout.fillWidth: true
                        rowSpacing: 0
                        columnSpacing: 1
                        
                        Label { 
                            text: "Año:" 
                            font.pixelSize: 10
                        }
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
                            font.pixelSize: 10
                        }
                        
                        Label { 
                            text: "Mes:" 
                            font.pixelSize: 10
                        }
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
                            font.pixelSize: 10
                            
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
                    padding: 0
                    font.pixelSize: 10
                    ToolTip.visible: hovered
                    ToolTip.text: "La ET0 (Evapotranspiración de referencia) se calcula mediante el algoritmo de Penman-Monteith"
                }
                
                Button {
                    text: "Cargar datos"
                    Layout.fillWidth: true
                    enabled: !isLoading && selectedStation !== null && selectedProvince !== null
                    Material.background: AppTheme.Theme.mainColor
                    Material.foreground: AppTheme.Theme.buttonTextColor
                    font.bold: true
                    font.pixelSize: 14
                    implicitHeight: 36
                    
                    onClicked: {
                        if (!selectedProvince) {
                            errorMessage = "Por favor, seleccione una provincia primero."
                            return;
                        }
                        
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
                padding: 0
                font.pixelSize: 10
                Material.foreground: AppTheme.Theme.mainTextColor
            }
            
            TabButton {
                text: "Tabla"
                padding: 0
                font.pixelSize: 10
                Material.foreground: AppTheme.Theme.mainTextColor
            }
        }
        
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: dataTabBar.currentIndex
            visible: weatherData !== null
            
            // Chart tab
            ColumnLayout {
                spacing: 0
                
                // Single chart for all data types
                ChartView {
                    id: dataChart
                    title: "Datos meteorológicos"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    antialiasing: true
                    legend.visible: true
                    legend.alignment: Qt.AlignBottom
                    legend.font.pixelSize: 10
                    legend.markerShape: Legend.MarkerShapeCircle
                    legend.backgroundVisible: false
                    margins.top: 0
                    margins.bottom: 0
                    margins.left: 0
                    margins.right: 0
                    
                    // Theme styling
                    backgroundColor: AppTheme.Theme.mainBackgroundColor
                    titleColor: AppTheme.Theme.mainTextColor
                    titleFont.pixelSize: 12
                    titleFont.bold: true
                    
                    // Reduce spacing between bars for better mobile display
                    Component.onCompleted: {
                        // Access internal properties to adjust spacing
                        if (dataChart.__plotArea) {
                            dataChart.__plotArea.spacing = 0.03 // Reduce spacing between bars even more
                        }
                    }
                    
                    BarCategoryAxis {
                        id: dataAxisX
                        titleText: "Fecha"
                        labelsFont.pixelSize: 9 // Revert to original size
                        // Categories will be set in updateChartData
                        gridVisible: true
                        minorGridVisible: false
                        labelsAngle: -90 // Angle labels for better readability
                    }
                    
                    ValueAxis {
                        id: dataAxisY
                        min: 0
                        max: 50
                        titleText: "Valor"
                        labelsFont.pixelSize: 10 // Revert to original size
                    }
                }
                
                // X-axis legend for mobile - Removed to save space
                Label {
                    id: axisLegendLabel
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: ""
                    font.italic: true
                    font.pixelSize: 10
                    color: "#666666"
                    visible: false
                }
                
                // Variable selection buttons
                ButtonGroup { id: variableGroup }
                
                Flow {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    RadioButton {
                        text: "Temperatura"
                        checked: selectedVariable === "temperature"
                        ButtonGroup.group: variableGroup
                        padding: 1
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
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
                        padding: 1
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
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
                        padding: 1
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
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
                        padding: 1
                        enabled: !isMonthlyData
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
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
                        padding: 1
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "precipitation"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "Int. Térmica"
                        ButtonGroup.group: variableGroup
                        padding: 1
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "thermal_integral"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "Int. Radiación"
                        ButtonGroup.group: variableGroup
                        padding: 1
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
                        onCheckedChanged: {
                            if (checked) {
                                selectedVariable = "radiation_integral"
                                updateChartData()
                            }
                        }
                    }
                    
                    RadioButton {
                        text: "ET0 Acum."
                        ButtonGroup.group: variableGroup
                        padding: 1
                        enabled: !isMonthlyData
                        font.pixelSize: 9
                        Material.accent: AppTheme.Theme.accentColor
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
                        height: dataColumn.height + 4
                        
                        ColumnLayout {
                            id: dataColumn
                            width: parent.width - 4
                            anchors.centerIn: parent
                            spacing: 1
                            
                            Label {
                                text: {
                                    var date = new Date(modelData.fecha)
                                    return date.toLocaleDateString()
                                }
                                font.bold: true
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                color: AppTheme.Theme.mainTextColor
                            }
                            
                            GridLayout {
                                columns: 2
                                columnSpacing: 2
                                rowSpacing: 1
                                Layout.fillWidth: true
                                
                                Label { 
                                    text: "Temp. Máxima:" 
                                    font.pixelSize: 10
                                    color: AppTheme.Theme.mainTextColor
                                }
                                Label { 
                                    text: modelData.tempMax + " °C" 
                                    font.pixelSize: 10
                                    color: AppTheme.Theme.mainTextColor
                                }
                                
                                Label { 
                                    text: "Temp. Mínima:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.tempMin + " °C" 
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "Temp. Media:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.tempMedia + " °C" 
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "Hum. Máxima:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.humedadMax + " %" 
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "Hum. Mínima:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.humedadMin + " %" 
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "Hum. Media:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.humedadMedia + " %" 
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "Precipitación:" 
                                    font.pixelSize: 10
                                }
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
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "Radiación:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.radiacion + " MJ/m²" 
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "Vel. Viento:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.velViento + " m/s" 
                                    font.pixelSize: 10
                                }
                                
                                Label { 
                                    text: "ET0:" 
                                    font.pixelSize: 10
                                }
                                Label { 
                                    text: modelData.et0 !== undefined ? modelData.et0.toFixed(2) + " mm" : "N/A"  // Format with 2 decimal places and handle undefined
                                    font.pixelSize: 10
                                }
                            }
                            
                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: AppTheme.Theme.controlBorderColor
                                visible: index < dataListView.count - 1
                            }
                        }
                    }
                }
            }
        }
    }
}

