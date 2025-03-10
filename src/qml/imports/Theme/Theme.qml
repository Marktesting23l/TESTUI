pragma Singleton
import QtQuick
import QtQuick.Controls.Material

QtObject {
  id: object

  property var darkThemeColors: {
    "mainColor": "#FFA500", // Orange
    "mainOverlayColor": "#25062d",
    "accentColor": "#FF8C00", // Dark Orange
    "accentLightColor": "#99FF8C00", // Light Orange with transparency
    "mainBackgroundColor": "#3E2723", // Dark Brown
    "mainBackgroundColorSemiOpaque": "#bb3E2723",
    "mainTextColor": "#F5F5DC", // Beige instead of white
    "mainTextDisabledColor": "#73F5F5DC",
    "secondaryTextColor": "#E8E4C9", // Light beige
    "controlBackgroundColor": "#4E342E", // Brown
    "controlBackgroundAlternateColor": "#5D4037", // Lighter Brown
    "controlBackgroundDisabledColor": "#33555555",
    "controlBorderColor": "#6D4C41", // Medium Brown
    "buttonTextColor": "#F5F5DC", // Beige instead of white
    "toolButtonColor": "#FFE0B2", // Light orange for icons
    "toolButtonBackgroundColor": "#5D4037", // Brown
    "toolButtonBackgroundSemiOpaqueColor": "#4D5D4037",
    "scrollBarBackgroundColor": "#bb3E2723"
  }

  property var lightThemeColors: {
    "mainColor": "#FFA500", // Orange
    "mainOverlayColor": "#FFF8E1", // Very light orange
    "accentColor": "#FF8C00", // Dark Orange
    "accentLightColor": "#99FF8C00", // Light Orange with transparency
    "mainBackgroundColor": "#FFF3E0", // Very light orange background
    "mainBackgroundColorSemiOpaque": "#bbFFF3E0",
    "mainTextColor": "#3E2723", // Dark Brown for good contrast
    "mainTextDisabledColor": "#733E2723",
    "secondaryTextColor": "#5D4037", // Medium Brown
    "controlBackgroundColor": "#FFECB3", // Light Orange
    "controlBackgroundAlternateColor": "#FFE0B2", // Lighter Orange
    "controlBackgroundDisabledColor": "#33555555",
    "controlBorderColor": "#FFCC80", // Medium Light Orange
    "buttonTextColor": "#3E2723", // Dark Brown for good contrast
    "toolButtonColor": "#5D4037", // Brown for icons
    "toolButtonBackgroundColor": "#FFE0B2", // Light Orange
    "toolButtonBackgroundSemiOpaqueColor": "#4DFFE0B2",
    "scrollBarBackgroundColor": "#aaFFF3E0"
  }

  property bool darkTheme: false

  // Default properties that will be overridden by applyColors
  property color mainColor: "#FFA500" // Orange
  property color mainOverlayColor: darkTheme ? "#25062d" : "#FFF8E1"
  property color accentColor: "#FF8C00" // Dark Orange
  property color accentLightColor: "#99FF8C00" // Light Orange with transparency

  property color mainBackgroundColor: darkTheme ? "#3E2723" : "#FFF3E0"
  property color mainBackgroundColorSemiOpaque: darkTheme ? "#bb3E2723" : "#bbFFF3E0"
  property color mainTextColor: darkTheme ? "#F5F5DC" : "#3E2723"
  property color mainTextDisabledColor: darkTheme ? "#73F5F5DC" : "#733E2723"

  property color secondaryTextColor: darkTheme ? "#E8E4C9" : "#5D4037"

  property color controlBackgroundColor: darkTheme ? "#4E342E" : "#FFECB3"
  property color controlBackgroundAlternateColor: darkTheme ? "#5D4037" : "#FFE0B2"
  property color controlBackgroundDisabledColor: "#33555555"
  property color controlBorderColor: darkTheme ? "#6D4C41" : "#FFCC80"

  property color buttonTextColor: darkTheme ? "#F5F5DC" : "#3E2723"

  property color toolButtonColor: darkTheme ? "#FFE0B2" : "#5D4037"
  property color toolButtonBackgroundColor: darkTheme ? "#5D4037" : "#FFE0B2"
  property color toolButtonBackgroundSemiOpaqueColor: darkTheme ? "#4D5D4037" : "#4DFFE0B2"

  property color scrollBarBackgroundColor: darkTheme ? "#bb3E2723" : "#aaFFF3E0"

  // Standard colors
  property color darkRed: "#c33626"
  property color darkGray: "#5d4037" // Brown instead of gray to match theme
  property color darkGraySemiOpaque: "#4D5D4037"
  property color gray: "#8D6E63" // Brown-gray
  property color lightGray: "#D7CCC8" // Light brown-gray
  property color lightestGray: "#EFEBE9" // Very light brown-gray
  property color light: "#F5F5DC" // Beige instead of white

  property color errorColor: "#c0392b"
  property color warningColor: "#F57C00" // Darker orange for warning
  property color cloudColor: "#4c6dac"

  // GPS position colors with better state differentiation
  property color positionColor: "#FF8C00" // Dark Orange to match theme
  property color positionColorActive: "#8020db" // Brighter orange for active state
  property color positionColorInactive: "#b88d7d" // Brown-gray for inactive state
  property color positionColorSemiOpaque: "#99FF8C00"
  property color positionBackgroundColor: "#33FF8C00"
  property color positionBackgroundActiveColor: "#66FFA500" // More opaque for active state
  property color darkPositionColor: "#8e5d05bc" // Darker orange
  property color darkPositionColorSemiOpaque: "#88E65100"

  property color accuracyBad: "#c0392b"
  property color accuracyTolerated: "#F57C00" // Darker orange
  property color accuracyExcellent: "#4CAF50" // Green for excellent accuracy

  // Navigation colors changed to dark green
  property color navigationColor: "#2E7D32" // Dark Green
  property color navigationColorSemiOpaque: "#992E7D32"
  property color navigationBackgroundColor: "#332E7D32"

  property color sensorBackgroundColor: "#33999999"

  property color bookmarkDefault: "#FFA500" // Orange to match theme
  property color bookmarkOrange: "#FF8C00" // Dark Orange
  property color bookmarkRed: "#c0392b"
  property color bookmarkBlue: "#64b5f6"

  property color vertexColor: "#9441e6"
  property color vertexColorSemiOpaque: "#40cb4ce4"
  property color vertexSelectedColor: "#0000FF"
  property color vertexSelectedColorSemiOpaque: "#200000FF"
  property color vertexNewColor: "#FFA500" // Orange to match theme
  property color vertexNewColorSemiOpaque: "#40FFA500"

  property color processingPreview: '#99000000'

  property real fontScale: 1.0

  property font defaultFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale,
      "weight": Font.Normal
    })
  property font tinyFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale * 0.75,
      "weight": Font.Normal
    })
  property font tipFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale * 0.875,
      "weight": Font.Normal
    })
  property font resultFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale * 0.8125,
      "weight": Font.Normal
    })
  property font strongFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale,
      "bold": true,
      "weight": Font.Bold
    })
  property font strongTipFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale * 0.875,
      "bold": true,
      "weight": Font.Bold
    })
  property font secondaryTitleFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale * 1.125,
      "weight": Font.Normal
    })
  property font titleFont: Qt.font({
      "pointSize": systemFontPointSize * fontScale * 1.25,
      "weight": Font.Normal
    })

  readonly property int popupScreenEdgeMargin: 40

  readonly property int menuItemIconlessLeftPadding: 52
  readonly property int menuItemLeftPadding: 12
  readonly property int menuItemCheckLeftPadding: 16

  function getThemeIcon(name) {
    var ppiName;
    if (ppi >= 360)
      ppiName = "xxxhdpi";
    else if (ppi >= 270)
      ppiName = "xxhdpi";
    else if (ppi >= 180)
      ppiName = "xhdpi";
    else if (ppi >= 135)
      ppiName = "hdpi";
    else
      ppiName = "mdpi";
    var theme = 'sigpacgo';
    var path = 'qrc:/themes/' + theme + '/' + ppiName + '/' + name + '.png';
    return path;
  }

  function getThemeVectorIcon(name) {
    var theme = 'sigpacgo';
    var path = 'qrc:/themes/' + theme + '/nodpi/' + name + '.svg';
    return path;
  }

  function colorToHtml(color) {
    return "rgba(%1,%2,%3,%4)".arg(Math.floor(Theme.errorColor.r * 255)).arg(Math.floor(Theme.errorColor.g * 255)).arg(Math.floor(Theme.errorColor.b * 255)).arg(Math.floor(Theme.errorColor.a * 255));
  }

  function toInlineStyles(styleProperties) {
    var styles = '';
    for (var property in styleProperties) {
      var value = styleProperties[property];
      styles += property;
      styles += ': ';
      styles += typeof value == 'color' ? colorToHtml(value) : value;
      styles += ';';
    }
    return styles;
  }

  function applyColors(colors) {
    const names = Object.keys(colors);
    for (const name of names) {
      if (object.hasOwnProperty(name)) {
        object[name] = colors[name];
      }
    }
  }

  function applyAppearance(colors, baseAppearance) {
    const appearance = baseAppearance !== undefined ? baseAppearance : settings ? settings.value('appearance', 'system') : undefined;
    if (appearance === undefined || appearance === 'system') {
      darkTheme = platformUtilities.isSystemDarkTheme();
    } else {
      darkTheme = appearance === 'dark';
    }
    Material.theme = darkTheme ? "Dark" : "Light";
    applyColors(darkTheme ? Theme.darkThemeColors : Theme.lightThemeColors);
    mainBackgroundColor = Material.backgroundColor;
    mainTextColor = Material.foreground;
    if (colors !== undefined) {
      applyColors(colors);
    }
  }

  function applyFontScale() {
    fontScale = settings ? settings.value('fontScale', 1.0) : 1.0;
  }

  Component.onCompleted: {
    applyAppearance();
    applyFontScale();
  }
}
