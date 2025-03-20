import QtQuick
import QtQuick.Controls
import QtQml

QtObject {
    id: cultivoDeclaradoService
    
    readonly property string mvtBaseUrl: "https://sigpac-hubcloud.es/mvt"
    
    // Property to set the campaign year (default to previous year since current year data may not be available yet)
    property int campaignYear: new Date().getFullYear() - 1
    
    // Signal emitted when cultivation data is loaded
    signal dataLoaded(var cultivoData)
    
    // Signal emitted when an error occurs
    signal errorOccurred(string errorMessage)
    
    // Signal emitted when loading status changes
    signal loadingChanged(bool isLoading)
    
    // Property to store cultivo data
    property var cultivoDeclaradoData: null
    property bool isLoading: false
    
    // An object to track request attempts and prevent infinite loops
    property var requestAttempts: ({
        count: 0,
        maxAttempts: 9,    // Try at most 9 tiles (3x3 grid)
        processedTiles: {} // Track which tiles we've already processed
    })
    
    // Function to query cultivo declarado data by SIGPAC code
    function queryBySigpacCode(pr, mu, po, pa, re) {
        console.log("Querying Cultivo Declarado for PR=" + pr + ", MU=" + mu + 
                   ", PO=" + po + ", PA=" + pa + ", RE=" + re);
        
        // Reset data and attempts
        cultivoDeclaradoData = null;
        isLoading = true;
        loadingChanged(true);
        resetRequestAttempts();
        
        // First get the parcel geometry to determine the correct tile
        var sigpacUrl = "https://sigpac-hubcloud.es/servicioconsultassigpac/query/recinfo/" + 
                     pr + "/" + mu + "/0/0/" + po + "/" + pa + "/" + re + ".json";
        
        var sigpacXhr = new XMLHttpRequest();
        sigpacXhr.onreadystatechange = function() {
            if (sigpacXhr.readyState === XMLHttpRequest.DONE) {
                if (sigpacXhr.status === 200) {
                    try {
                        var response = JSON.parse(sigpacXhr.responseText);
                        if (Array.isArray(response) && response.length > 0 && response[0].wkt) {
                            // Get the centroid from the WKT for tile calculation
                            var centerCoords = getCenterFromWKT(response[0].wkt);
                            
                            if (centerCoords) {
                                // Now use these coordinates to determine the correct tiles
                                queryTilesFromCoordinates(pr, mu, po, pa, re, centerCoords);
                                return;
                            }
                        }
                        console.error("Failed to get valid geometry from SIGPAC response, trying with default Spain-centered tile area");
                        // If we couldn't get specific coordinates, query a range of default tiles
                        queryDefaultTiles(pr, mu, po, pa, re);
                    } catch (e) {
                        console.error("Error parsing SIGPAC geometry data:", e);
                        // If parsing failed, query default tiles
                        queryDefaultTiles(pr, mu, po, pa, re);
                    }
                } else {
                    console.error("Error loading SIGPAC geometry. Status:", sigpacXhr.status);
                    // If request failed, query default tiles
                    queryDefaultTiles(pr, mu, po, pa, re);
                }
            }
        };
        
        try {
            sigpacXhr.open("GET", sigpacUrl);
            sigpacXhr.send();
        } catch (e) {
            console.error("Error sending SIGPAC geometry request:", e);
            // If request failed, query default tiles
            queryDefaultTiles(pr, mu, po, pa, re);
        }
    }
    
    // Function to query cultivo data by coordinates
    function queryByCoordinates(srid, x, y) {
        console.log("Querying Cultivo Declarado with coordinates: SRID=" + srid + ", X=" + x + ", Y=" + y);
        
        // Reset data and attempts
        cultivoDeclaradoData = null;
        isLoading = true;
        loadingChanged(true);
        resetRequestAttempts();
        
        // First query the SIGPAC service to get the parcel code
        var sigpacUrl = "https://sigpac-hubcloud.es/servicioconsultassigpac/query/recinfobypoint/" + srid + "/" + x + "/" + y + ".json";
        
        var sigpacXhr = new XMLHttpRequest();
        sigpacXhr.onreadystatechange = function() {
            if (sigpacXhr.readyState === XMLHttpRequest.DONE) {
                if (sigpacXhr.status === 200) {
                    try {
                        var response = JSON.parse(sigpacXhr.responseText);
                        if (Array.isArray(response) && response.length > 0) {
                            var item = response[0];
                            if (item.provincia !== undefined && 
                                item.municipio !== undefined && 
                                item.poligono !== undefined && 
                                item.parcela !== undefined && 
                                item.recinto !== undefined) {
                                
                                // We already have the coordinates, use them directly to determine tiles
                                var coords = { x: parseFloat(x), y: parseFloat(y) };
                                queryTilesFromCoordinates(item.provincia, item.municipio, 
                                                        item.poligono, item.parcela, item.recinto, 
                                                        coords);
                                return;
                            }
                        }
                        console.error("Failed to get valid SIGPAC code from coordinates");
                        isLoading = false;
                        loadingChanged(false);
                        errorOccurred("No se encontró parcela SIGPAC en estas coordenadas");
                    } catch (e) {
                        console.error("Error parsing SIGPAC coordinate data:", e);
                        isLoading = false;
                        loadingChanged(false);
                        errorOccurred("Error al procesar datos SIGPAC: " + e);
                    }
                } else {
                    console.error("Error loading SIGPAC data. Status:", sigpacXhr.status);
                    isLoading = false;
                    loadingChanged(false);
                    errorOccurred("Error al cargar datos SIGPAC: " + sigpacXhr.status);
                }
            }
        };
        
        try {
            sigpacXhr.open("GET", sigpacUrl);
            sigpacXhr.send();
        } catch (e) {
            console.error("Error sending SIGPAC coordinate request:", e);
            isLoading = false;
            loadingChanged(false);
            errorOccurred("Error al enviar solicitud de coordenadas: " + e);
        }
    }
    
    // Reset the request attempts tracker
    function resetRequestAttempts() {
        requestAttempts = {
            count: 0,
            maxAttempts: 9,
            processedTiles: {}
        };
    }
    
    // Extract center coordinates from WKT
    function getCenterFromWKT(wkt) {
        try {
            console.log("Extracting center from WKT:", wkt);
            
            // Extract coordinates from the WKT - handle different WKT formats
            var coordsMatch;
            if (wkt.includes("POLYGON")) {
                // Regular polygon format: POLYGON((x1 y1, x2 y2, ...))
                coordsMatch = wkt.match(/\(\((.*?)\)\)/);
            } else if (wkt.includes("MULTIPOLYGON")) {
                // Multipolygon format: MULTIPOLYGON(((x1 y1, x2 y2, ...)))
                coordsMatch = wkt.match(/\(\(\((.*?)\)\)\)/);
            } else {
                coordsMatch = null;
            }
            
            if (coordsMatch && coordsMatch[1]) {
                var coordsStr = coordsMatch[1];
                var coordsPairs = coordsStr.split(',');
                
                console.log("Found coordinate pairs:", coordsPairs.length);
                
                // Calculate centroid by averaging all coordinates
                var sumX = 0;
                var sumY = 0;
                var pointCount = 0;
                
                for (var i = 0; i < coordsPairs.length; i++) {
                    var pair = coordsPairs[i].trim().split(' ');
                    if (pair.length >= 2) {
                        var x = parseFloat(pair[0]);
                        var y = parseFloat(pair[1]);
                        
                        if (!isNaN(x) && !isNaN(y)) {
                            sumX += x;
                            sumY += y;
                            pointCount++;
                        }
                    }
                }
                
                if (pointCount > 0) {
                    var center = {
                        x: sumX / pointCount,
                        y: sumY / pointCount
                    };
                    
                    console.log("Calculated center:", center.x, center.y);
                    return center;
                }
            }
            
            console.log("Failed to extract coordinates from WKT");
            return null;
        } catch (e) {
            console.error("Error extracting center from WKT:", e);
            return null;
        }
    }
    
    // Function to query tiles using coordinates
    function queryTilesFromCoordinates(pr, mu, po, pa, re, coords) {
        console.log("Querying tiles based on coordinates:", coords.x, coords.y);
        
        // The zoom level QGIS uses
        var zoom = 15;
        
        // Calculate tile coordinates from center
        var tileX = calculateTileX(coords.x, zoom);
        var tileY = calculateTileY(coords.y, zoom);
        
        console.log("Calculated tile coordinates for this parcel:", tileX, tileY);
        
        // Try the central tile first
        tryGeoJsonTile(pr, mu, po, pa, re, tileX, tileY, zoom);
    }
    
    // Function to query default tiles covering Spain
    function queryDefaultTiles(pr, mu, po, pa, re) {
        console.log("Querying default tiles covering Spain");
        
        // Default tiles that cover much of Spain
        var defaultTiles = [
            { x: 16181, y: 12778, z: 15 }, // Known to work in Almería
            { x: 16181, y: 12779, z: 15 }, // Adjacent tile
            { x: 16036, y: 12420, z: 15 }, // Another area in Spain
            { x: 15921, y: 12265, z: 15 }  // Another area in Spain
        ];
        
        // Try the first default tile
        var tile = defaultTiles[0];
        tryGeoJsonTile(pr, mu, po, pa, re, tile.x, tile.y, tile.z);
    }
    
    // Try a specific GeoJSON tile
    function tryGeoJsonTile(pr, mu, po, pa, re, tileX, tileY, zoom) {
        // Skip if we've already tried this tile or reached max attempts
        var tileKey = tileX + "," + tileY + "," + zoom;
        if (requestAttempts.processedTiles[tileKey] || requestAttempts.count >= requestAttempts.maxAttempts) {
            // If we've tried all allowed tiles, report error
            if (requestAttempts.count >= requestAttempts.maxAttempts) {
                console.log("Reached maximum number of tile attempts");
                isLoading = false;
                loadingChanged(false);
                errorOccurred("No se encontraron datos de cultivo declarado para esta parcela después de intentar múltiples ubicaciones");
                return;
            }
            
            // Try adjacent tiles
            tryAdjacentTiles(pr, mu, po, pa, re, tileX, tileY, zoom);
            return;
        }
        
        // Mark this tile as processed and increment counter
        requestAttempts.processedTiles[tileKey] = true;
        requestAttempts.count++;
        
        var geojsonUrl = mvtBaseUrl + "/cultivo_declarado@3857@geojson/" + zoom + "/" + tileX + "/" + tileY + ".geojson";
        console.log("Trying tile " + requestAttempts.count + ": X=" + tileX + ", Y=" + tileY + ", Z=" + zoom);
        
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        
                        if (response.features && Array.isArray(response.features) && response.features.length > 0) {
                            console.log("Found features in tile " + tileX + "," + tileY + ":", response.features.length);
                            
                            // Filter for specific parcel if needed
                            var filteredFeatures = response.features;
                            if (pr && mu && po && pa && re) {
                                filteredFeatures = response.features.filter(function(feature) {
                                    var props = feature.properties;
                                    
                                    // Try different property formats
                                    if ((props.provincia == pr || props.exp_provincia == pr) && 
                                        props.municipio == mu && 
                                        (props.poligono == po || parseInt(props.poligono) == parseInt(po)) && 
                                        (props.parcela == pa || parseInt(props.parcela) == parseInt(pa)) && 
                                        (props.recinto == re || parseInt(props.recinto) == parseInt(re))) {
                                        return true;
                                    }
                                    
                                    return false;
                                });
                            }
                            
                            if (filteredFeatures.length > 0) {
                                cultivoDeclaradoData = filteredFeatures;
                                console.log("Found matching features:", cultivoDeclaradoData.length);
                                isLoading = false;
                                loadingChanged(false);
                                dataLoaded(cultivoDeclaradoData);
                                return;
                            } else {
                                console.log("No features match our criteria in this tile");
                                tryAdjacentTiles(pr, mu, po, pa, re, tileX, tileY, zoom);
                            }
                        } else {
                            console.log("No features found in tile " + tileX + "," + tileY);
                            tryAdjacentTiles(pr, mu, po, pa, re, tileX, tileY, zoom);
                        }
                    } catch (e) {
                        console.error("Error parsing GeoJSON data:", e);
                        tryAdjacentTiles(pr, mu, po, pa, re, tileX, tileY, zoom);
                    }
                } else {
                    console.log("Failed to load GeoJSON for tile " + tileX + "," + tileY + ". Status: " + xhr.status);
                    tryAdjacentTiles(pr, mu, po, pa, re, tileX, tileY, zoom);
                }
            }
        };
        
        // Add QGIS-like headers
        var headers = {
            "User-Agent": "Mozilla/5.0 QGIS/33404/Linux",
            "referer": ""
        };
        
        try {
            xhr.open("GET", geojsonUrl);
            
            // Add headers
            for (var header in headers) {
                xhr.setRequestHeader(header, headers[header]);
            }
            
            xhr.send();
        } catch (e) {
            console.error("Error sending GeoJSON request:", e);
            tryAdjacentTiles(pr, mu, po, pa, re, tileX, tileY, zoom);
        }
    }
    
    // Try adjacent tiles in a spiral pattern
    function tryAdjacentTiles(pr, mu, po, pa, re, centerX, centerY, zoom) {
        // Try surrounding tiles in a spiral pattern
        var adjacentOffsets = [
            {dx: 0, dy: -1},  // Up
            {dx: 1, dy: 0},   // Right
            {dx: 0, dy: 1},   // Down
            {dx: -1, dy: 0},  // Left
            {dx: 1, dy: -1},  // Upper right
            {dx: 1, dy: 1},   // Lower right
            {dx: -1, dy: 1},  // Lower left
            {dx: -1, dy: -1}  // Upper left
        ];
        
        // Try each adjacent tile
        for (var i = 0; i < adjacentOffsets.length; i++) {
            var offset = adjacentOffsets[i];
            var tileX = centerX + offset.dx;
            var tileY = centerY + offset.dy;
            
            // Skip if we've already tried this tile
            var tileKey = tileX + "," + tileY + "," + zoom;
            if (!requestAttempts.processedTiles[tileKey] && requestAttempts.count < requestAttempts.maxAttempts) {
                tryGeoJsonTile(pr, mu, po, pa, re, tileX, tileY, zoom);
                return;
            }
        }
        
        // If we get here, we've tried all adjacent tiles without success
        console.log("Tried all adjacent tiles without finding data");
        isLoading = false;
        loadingChanged(false);
        errorOccurred("No se encontraron datos de cultivo declarado para esta parcela");
    }
    
    // Helper function to calculate tile X coordinate from longitude
    function calculateTileX(lon, zoom) {
        // Handle Web Mercator coordinates (EPSG:3857) as well as lon/lat
        if (Math.abs(lon) > 180) {
            // Looks like Web Mercator, convert to lon/lat first
            lon = (lon / 20037508.34) * 180;
        }
        
        // Ensure lon is a valid number
        if (isNaN(lon)) {
            console.error("Invalid longitude for tile calculation:", lon);
            return 16181; // Fallback to a tile in Spain
        }
        
        // Ensure lon is within bounds
        lon = Math.max(Math.min(lon, 180), -180);
        
        var tileX = Math.floor((lon + 180) / 360 * Math.pow(2, zoom));
        console.log("Calculated tileX:", tileX, "from lon:", lon);
        return tileX;
    }
    
    // Helper function to calculate tile Y coordinate from latitude
    function calculateTileY(lat, zoom) {
        // Handle Web Mercator coordinates (EPSG:3857) as well as lon/lat
        if (Math.abs(lat) > 90) {
            // Looks like Web Mercator, convert to lon/lat first
            lat = Math.atan(Math.exp(lat / 20037508.34 * Math.PI)) * 360 / Math.PI - 90;
        }
        
        // Ensure lat is a valid number
        if (isNaN(lat)) {
            console.error("Invalid latitude for tile calculation:", lat);
            return 12778; // Fallback to a tile in Spain
        }
        
        // Ensure lat is within bounds
        lat = Math.max(Math.min(lat, 85.0511), -85.0511);
        
        var tileY = Math.floor((1 - Math.log(Math.tan(lat * Math.PI / 180) + 1 / Math.cos(lat * Math.PI / 180)) / Math.PI) / 2 * Math.pow(2, zoom));
        console.log("Calculated tileY:", tileY, "from lat:", lat);
        return tileY;
    }
    
    // Helper function to format the cultivo declarado data for display
    function formatCultivoDeclaradoData(data) {
        if (!data || (Array.isArray(data) && data.length === 0)) {
            return "No se encontraron datos de cultivo declarado para esta parcela";
        }
        
        var result = "";
        
        // Map of product codes to descriptions
        var productDict = {
            "1": "Trigo blando",
            "2": "Trigo duro",
            "3": "Cebada",
            "4": "Avena",
            "5": "Centeno",
            "6": "Triticale",
            "7": "Maíz",
            "8": "Sorgo",
            "11": "Arroz",
            "21": "Girasol",
            "22": "Colza",
            "23": "Soja",
            "40": "Alfalfa",
            "41": "Veza",
            "50": "Patata",
            "51": "Remolacha",
            "61": "Algodón",
            "77": "Olivar",
            "78": "Viñedo vinificación",
            "82": "Almendros",
            "83": "Cítricos",
            "152": "Hortícolas", // Adding the crop code from your example
            "201": "Pasto con arbolado",
            "202": "Pasto arbustivo",
            "203": "Pastizal"
        };
        
        // Map of aid codes to descriptions
        var aidDict = {
            "PGBC": "Pago Básico",
            "AYAC": "Ayuda Asociada Cultivos",
            "AYAG": "Ayuda Asociada Ganadería",
            "RVPA": "Eco-régimen Pastos",
            "RVCA": "Eco-régimen Cultivos Aromáticas",
            "RVCH": "Eco-régimen Cultivos Herbáceos",
            "RVCL": "Eco-régimen Cultivos Leñosos",
            "ESCA": "Espacios de Biodiversidad",
            "18": "Ayuda 18" // Adding code from your example
        };
        
        // Process the features
        var items = [];
        
        if (Array.isArray(data)) {
            // Extract properties from features
            items = data.map(function(feature) { return feature.properties; });
        } else if (typeof data === 'object') {
            // Single object
            items = [data.properties || data];
        }
        
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            
            result += "CULTIVO DECLARADO (" + (i + 1) + "/" + items.length + "):\n";
            
            // Debug information about raw properties
            if (item) {
                result += "  IDENTIFICACIÓN PARCELA:\n";
                if (item.provincia !== undefined) result += "    Provincia: " + item.provincia + "\n";
                if (item.municipio !== undefined) result += "    Municipio: " + item.municipio + "\n";
                if (item.poligono !== undefined) result += "    Polígono: " + item.poligono + "\n";
                if (item.parcela !== undefined) result += "    Parcela: " + item.parcela + "\n";
                if (item.recinto !== undefined) result += "    Recinto: " + item.recinto + "\n";
                if (item.agregado !== undefined) result += "    Agregado: " + item.agregado + "\n";
                if (item.zona !== undefined) result += "    Zona: " + item.zona + "\n";
                result += "\n";
            } else {
                result += "  ERROR: Datos de parcela no disponibles\n\n";
                continue; // Skip to next item if this one has no properties
            }
            
            // Expediente info
            result += "  DATOS EXPEDIENTE:\n";
            if (item.exp_num !== undefined && item.exp_ca !== undefined && item.exp_ano !== undefined) {
                result += "    Expediente: " + item.exp_num + "\n";
                result += "    Comunidad Autónoma: " + item.exp_ca + "\n";
                result += "    Año: " + item.exp_ano + "\n";
                if (item.exp_provincia !== undefined) {
                    result += "    Provincia expediente: " + item.exp_provincia + "\n";
                }
            } else {
                result += "    No disponible\n";
            }
            
            // Producto y ayudas
            result += "  CULTIVO PRINCIPAL:\n";
            if (item.parc_producto !== undefined) {
                var productName = productDict[item.parc_producto] || item.parc_producto;
                result += "    Producto: " + productName + " (" + item.parc_producto + ")\n";
            } else {
                result += "    Producto: No declarado\n";
            }
            
            // Sistema de explotación
            if (item.parc_sistexp !== undefined) {
                var sistExp = item.parc_sistexp === "S" ? "Secano" : 
                             (item.parc_sistexp === "R" ? "Regadío" : item.parc_sistexp);
                result += "    Sistema de explotación: " + sistExp + "\n";
            }
            
            // Superficie
            if (item.parc_supcult !== undefined) {
                // parc_supcult is in áreas (0.01 ha), convert to hectares
                var superficieHa = parseFloat(item.parc_supcult) / 100;
                result += "    Superficie declarada: " + superficieHa.toFixed(4) + " ha\n";
            }
            
            // Ayudas solicitadas
            if (item.parc_ayudasol !== undefined && item.parc_ayudasol !== null && item.parc_ayudasol !== "") {
                result += "    Ayudas solicitadas:\n";
                try {
                    var ayudas = String(item.parc_ayudasol).split(",");
                    for (var j = 0; j < ayudas.length; j++) {
                        var aid = ayudas[j].trim();
                        var aidDesc = aidDict[aid] || aid;
                        result += "      - " + aidDesc + "\n";
                    }
                } catch (e) {
                    result += "      Error al procesar ayudas: " + e + "\n";
                }
            }
            
            // PDR
            if (item.pdr_rec !== undefined && item.pdr_rec !== null && item.pdr_rec !== "") {
                result += "    Ayudas PDR:\n";
                try {
                    var pdrAyudas = String(item.pdr_rec).split(",");
                    for (var j = 0; j < pdrAyudas.length; j++) {
                        result += "      - " + pdrAyudas[j].trim() + "\n";
                    }
                } catch (e) {
                    result += "      Error al procesar PDR: " + e + "\n";
                }
            }
            
            // Cultivo secundario
            if (item.cultsecun_producto !== undefined && item.cultsecun_producto !== null && item.cultsecun_producto !== "") {
                result += "  CULTIVO SECUNDARIO:\n";
                var secProductName = productDict[item.cultsecun_producto] || item.cultsecun_producto;
                result += "    Producto: " + secProductName + " (" + item.cultsecun_producto + ")\n";
                
                if (item.cultsecun_ayudasol !== undefined && item.cultsecun_ayudasol !== null && item.cultsecun_ayudasol !== "") {
                    result += "    Ayudas solicitadas:\n";
                    try {
                        var secAyudas = String(item.cultsecun_ayudasol).split(",");
                        for (var j = 0; j < secAyudas.length; j++) {
                            var secAid = secAyudas[j].trim();
                            var secAidDesc = aidDict[secAid] || secAid;
                            result += "      - " + secAidDesc + "\n";
                        }
                    } catch (e) {
                        result += "      Error al procesar ayudas secundarias: " + e + "\n";
                    }
                }
            }
            
            // Aprovechamiento
            if (item.tipo_aprovecha !== undefined && item.tipo_aprovecha !== null && item.tipo_aprovecha !== "") {
                result += "  APROVECHAMIENTO:\n";
                result += "    Tipo: " + item.tipo_aprovecha + "\n";
            }
            
            // Indicador de cultivo o aprovechamiento
            if (item.parc_indcultapro !== undefined && item.parc_indcultapro !== null && item.parc_indcultapro !== "") {
                result += "  OTROS DATOS:\n";
                result += "    Indicador cultivo/aprovechamiento: " + item.parc_indcultapro + "\n";
            }
            
            // Add raw data in debug mode
            result += "\n  DATOS DE SISTEMA:\n";
            for (var key in item) {
                if (item.hasOwnProperty(key) && item[key] !== undefined && item[key] !== null) {
                    result += "    " + key + ": " + item[key] + "\n";
                }
            }
            
            if (i < items.length - 1) {
                result += "\n  ---\n\n";
            }
        }
        
        return result;
    }
} 