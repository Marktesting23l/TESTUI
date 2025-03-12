import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQml 2.12

QtObject {
    id: riaService
    
    readonly property string baseUrl: "https://www.juntadeandalucia.es/agriculturaypesca/ifapa/riaws"
    
    // Signal emitted when provinces are loaded
    signal provincesLoaded(var provinces)
    
    // Signal emitted when stations are loaded
    signal stationsLoaded(var stations)
    
    // Signal emitted when daily data is loaded
    signal dailyDataLoaded(var dailyData)
    
    // Signal emitted when monthly data is loaded
    signal monthlyDataLoaded(var monthlyData)
    
    // Signal emitted when an error occurs
    signal errorOccurred(string errorMessage)
    
    // Helper function to format date for API
    function formatDateForAPI(date) {
        // The API expects ISO format without milliseconds and with 'Z' timezone
        var isoString = date.toISOString();
        // Remove milliseconds part and ensure 'Z' is present
        return isoString.split('.')[0] + "Z";
    }
    
    // Helper function to normalize numeric values
    function normalizeNumericValue(value) {
        if (value === undefined || value === null) {
            return 0;
        }
        
        // Handle string values with comma as decimal separator
        if (typeof value === 'string') {
            return parseFloat(value.replace(',', '.')) || 0;
        }
        
        return parseFloat(value) || 0;
    }
    
    // Function to load provinces
    function loadProvinces() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        provincesLoaded(response);
                    } catch (e) {
                        errorOccurred("Error parsing provinces data: " + e);
                    }
                } else {
                    errorOccurred("Error loading provinces: " + xhr.status);
                }
            }
        }
        
        xhr.open("GET", baseUrl + "/provincias");
        xhr.send();
    }
    
    // Function to load stations for a province
    function loadStations(provinceId) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        stationsLoaded(response);
                    } catch (e) {
                        errorOccurred("Error parsing stations data: " + e);
                    }
                } else {
                    errorOccurred("Error loading stations: " + xhr.status);
                }
            }
        }
        
        xhr.open("GET", baseUrl + "/estaciones/" + provinceId);
        xhr.send();
    }
    
    // Function to load daily data for a station on a specific date
    function loadDailyData(provinceId, stationCode, date, calculateEt0) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        
                        // Normalize numeric values in the response
                        if (Array.isArray(response)) {
                            response.forEach(function(item) {
                                // Ensure all numeric values are properly parsed
                                item.tempMax = normalizeNumericValue(item.tempMax);
                                item.tempMin = normalizeNumericValue(item.tempMin);
                                item.tempMedia = normalizeNumericValue(item.tempMedia);
                                item.humedadMax = normalizeNumericValue(item.humedadMax);
                                item.humedadMin = normalizeNumericValue(item.humedadMin);
                                item.humedadMedia = normalizeNumericValue(item.humedadMedia);
                                item.precipitacion = normalizeNumericValue(item.precipitacion);
                                item.radiacion = normalizeNumericValue(item.radiacion);
                                item.velViento = normalizeNumericValue(item.velViento);
                                item.et0 = normalizeNumericValue(item.et0);
                            });
                        } else if (response) {
                            // Single object
                            response.tempMax = normalizeNumericValue(response.tempMax);
                            response.tempMin = normalizeNumericValue(response.tempMin);
                            response.tempMedia = normalizeNumericValue(response.tempMedia);
                            response.humedadMax = normalizeNumericValue(response.humedadMax);
                            response.humedadMin = normalizeNumericValue(response.humedadMin);
                            response.humedadMedia = normalizeNumericValue(response.humedadMedia);
                            response.precipitacion = normalizeNumericValue(response.precipitacion);
                            response.radiacion = normalizeNumericValue(response.radiacion);
                            response.velViento = normalizeNumericValue(response.velViento);
                            response.et0 = normalizeNumericValue(response.et0);
                        }
                        
                        dailyDataLoaded(response);
                    } catch (e) {
                        errorOccurred("Error parsing daily data: " + e);
                    }
                } else {
                    errorOccurred("Error loading daily data: " + xhr.status + " - Compruebe que la fecha seleccionada tiene datos disponibles.");
                }
            }
        }
        
        // Format date as ISO string and encode it
        var formattedDate = formatDateForAPI(date);
        var encodedDate = encodeURIComponent(formattedDate);
        
        var url = baseUrl + "/datosdiarios/" + provinceId + "/" + stationCode + "/" + encodedDate + "/" + calculateEt0;
        console.log("Loading daily data from URL: " + url);
        
        xhr.open("GET", url);
        xhr.send();
    }
    
    // Function to load daily data for a station in a date range
    function loadDailyDataRange(provinceId, stationCode, startDate, endDate, calculateEt0) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        
                        // Normalize numeric values in the response
                        if (Array.isArray(response)) {
                            response.forEach(function(item) {
                                // Ensure all numeric values are properly parsed
                                item.tempMax = normalizeNumericValue(item.tempMax);
                                item.tempMin = normalizeNumericValue(item.tempMin);
                                item.tempMedia = normalizeNumericValue(item.tempMedia);
                                item.humedadMax = normalizeNumericValue(item.humedadMax);
                                item.humedadMin = normalizeNumericValue(item.humedadMin);
                                item.humedadMedia = normalizeNumericValue(item.humedadMedia);
                                item.precipitacion = normalizeNumericValue(item.precipitacion);
                                item.radiacion = normalizeNumericValue(item.radiacion);
                                item.velViento = normalizeNumericValue(item.velViento);
                                item.et0 = normalizeNumericValue(item.et0);
                            });
                        } else if (response) {
                            // Single object
                            response.tempMax = normalizeNumericValue(response.tempMax);
                            response.tempMin = normalizeNumericValue(response.tempMin);
                            response.tempMedia = normalizeNumericValue(response.tempMedia);
                            response.humedadMax = normalizeNumericValue(response.humedadMax);
                            response.humedadMin = normalizeNumericValue(response.humedadMin);
                            response.humedadMedia = normalizeNumericValue(response.humedadMedia);
                            response.precipitacion = normalizeNumericValue(response.precipitacion);
                            response.radiacion = normalizeNumericValue(response.radiacion);
                            response.velViento = normalizeNumericValue(response.velViento);
                            response.et0 = normalizeNumericValue(response.et0);
                        }
                        
                        dailyDataLoaded(response);
                    } catch (e) {
                        errorOccurred("Error parsing daily data range: " + e);
                    }
                } else {
                    errorOccurred("Error loading daily data range: " + xhr.status + " - Compruebe que las fechas seleccionadas tienen datos disponibles.");
                }
            }
        }
        
        // Format dates as ISO strings and encode them
        var formattedStartDate = formatDateForAPI(startDate);
        var formattedEndDate = formatDateForAPI(endDate);
        var encodedStartDate = encodeURIComponent(formattedStartDate);
        var encodedEndDate = encodeURIComponent(formattedEndDate);
        
        var url = baseUrl + "/datosdiarios/" + provinceId + "/" + stationCode + "/" + encodedStartDate + "/" + encodedEndDate + "/" + calculateEt0;
        console.log("Loading daily data range from URL: " + url);
        
        xhr.open("GET", url);
        xhr.send();
    }
    
    // Function to load monthly data for a station in a specific month
    function loadMonthlyData(provinceId, stationCode, year, month) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        // Adapt the monthly data to match the format expected by the UI
                        // This ensures compatibility with the existing chart and table display
                        if (response) {
                            // If it's a single object, convert some properties to match daily data format
                            if (!Array.isArray(response)) {
                                response.tempMax = normalizeNumericValue(response.tempMax);
                                response.tempMin = normalizeNumericValue(response.tempMin);
                                response.tempMedia = normalizeNumericValue(response.tempMedia);
                                response.humedadMax = normalizeNumericValue(response.humedadMax);
                                response.humedadMin = normalizeNumericValue(response.humedadMin);
                                response.humedadMedia = normalizeNumericValue(response.humedadMedia);
                                response.precipitacion = normalizeNumericValue(response.precipitacion);
                                response.radiacion = normalizeNumericValue(response.radiacion);
                                response.velViento = normalizeNumericValue(response.velViento);
                                response.et0 = normalizeNumericValue(response.et0);
                                // Create a fecha property for display purposes
                                response.fecha = new Date(year, month - 1, 1).toISOString();
                            }
                        }
                        monthlyDataLoaded(response);
                    } catch (e) {
                        errorOccurred("Error parsing monthly data: " + e);
                    }
                } else {
                    errorOccurred("Error loading monthly data: " + xhr.status + " - Compruebe que el mes seleccionado tiene datos disponibles.");
                }
            }
        }
        
        var url = baseUrl + "/datosmensuales/" + provinceId + "/" + stationCode + "/" + year + "/" + month;
        console.log("Loading monthly data from URL: " + url);
        
        xhr.open("GET", url);
        xhr.send();
    }
    
    // Function to load monthly data for a station in a month range
    function loadMonthlyDataRange(provinceId, stationCode, year, startMonth, endMonth) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        // Adapt the monthly data to match the format expected by the UI
                        if (Array.isArray(response)) {
                            response.forEach(function(item) {
                                item.tempMax = normalizeNumericValue(item.tempMax);
                                item.tempMin = normalizeNumericValue(item.tempMin);
                                item.tempMedia = normalizeNumericValue(item.tempMedia);
                                item.humedadMax = normalizeNumericValue(item.humedadMax);
                                item.humedadMin = normalizeNumericValue(item.humedadMin);
                                item.humedadMedia = normalizeNumericValue(item.humedadMedia);
                                item.precipitacion = normalizeNumericValue(item.precipitacion);
                                item.radiacion = normalizeNumericValue(item.radiacion);
                                item.velViento = normalizeNumericValue(item.velViento);
                                item.et0 = normalizeNumericValue(item.et0);
                                // Create a fecha property for display purposes
                                item.fecha = new Date(year, item.mes - 1, 1).toISOString();
                            });
                        }
                        monthlyDataLoaded(response);
                    } catch (e) {
                        errorOccurred("Error parsing monthly data range: " + e);
                    }
                } else {
                    errorOccurred("Error loading monthly data range: " + xhr.status + " - Compruebe que los meses seleccionados tienen datos disponibles.");
                }
            }
        }
        
        var url = baseUrl + "/datosmensuales/" + provinceId + "/" + stationCode + "/" + year + "/" + startMonth + "/" + endMonth;
        console.log("Loading monthly data range from URL: " + url);
        
        xhr.open("GET", url);
        xhr.send();
    }
} 