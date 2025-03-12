// This script converts municipality_data.json to the format needed for CascadeSearchPanel.qml
const fs = require('fs');

// Read the JSON file
const jsonData = fs.readFileSync('src/qml/municipality_data.json', 'utf8');
const data = JSON.parse(jsonData);

// Start building the output
let output = '    // Function to load municipality names for a province\n';
output += '    function loadMunicipalityNames(provinceCode) {\n';

// Process each province
const provinces = Object.keys(data).sort((a, b) => parseInt(a) - parseInt(b));
let isFirst = true;

for (const province of provinces) {
    // Start the if/else if block
    if (isFirst) {
        output += `        if (provinceCode === ${province}) {\n`;
        isFirst = false;
    } else {
        output += `        else if (provinceCode === ${province}) {\n`;
    }
    
    // Start the municipalityNames object
    output += '            municipalityNames = {\n';
    
    // Add each municipality
    const municipalities = Object.keys(data[province]).sort((a, b) => parseInt(a) - parseInt(b));
    for (const municipality of municipalities) {
        const name = data[province][municipality].replace(/"/g, '\\"'); // Escape quotes
        output += `                "${municipality}": "${name}",\n`;
    }
    
    // Close the municipalityNames object
    output += '            };\n';
    output += '        }\n';
}

// Add the default case
output += '        // Add a default case to handle other provinces\n';
output += '        else {\n';
output += '            // If we don\'t have data for this province, use an empty object\n';
output += '            municipalityNames = {};\n';
output += '            console.log("No municipality data available for province code: " + provinceCode);\n';
output += '        }\n';

// Close the function
output += '    }\n';

// Write the output to a file
fs.writeFileSync('municipality_function.txt', output);
console.log('Conversion complete! Check municipality_function.txt for the result.'); 