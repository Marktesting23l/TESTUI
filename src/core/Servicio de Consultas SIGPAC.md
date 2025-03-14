Servicio de Consultas SIGPAC

    PROPIEDADES DE RECINTO POR COORDENADAS

    Esta consulta devuelve las propiedades registradas en SIGPAC del recinto que contiene el punto que se envía como parámetro.

    Existen dos tipos de peticiones, de tipo REST, que serán atendidas por este servicio:
        https://sigpac-hubcloud.es/servicioconsultassigpac/query/recinfobypoint/[srid]/[x]/[y].json
        https://sigpac-hubcloud.es/servicioconsultassigpac/query/recinfobypoint/[srid]/[x]/[y].geojson

    Donde:
        [srid]: SRID del sistema de referencia en que se expresan las coordenadas del punto a consultar y en el que serán devueltas las coordenadas de los recintos encontrados.
        [x]: coordenada x del punto a consultar
        [y]: coordenada y del punto a consultar

    Dichas llamadas obtienen como resultado uno o varios objetos que contienen las propiedades del recinto o recintos que contienen al punto enviado como parámetro en la llamada.

    En la primera de las llamadas el resultado será una colección de objetos en formato JSON y en la segunda un objeto en formato GeoJSON (ambos resultados llevarán compresión gzip).

    Nota: En el caso de llamadas de tipo JSON los resultados serán del tipo:

    Si el resultado es 0 geometrías, se recibe un array o colección de elementos con 0 (cero) elementos:

    [ ]

    Si el resultado es 1 geometría, el array o colección tendrá un único elemento de la forma:

    [

    {

    "provincia": 31,

    "municipio": 192,

    "agregado": 0,

    "agregado": 0,

    "agregado": 0,

    "zona": 0,

    "poligono": 5,

    "parcela": 83,

    "recinto": 1,

    "superficie": 9.4722,

    "pendiente_media": 11.4,

    "coef_regadio": 0,

    "admisibilidad": 0,

    "incidencias": null,

    "uso_sigpac": "FO",

    "region": null,

    "wkt": "POLYGON(...)",

    "srid": 4258

    }

    ]

    Si el resultado son 2 ó más geometrías, el array o colección contendrá un elemento por cada geometría:

    [

    {

    "provincia": 31,

    "municipio": 192,

    "agregado": 0,

    "zona": 0,

    "poligono": 5,

    "parcela": 83,

    "recinto": 1,

    "superficie": 9.4722,

    "pendiente_media": 11.4,

    "coef_regadio": 0,

    "admisibilidad": 0,

    "incidencias": null,

    "uso_sigpac": "FO",

    "region": null,

    "wkt": "POLYGON(...)",

    "srid": 4258

    }

    "provincia": 31,

    "municipio": 192,

    "agregado": 0,

    "zona": 0,

    "poligono": 5,

    "parcela": 83,

    "recinto": 2,

    "superficie": 0.0581,

    "pendiente_media": 24.9,

    "coef_regadio": 0,

    "admisibilidad": 0,

    "incidencias": null,

    "uso_sigpac": "TA",

    "region": 0701,

    "wkt": "POLYGON(...)",

    "srid": 4258

    ]

    Donde:
        provincia: código de la provincia.
        municipio: código del municipio SIGPAC.
        agregado: código del agregado.
        zona: código de la zona.
        poligono: número del polígono.
        parcela: número de la parcela.
        recinto: código del recinto SIGPAC.
        superficie: superficie del recinto expresado en hectáreas.
        pendiente_media: pendiente media del recinto.
        coef_regadio: coeficiente de regadío del recinto.
        admisibilidad: porcentaje de admisibilidad de aplicación en los recintos de pastos.
        incidencias: códigos de las incidencias del recinto separados por comas.
        uso_sigpac: código de uso del recinto.
        region: código de la región asignada al recinto.
        wkt: coordenadas que definen el recinto en formato WKT.
        srid: srid o código EPSG en el que están expresadas las coordenadas del recinto definido en el campo wkt.
