// This script converts municipality_data.json to the format needed for CascadeSearchPanel.qml
const fs = require('fs');

const jsonData = fs.readFileSync('src/qml/municipality_data.json', 'utf8');
const data = JSON.parse(jsonData);

let output = '    function loadMunicipalityNames(provinceCode) {\n';

const provinces = Object.keys(data).sort((a, b) => parseInt(a) - parseInt(b));
let isFirst = true;

for (const province of provinces) {
    if (isFirst) {
        output += `        if (provinceCode === ${province}) {\n`;
        isFirst = false;
    } else {
        output += `        else if (provinceCode === ${province}) {\n`;
    }
    
    output += '            municipalityNames = {\n';
    
    const municipalities = Object.keys(data[province]).sort((a, b) => parseInt(a) - parseInt(b));
    for (const municipality of municipalities) {
        const name = data[province][municipality].replace(/"/g, '\\"');
        output += `                "${municipality}": "${name}",\n`;
    }
    
    output += '            };\n';
    output += '        }\n';
}

output += '        else {\n';
output += '            municipalityNames = {};\n';
output += '            console.log("No municipality data available for province code: " + provinceCode);\n';
output += '        }\n';

output += '    }\n';

fs.writeFileSync('municipality_function.txt', output);
console.log('Conversion complete! Check municipality_function.txt for the result.');