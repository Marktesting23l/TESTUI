import QtQuick
import QtQuick.Controls
import QtQml

QtObject {
    id: sigpacService
    
    readonly property string baseUrl: "https://sigpac-hubcloud.es/servicioconsultassigpac"
    
    // Signal emitted when SIGPAC data is loaded
    signal dataLoaded(var sigpacData)
    
    // Signal emitted when an error occurs
    signal errorOccurred(string errorMessage)
    
    // Signal emitted when additional data loading status changes
    signal additionalDataLoadingChanged(bool isLoading)
    
    // Property to store additional intersection data
    property var redNaturaData: null
    property var fitosanitariosData: null
    property var nitratosData: null
    property var montaneraData: null
    property var pastosData: null
    
    // Function to query SIGPAC data by coordinates
    // srid: SRID of the coordinate system (e.g., 3857 for Web Mercator)
    // x: X coordinate
    // y: Y coordinate
    // format: "json" or "geojson"
    function queryByCoordinates(srid, x, y, format) {
        console.log("Querying SIGPAC with coordinates: SRID=" + srid + ", X=" + x + ", Y=" + y);
        
        // Reset intersection data
        resetIntersectionData();
        
        // Check if we're using a supported SRID
        if (srid !== 4258 && srid !== 4326 && srid !== 25830) {
            console.log("Warning: SRID " + srid + " might not be fully supported by SIGPAC. Consider using EPSG:4258 or EPSG:4326.");
        }
        
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("SIGPAC data received:", JSON.stringify(response).substring(0, 200) + "...");
                        
                        // Log the full structure of the first item for debugging
                        if (Array.isArray(response) && response.length > 0) {
                            logObjectStructure(response[0]);
                        }
                        
                        if (Array.isArray(response) && response.length === 0) {
                            console.log("SIGPAC returned an empty array. The coordinates might be outside of Spain or the SRID might not be supported.");
                            errorOccurred("No data found. Try using EPSG:4258 (ETRS89) or EPSG:4326 (WGS84) coordinate system.");
                        } else {
                            dataLoaded(response);
                            
                            // If we have valid results, also query the intersection data
                            if (Array.isArray(response) && response.length > 0) {
                                // Get the SIGPAC code from the first result
                                var item = response[0];
                                if (item.provincia !== undefined && 
                                    item.municipio !== undefined && 
                                    item.poligono !== undefined && 
                                    item.parcela !== undefined && 
                                    item.recinto !== undefined) {
                                    
                                    // Use default values of 0 for agregado and zona if not provided
                                    var agregado = item.agregado !== undefined ? item.agregado : 0;
                                    var zona = item.zona !== undefined ? item.zona : 0;
                                    
                                    // Query additional intersection data
                                    additionalDataLoadingChanged(true);
                                    queryRedNatura(item.provincia, item.municipio, agregado, zona, 
                                                  item.poligono, item.parcela, item.recinto, format);
                                    queryFitosanitarios(item.provincia, item.municipio, agregado, zona, 
                                                       item.poligono, item.parcela, item.recinto, format);
                                    queryNitratos(item.provincia, item.municipio, agregado, zona, 
                                                 item.poligono, item.parcela, item.recinto, format);
                                    queryMontanera(item.provincia, item.municipio, agregado, zona, 
                                                  item.poligono, item.parcela, item.recinto, format);
                                    queryPastos(item.provincia, item.municipio, agregado, zona, 
                                               item.poligono, item.parcela, item.recinto, format);
                                }
                            }
                        }
                    } catch (e) {
                        console.error("Error parsing SIGPAC data:", e);
                        errorOccurred("Error parsing SIGPAC data: " + e);
                    }
                } else {
                    console.error("Error loading SIGPAC data. Status:", xhr.status);
                    errorOccurred("Error loading SIGPAC data: " + xhr.status);
                }
            }
        }
        
        // Build the URL with parameters
        var requestFormat = format === "geojson" ? "geojson" : "json";
        var url = baseUrl + "/query/recinfobypoint/" + srid + "/" + x + "/" + y + "." + requestFormat;
        
        console.log("Querying SIGPAC at URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending SIGPAC request:", e);
            errorOccurred("Error sending SIGPAC request: " + e);
        }
    }
    
    // Function to query SIGPAC data by SIGPAC code
    // pr: provincia, mu: municipio, ag: agregado, zo: zona, po: polígono, pa: parcela, re: recinto
    // format: "json" or "geojson"
    function queryBySigpacCode(pr, mu, ag, zo, po, pa, re, format) {
        console.log("Querying SIGPAC with code: PR=" + pr + ", MU=" + mu + ", AG=" + ag + 
                    ", ZO=" + zo + ", PO=" + po + ", PA=" + pa + ", RE=" + re);
        
        // Reset intersection data
        resetIntersectionData();
        
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("SIGPAC data received:", JSON.stringify(response).substring(0, 200) + "...");
                        
                        // Log the full structure of the first item for debugging
                        if (Array.isArray(response) && response.length > 0) {
                            logObjectStructure(response[0]);
                        }
                        
                        if (Array.isArray(response) && response.length === 0) {
                            console.log("SIGPAC returned an empty array. The SIGPAC code might not exist.");
                            errorOccurred("No data found for the specified SIGPAC code.");
                        } else {
                            dataLoaded(response);
                            
                            // Query additional intersection data
                            additionalDataLoadingChanged(true);
                            queryRedNatura(pr, mu, ag, zo, po, pa, re, format);
                            queryFitosanitarios(pr, mu, ag, zo, po, pa, re, format);
                            queryNitratos(pr, mu, ag, zo, po, pa, re, format);
                            queryMontanera(pr, mu, ag, zo, po, pa, re, format);
                            queryPastos(pr, mu, ag, zo, po, pa, re, format);
                        }
                    } catch (e) {
                        console.error("Error parsing SIGPAC data:", e);
                        errorOccurred("Error parsing SIGPAC data: " + e);
                    }
                } else {
                    console.error("Error loading SIGPAC data. Status:", xhr.status);
                    errorOccurred("Error loading SIGPAC data: " + xhr.status);
                }
            }
        }
        
        // Build the URL with parameters
        var requestFormat = format === "geojson" ? "geojson" : "json";
        var url = baseUrl + "/query/recinfo/" + pr + "/" + mu + "/" + ag + "/" + zo + "/" + po + "/" + pa + "/" + re + "." + requestFormat;
        
        console.log("Querying SIGPAC at URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending SIGPAC request:", e);
            errorOccurred("Error sending SIGPAC request: " + e);
        }
    }
    
    // Function to reset all intersection data
    function resetIntersectionData() {
        redNaturaData = null;
        fitosanitariosData = null;
        nitratosData = null;
        montaneraData = null;
        pastosData = null;
    }
    
    // Function to query Red Natura intersection data
    function queryRedNatura(pr, mu, ag, zo, po, pa, re, format) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("Red Natura data received:", JSON.stringify(response).substring(0, 200) + "...");
                        redNaturaData = response;
                    } catch (e) {
                        console.error("Error parsing Red Natura data:", e);
                        redNaturaData = [];
                    }
                } else {
                    console.error("Error loading Red Natura data. Status:", xhr.status);
                    redNaturaData = [];
                }
            }
        }
        
        // Build the URL with parameters
        var requestFormat = format === "geojson" ? "geojson" : "json";
        var url = baseUrl + "/intersection/red_natura/" + pr + "/" + mu + "/" + ag + "/" + zo + "/" + po + "/" + pa + "/" + re + "." + requestFormat;
        
        console.log("Querying Red Natura at URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending Red Natura request:", e);
            redNaturaData = [];
        }
    }
    
    // Function to query Fitosanitarios intersection data
    function queryFitosanitarios(pr, mu, ag, zo, po, pa, re, format) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("Fitosanitarios data received:", JSON.stringify(response).substring(0, 200) + "...");
                        fitosanitariosData = response;
                    } catch (e) {
                        console.error("Error parsing Fitosanitarios data:", e);
                        fitosanitariosData = [];
                    }
                } else {
                    console.error("Error loading Fitosanitarios data. Status:", xhr.status);
                    fitosanitariosData = [];
                }
            }
        }
        
        // Build the URL with parameters
        var requestFormat = format === "geojson" ? "geojson" : "json";
        var url = baseUrl + "/intersection/fitosanitarios/" + pr + "/" + mu + "/" + ag + "/" + zo + "/" + po + "/" + pa + "/" + re + "." + requestFormat;
        
        console.log("Querying Fitosanitarios at URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending Fitosanitarios request:", e);
            fitosanitariosData = [];
        }
    }
    
    // Function to query Nitratos intersection data
    function queryNitratos(pr, mu, ag, zo, po, pa, re, format) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("Nitratos data received:", JSON.stringify(response).substring(0, 200) + "...");
                        nitratosData = response;
                    } catch (e) {
                        console.error("Error parsing Nitratos data:", e);
                        nitratosData = [];
                    }
                } else {
                    console.error("Error loading Nitratos data. Status:", xhr.status);
                    nitratosData = [];
                }
            }
        }
        
        // Build the URL with parameters
        var requestFormat = format === "geojson" ? "geojson" : "json";
        var url = baseUrl + "/intersection/nitratos/" + pr + "/" + mu + "/" + ag + "/" + zo + "/" + po + "/" + pa + "/" + re + "." + requestFormat;
        
        console.log("Querying Nitratos at URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending Nitratos request:", e);
            nitratosData = [];
        }
    }
    
    // Function to query Montanera intersection data
    function queryMontanera(pr, mu, ag, zo, po, pa, re, format) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("Montanera data received:", JSON.stringify(response).substring(0, 200) + "...");
                        montaneraData = response;
                    } catch (e) {
                        console.error("Error parsing Montanera data:", e);
                        montaneraData = [];
                    }
                } else {
                    console.error("Error loading Montanera data. Status:", xhr.status);
                    montaneraData = [];
                }
            }
        }
        
        // Build the URL with parameters
        var requestFormat = format === "geojson" ? "geojson" : "json";
        var url = baseUrl + "/intersection/montanera/" + pr + "/" + mu + "/" + ag + "/" + zo + "/" + po + "/" + pa + "/" + re + "." + requestFormat;
        
        console.log("Querying Montanera at URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending Montanera request:", e);
            montaneraData = [];
        }
    }
    
    // Function to query Pastos Permanentes intersection data
    function queryPastos(pr, mu, ag, zo, po, pa, re, format) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("Pastos data received:", JSON.stringify(response).substring(0, 200) + "...");
                        pastosData = response;
                    } catch (e) {
                        console.error("Error parsing Pastos data:", e);
                        pastosData = [];
                    }
                } else {
                    console.error("Error loading Pastos data. Status:", xhr.status);
                    pastosData = [];
                }
                
                // This is the last query, so set the loading flag to false
                additionalDataLoadingChanged(false);
            }
        }
        
        // Build the URL with parameters
        var requestFormat = format === "geojson" ? "geojson" : "json";
        var url = baseUrl + "/intersection/pastos/" + pr + "/" + mu + "/" + ag + "/" + zo + "/" + po + "/" + pa + "/" + re + "." + requestFormat;
        
        console.log("Querying Pastos at URL:", url);
        
        try {
            xhr.open("GET", url);
            xhr.send();
        } catch (e) {
            console.error("Error sending Pastos request:", e);
            pastosData = [];
        }
    }
    
    // Helper function to format SIGPAC data for display
    function formatSigpacData(data) {
        if (!data || data.length === 0) {
            return "No data found for this location";
        }
        
        var result = "";
        
        for (var i = 0; i < data.length; i++) {
            var item = data[i];
            result += "Resultado " + (i + 1) + ":\n";
            result += "  Provincia: " + item.provincia + "\n";
            result += "  Municipio: " + item.municipio + "\n";
            result += "  Polígono: " + item.poligono + "\n";
            result += "  Parcela: " + item.parcela + "\n";
            result += "  Recinto: " + item.recinto + "\n";
            
            // Fix for superficie value - check if it's defined and is a number
            // The API returns the area as "dn_surface" instead of "superficie"
            var superficie = "N/A";
            if (item.dn_surface !== undefined && item.dn_surface !== null && !isNaN(item.dn_surface)) {
                // Convert to hectares (if needed) and format with 4 decimal places
                var areaInHectares = item.dn_surface / 10000; // Convert from square meters to hectares
                superficie = areaInHectares.toFixed(4);
            } else if (item.superficie !== undefined && item.superficie !== null && !isNaN(item.superficie)) {
                // Fallback to superficie if it exists
                superficie = item.superficie.toFixed(4);
            }
            result += "  Superficie: " + superficie + " ha\n";
            
            result += "  Pendiente media: " + (item.pendiente_media !== undefined ? item.pendiente_media : "N/A") + "%\n";
            result += "  Uso SIGPAC: " + (item.uso_sigpac !== undefined ? item.uso_sigpac : "N/A") + "\n";
            
            // Add coef_regadio if available
            if (item.coef_regadio !== undefined && item.coef_regadio !== null) {
                result += "  Coef. Regadío: " + item.coef_regadio + "%\n";
            }
            
            // Add region if available
            if (item.region !== undefined && item.region !== null) {
                result += "  Región: " + item.region + "\n";
            }
            
            // Add admisibilidad if available
            if (item.admisibilidad !== undefined && item.admisibilidad !== null) {
                result += "  Admisibilidad: " + item.admisibilidad + "%\n";
            }
            
            if (i < data.length - 1) {
                result += "\n";
            }
        }
        
        // Add intersection data if available
        var intersectionResult = formatIntersectionData();
        if (intersectionResult) {
            result += "\n\n--- INFORMACIÓN ADICIONAL ---\n\n" + intersectionResult;
        }
        
        return result;
    }
    
    // Helper function to format intersection data
    function formatIntersectionData() {
        var result = "";
        
        // Format Red Natura data
        if (redNaturaData && Array.isArray(redNaturaData) && redNaturaData.length > 0) {
            result += "RED NATURA 2000:\n";
            for (var i = 0; i < redNaturaData.length; i++) {
                var item = redNaturaData[i];
                result += "  Superficie intersección: " + (item.surface_intersection / 10000).toFixed(4) + " ha (" + item.surface_tpc.toFixed(2) + "%)\n";
                
                if (item.lic_code && item.lic_code !== "") {
                    result += "  LIC: " + item.lic_code + " - " + (item.lic_name || "N/A") + "\n";
                }
                
                if (item.zepa_code && item.zepa_code !== "") {
                    result += "  ZEPA: " + item.zepa_code + " - " + (item.zepa_name || "N/A") + "\n";
                }
                
                if (i < redNaturaData.length - 1) {
                    result += "\n";
                }
            }
        }
        
        // Format Fitosanitarios data
        if (fitosanitariosData && Array.isArray(fitosanitariosData) && fitosanitariosData.length > 0) {
            if (result) result += "\n";
            result += "FITOSANITARIOS:\n";
            for (var i = 0; i < fitosanitariosData.length; i++) {
                var item = fitosanitariosData[i];
                result += "  Descripción: " + (item.descripcion || "N/A") + "\n";
                result += "  Superficie intersección: " + (item.surface_intersection / 10000).toFixed(4) + " ha (" + item.surface_tpc.toFixed(2) + "%)\n";
                
                if (i < fitosanitariosData.length - 1) {
                    result += "\n";
                }
            }
        }
        
        // Format Nitratos data
        if (nitratosData && Array.isArray(nitratosData) && nitratosData.length > 0) {
            if (result) result += "\n";
            result += "NITRATOS:\n";
            for (var i = 0; i < nitratosData.length; i++) {
                var item = nitratosData[i];
                result += "  Superficie intersección: " + (item.surface_intersection / 10000).toFixed(4) + " ha (" + item.surface_tpc.toFixed(2) + "%)\n";
                
                if (i < nitratosData.length - 1) {
                    result += "\n";
                }
            }
        }
        
        // Format Montanera data
        if (montaneraData && Array.isArray(montaneraData) && montaneraData.length > 0) {
            if (result) result += "\n";
            result += "MONTANERA:\n";
            for (var i = 0; i < montaneraData.length; i++) {
                var item = montaneraData[i];
                result += "  Superficie intersección: " + (item.surface_intersection / 10000).toFixed(4) + " ha (" + item.surface_tpc.toFixed(2) + "%)\n";
                
                if (item.sac_quercus !== undefined) {
                    result += "  SAC Quercus: " + (item.sac_quercus === "*" ? "No aplicable" : item.sac_quercus.toFixed(2) + "%") + "\n";
                }
                
                if (i < montaneraData.length - 1) {
                    result += "\n";
                }
            }
        }
        
        // Format Pastos data
        if (pastosData && Array.isArray(pastosData) && pastosData.length > 0) {
            if (result) result += "\n";
            result += "PASTOS PERMANENTES:\n";
            for (var i = 0; i < pastosData.length; i++) {
                var item = pastosData[i];
                result += "  Superficie intersección: " + (item.surface_intersection / 10000).toFixed(4) + " ha (" + item.surface_tpc.toFixed(2) + "%)\n";
                
                if (item.sensible !== undefined) {
                    var sensibleText = "";
                    if (item.sensible === 1) {
                        sensibleText = "Sí (zona sensible)";
                    } else if (item.sensible === 0) {
                        sensibleText = "No (zona no sensible)";
                    } else {
                        sensibleText = "No aplicable (uso SIGPAC no es pasto)";
                    }
                    result += "  Sensible: " + sensibleText + "\n";
                }
                
                if (i < pastosData.length - 1) {
                    result += "\n";
                }
            }
        }
        
        return result;
    }
    
    // Helper function to convert coordinates from one SRID to another
    // This is a placeholder - in a real implementation, you would use QGIS's
    // coordinate transformation capabilities
    function convertCoordinates(fromSrid, toSrid, x, y) {
        // In a real implementation, you would use QGIS's coordinate transformation
        // For now, we'll just return the original coordinates
        console.log("Converting coordinates from SRID " + fromSrid + " to " + toSrid);
        return { x: x, y: y };
    }
    
    // Helper function to log the structure of an object for debugging
    function logObjectStructure(obj) {
        if (!obj) return;
        
        console.log("SIGPAC response structure:");
        for (var key in obj) {
            console.log("  " + key + ": " + typeof obj[key] + " = " + obj[key]);
        }
    }
} 