import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQml 2.12

QtObject {
    id: openMeteoService
    
    readonly property string baseUrl: "https://api.open-meteo.com/v1/forecast"
    
    // Signal emitted when forecast data is loaded
    signal forecastLoaded(var forecastData)
    
    // Signal emitted when an error occurs
    signal errorOccurred(string errorMessage)
    
    // Function to load weather forecast for a location
    function loadForecast(latitude, longitude) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        
                        // Process the data to make it easier to use in the UI
                        var processedData = processWeatherData(response);
                        
                        forecastLoaded(processedData);
                    } catch (e) {
                        errorOccurred("Error parsing forecast data: " + e);
                    }
                } else {
                    errorOccurred("Error loading forecast: " + xhr.status);
                }
            }
        }
        
        // Build the URL with parameters - using exact parameters from the provided URL
        var url = baseUrl + "?latitude=" + latitude + 
                  "&longitude=" + longitude + 
                  "&hourly=temperature_2m,wind_speed_10m,soil_temperature_0cm,soil_moisture_0_to_1cm," +
                  "weather_code,surface_pressure,vapour_pressure_deficit,rain,dew_point_2m," +
                  "relative_humidity_2m,wet_bulb_temperature_2m,wind_direction_10m,precipitation_probability," +
                  "soil_moisture_3_to_9cm,soil_temperature_18cm" +
                  "&models=best_match" +
                  "&current=temperature_2m,wind_speed_10m,precipitation,relative_humidity_2m,rain," +
                  "surface_pressure,wind_direction_10m,weather_code" +
                  "&timezone=auto" +
                  "&forecast_days=7";
        
        console.log("Loading forecast from URL: " + url);
        
        xhr.open("GET", url);
        xhr.send();
    }
    
    // For testing with local JSON file
    function loadForecastFromFile() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var processedData = processWeatherData(response);
                        forecastLoaded(processedData);
                    } catch (e) {
                        errorOccurred("Error parsing forecast data from file: " + e);
                    }
                } else {
                    errorOccurred("Error loading forecast from file: " + xhr.status);
                }
            }
        }
        
        xhr.open("GET", "qrc:/qml/forecast.json");
        xhr.send();
    }
    
    // Helper function to process the weather data
    function processWeatherData(data) {
        console.log("Processing weather data from API");
        
        var result = {
            current: {},
            hourly: [],
            daily: []
        };
        
        // Process current weather
        if (data.current) {
            result.current = {
                temperature: data.current.temperature_2m,
                windspeed: data.current.wind_speed_10m,
                winddirection: data.current.wind_direction_10m,
                weathercode: data.current.weather_code,
                precipitation: data.current.precipitation,
                humidity: data.current.relative_humidity_2m,
                rain: data.current.rain,
                pressure: data.current.surface_pressure,
                weatherDescription: getWeatherDescription(data.current.weather_code),
                weatherIcon: getWeatherIcon(data.current.weather_code)
            };
        } else if (data.hourly && data.hourly.time && data.hourly.time.length > 0) {
            // If current is not available, use the first hourly data point
            var currentIndex = 0;
            result.current = {
                temperature: data.hourly.temperature_2m[currentIndex],
                windspeed: data.hourly.wind_speed_10m[currentIndex],
                winddirection: data.hourly.wind_direction_10m ? data.hourly.wind_direction_10m[currentIndex] : null,
                weathercode: data.hourly.weather_code[currentIndex],
                humidity: data.hourly.relative_humidity_2m ? data.hourly.relative_humidity_2m[currentIndex] : null,
                weatherDescription: getWeatherDescription(data.hourly.weather_code[currentIndex]),
                weatherIcon: getWeatherIcon(data.hourly.weather_code[currentIndex])
            };
        }
        
        // Process hourly forecast
        if (data.hourly) {
            console.log("Processing hourly data with " + (data.hourly.time ? data.hourly.time.length : 0) + " time points");
            
            var timeArray = data.hourly.time || [];
            var tempArray = data.hourly.temperature_2m || [];
            var humidityArray = data.hourly.relative_humidity_2m || [];
            var precipProbArray = data.hourly.precipitation_probability || [];
            var rainArray = data.hourly.rain || [];
            var weathercodeArray = data.hourly.weather_code || [];
            var windspeedArray = data.hourly.wind_speed_10m || [];
            var windDirectionArray = data.hourly.wind_direction_10m || [];
            var soilTemp0Array = data.hourly.soil_temperature_0cm || [];
            var soilTemp18Array = data.hourly.soil_temperature_18cm || [];
            var soilMoisture0Array = data.hourly.soil_moisture_0_to_1cm || [];
            var soilMoisture3Array = data.hourly.soil_moisture_3_to_9cm || [];
            var pressureArray = data.hourly.surface_pressure || [];
            var vpdArray = data.hourly.vapour_pressure_deficit || [];
            var dewPointArray = data.hourly.dew_point_2m || [];
            var wetBulbTempArray = data.hourly.wet_bulb_temperature_2m || [];
            
            for (var i = 0; i < timeArray.length; i++) {
                var hourlyData = {
                    time: new Date(timeArray[i]),
                    temperature_2m: i < tempArray.length ? tempArray[i] : null,
                    relative_humidity_2m: i < humidityArray.length ? humidityArray[i] : null,
                    precipitation_probability: i < precipProbArray.length ? precipProbArray[i] : null,
                    rain: i < rainArray.length ? rainArray[i] : null,
                    weather_code: i < weathercodeArray.length ? weathercodeArray[i] : null,
                    wind_speed_10m: i < windspeedArray.length ? windspeedArray[i] : null,
                    wind_direction_10m: i < windDirectionArray.length ? windDirectionArray[i] : null,
                    soil_temperature_0cm: i < soilTemp0Array.length ? soilTemp0Array[i] : null,
                    soil_temperature_18cm: i < soilTemp18Array.length ? soilTemp18Array[i] : null,
                    soil_moisture_0_1cm: i < soilMoisture0Array.length ? soilMoisture0Array[i] : null,
                    soil_moisture_3_9cm: i < soilMoisture3Array.length ? soilMoisture3Array[i] : null,
                    surface_pressure: i < pressureArray.length ? pressureArray[i] : null,
                    vapour_pressure_deficit: i < vpdArray.length ? vpdArray[i] : null,
                    dewpoint_2m: i < dewPointArray.length ? dewPointArray[i] : null,
                    wet_bulb_temperature_2m: i < wetBulbTempArray.length ? wetBulbTempArray[i] : null,
                    weatherDescription: i < weathercodeArray.length ? getWeatherDescription(weathercodeArray[i]) : "",
                    weatherIcon: i < weathercodeArray.length ? getWeatherIcon(weathercodeArray[i]) : ""
                };
                
                result.hourly.push(hourlyData);
            }
            
            console.log("Processed " + result.hourly.length + " hourly data points");
            if (result.hourly.length > 0) {
                console.log("First hourly data point:", JSON.stringify(result.hourly[0]).substring(0, 200) + "...");
            }
        }
        
        // Create daily forecast from hourly data since we don't have daily in the API
        if (data.hourly && data.hourly.time) {
            console.log("Creating daily forecast from hourly data");
            
            // Group hourly data by day
            var dailyData = {};
            
            for (var j = 0; j < data.hourly.time.length; j++) {
                var date = new Date(data.hourly.time[j]);
                var dateString = date.toISOString().split('T')[0]; // YYYY-MM-DD
                
                if (!dailyData[dateString]) {
                    dailyData[dateString] = {
                        date: new Date(dateString),
                        temps: [],
                        weatherCodes: [],
                        precipitation: 0,
                        windSpeeds: []
                    };
                }
                
                // Collect data for this day
                if (data.hourly.temperature_2m && data.hourly.temperature_2m[j] !== null) {
                    dailyData[dateString].temps.push(data.hourly.temperature_2m[j]);
                }
                
                if (data.hourly.weather_code && data.hourly.weather_code[j] !== null) {
                    dailyData[dateString].weatherCodes.push(data.hourly.weather_code[j]);
                }
                
                if (data.hourly.rain && data.hourly.rain[j] !== null) {
                    dailyData[dateString].precipitation += data.hourly.rain[j];
                }
                
                if (data.hourly.wind_speed_10m && data.hourly.wind_speed_10m[j] !== null) {
                    dailyData[dateString].windSpeeds.push(data.hourly.wind_speed_10m[j]);
                }
            }
            
            // Process daily data
            var dailyKeys = Object.keys(dailyData).sort();
            for (var k = 0; k < dailyKeys.length; k++) {
                var day = dailyData[dailyKeys[k]];
                
                // Calculate min/max temperature
                var minTemp = Math.min.apply(null, day.temps);
                var maxTemp = Math.max.apply(null, day.temps);
                
                // Get most common weather code for the day
                var weatherCodeCounts = {};
                var maxCount = 0;
                var mostCommonWeatherCode = null;
                
                for (var l = 0; l < day.weatherCodes.length; l++) {
                    var code = day.weatherCodes[l];
                    weatherCodeCounts[code] = (weatherCodeCounts[code] || 0) + 1;
                    
                    if (weatherCodeCounts[code] > maxCount) {
                        maxCount = weatherCodeCounts[code];
                        mostCommonWeatherCode = code;
                    }
                }
                
                // Get max wind speed
                var maxWindSpeed = Math.max.apply(null, day.windSpeeds);
                
                // Create daily forecast entry
                result.daily.push({
                    date: day.date,
                    temperature_2m_min: minTemp,
                    temperature_2m_max: maxTemp,
                    precipitation_sum: day.precipitation,
                    weather_code: mostCommonWeatherCode,
                    wind_speed_10m_max: maxWindSpeed,
                    weatherDescription: getWeatherDescription(mostCommonWeatherCode),
                    weatherIcon: getWeatherIcon(mostCommonWeatherCode)
                });
            }
            
            console.log("Created " + result.daily.length + " daily data points from hourly data");
        }
        
        return result;
    }
    
    // Helper function to get weather description from weather code
    function getWeatherDescription(code) {
        // WMO Weather interpretation codes (WW)
        // https://open-meteo.com/en/docs
        switch(code) {
            case 0: return "Cielo despejado";
            case 1: return "Principalmente despejado";
            case 2: return "Parcialmente nublado";
            case 3: return "Nublado";
            case 45: return "Niebla";
            case 48: return "Niebla con escarcha";
            case 51: return "Llovizna ligera";
            case 53: return "Llovizna moderada";
            case 55: return "Llovizna intensa";
            case 56: return "Llovizna helada ligera";
            case 57: return "Llovizna helada intensa";
            case 61: return "Lluvia ligera";
            case 63: return "Lluvia moderada";
            case 65: return "Lluvia intensa";
            case 66: return "Lluvia helada ligera";
            case 67: return "Lluvia helada intensa";
            case 71: return "Nevada ligera";
            case 73: return "Nevada moderada";
            case 75: return "Nevada intensa";
            case 77: return "Granos de nieve";
            case 80: return "Chubascos ligeros";
            case 81: return "Chubascos moderados";
            case 82: return "Chubascos violentos";
            case 85: return "Chubascos de nieve ligeros";
            case 86: return "Chubascos de nieve intensos";
            case 95: return "Tormenta";
            case 96: return "Tormenta con granizo ligero";
            case 99: return "Tormenta con granizo intenso";
            default: return "Desconocido";
        }
    }
    
    // Helper function to get weather icon from weather code
    function getWeatherIcon(code) {
        // Map WMO codes to icon names
        var iconPath = "";
        
        // Try to map the code to an icon
        switch(code) {
            case 0: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/clear.svg"; break;
            case 1: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/mostly_clear.svg"; break;
            case 2: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/partly_cloudy.svg"; break;
            case 3: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/cloudy.svg"; break;
            case 45:
            case 48: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/fog.svg"; break;
            case 51:
            case 53:
            case 55: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/drizzle.svg"; break;
            case 56:
            case 57: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/freezing_drizzle.svg"; break;
            case 61: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/light_rain.svg"; break;
            case 63: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/rain.svg"; break;
            case 65: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/heavy_rain.svg"; break;
            case 66:
            case 67: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/freezing_rain.svg"; break;
            case 71:
            case 73:
            case 75:
            case 77: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/snow.svg"; break;
            case 80:
            case 81:
            case 82: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/showers.svg"; break;
            case 85:
            case 86: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/snow_showers.svg"; break;
            case 95:
            case 96:
            case 99: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/thunderstorm.svg"; break;
            default: iconPath = "qrc:///images/themes/sigpacgo/nodpi/weather/cloudy.svg"; break;
        }
        
        // Fallback to a generic icon if the specific one is not available
        // Use a standard icon from the Qt resources that's likely to be available
        return "qrc:///icons/mActionAddRasterLayer.svg";
    }
} 