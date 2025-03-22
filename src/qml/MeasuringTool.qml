import QtQuick
import QtQuick.Shapes
import org.qgis
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Item {
  id: measuringTool

  property alias measuringRubberband: rubberband
  property bool isClosingArea: rubberband.model.vertexCount > 2 && vertexFirstLastDistance.screenDistance < 10
  property bool isArea: false
  
  // Property to access the project's distance units
  property var projectInfo: qgisProject ? qgisProject.projectInfo : null
  property var distanceUnits: projectInfo ? projectInfo.distanceUnits : Qgis.DistanceUnit.Meters

  // Add a TapHandler to allow direct finger tap to add vertices
  // Note: This deliberately ignores the global fingerTapDigitizing setting to provide
  // a more intuitive measuring experience on touch devices as requested by users
  TapHandler {
    id: directTapHandler
    enabled: stateMachine.state === 'measure' && !rubberband.model.frozen // Always enable in the measuring tool, regardless of global setting
    acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Mouse
    acceptedPointerTypes: PointerDevice.Finger | PointerDevice.GenericPointer
    acceptedButtons: Qt.LeftButton
    grabPermissions: PointerHandler.CanTakeOverFromHandlersOfDifferentType | PointerHandler.ApprovesTakeOverByAnything | PointerHandler.ApprovesCancellation
    
    onTapped: (eventPoint) => {
      if (enabled) {
        // Set the coordinate locator to the tapped position
        coordinateLocator.sourceLocation = eventPoint.position;
        
        // Add vertex at the tapped position after a short delay to allow coordinate locator to update
        addVertexTimer.start();
      }
    }
  }
  
  Timer {
    id: addVertexTimer
    interval: 50 // Short delay to ensure coordinate is updated
    repeat: false
    onTriggered: {
      // Add the vertex at the current coordinate
      rubberband.model.addVertex();
    }
  }

  MapToScreen {
    id: vertexFirstLastDistance
    mapSettings: rubberband.mapSettings
    mapDistance: GeometryUtils.distanceBetweenPoints(rubberband.model.firstCoordinate, rubberband.model.currentCoordinate)
  }

  // Add a DistanceArea object to calculate segment lengths
  DistanceArea {
    id: distanceArea
    rubberbandModel: rubberband.model
    crs: rubberband.mapSettings.destinationCrs
    project: qgisProject
  }

  Repeater {
    id: vertices
    model: rubberband.model.vertices
    delegate: Shape {
      id: shape
      MapToScreen {
        id: vertexToScreen
        mapSettings: rubberband.mapSettings
        mapPoint: modelData
      }

      visible: rubberband.model.vertexCount > 1

      x: vertexToScreen.screenPoint.x - width / 2
      y: vertexToScreen.screenPoint.y - width / 2

      width: isClosingArea && (index === 0 || index === rubberband.model.vertexCount - 1) ? 20 : 10
      height: width

      ShapePath {
        strokeColor: "#96ffffff"
        strokeWidth: 5
        fillColor: "transparent"
        PathAngleArc {
          centerX: shape.width / 2
          centerY: centerX
          radiusX: centerX
          radiusY: centerX
          startAngle: 0
          sweepAngle: 360
        }
      }
      ShapePath {
        strokeColor: "#96000000"
        strokeWidth: 3
        fillColor: "transparent"
        PathAngleArc {
          centerX: shape.width / 2
          centerY: centerX
          radiusX: centerX
          radiusY: centerX
          startAngle: 0
          sweepAngle: 360
        }
      }
    }
  }

  // Add segment labels
  Repeater {
    id: segmentLabels
    // We need one less label than vertices (for segments between vertices)
    model: Math.max(0, rubberband.model.vertexCount - 1)
    
    // Don't show any labels if we have too many vertices (indicates freehand drawing)
    // Freehand drawing typically adds many vertices very quickly (>100), while manual
    // vertex placement typically has far fewer vertices
    visible: rubberband.model.vertexCount < 100
    
    delegate: Item {
      id: segmentLabelItem
      // Hide labels when they go beyond available vertices
      visible: rubberband.model.vertexCount > 1 && index < rubberband.model.vertexCount - 1
      
      // Calculate the position of the current and next vertex
      property var currentVertex: rubberband.model.vertices[index]
      property var nextVertex: rubberband.model.vertices[index + 1]
      
      // Convert to screen coordinates
      MapToScreen {
        id: currentVertexToScreen
        mapSettings: rubberband.mapSettings
        mapPoint: segmentLabelItem.currentVertex
      }
      
      MapToScreen {
        id: nextVertexToScreen
        mapSettings: rubberband.mapSettings
        mapPoint: segmentLabelItem.nextVertex
      }
      
      // Calculate the midpoint of the segment
      property real midX: (currentVertexToScreen.screenPoint.x + nextVertexToScreen.screenPoint.x) / 2
      property real midY: (currentVertexToScreen.screenPoint.y + nextVertexToScreen.screenPoint.y) / 2
      
      // Calculate angle of the line segment to position label offset perpendicular to the line
      property real deltaX: nextVertexToScreen.screenPoint.x - currentVertexToScreen.screenPoint.x
      property real deltaY: nextVertexToScreen.screenPoint.y - currentVertexToScreen.screenPoint.y
      property real angle: Math.atan2(deltaY, deltaX)
      
      // Offset perpendicular to the line (alternating sides based on index for better visibility in case of parallel segments)
      property real offsetDistance: 15
      property real offsetX: (index % 2 === 0 ? -1 : 1) * Math.sin(angle) * offsetDistance
      property real offsetY: (index % 2 === 0 ? 1 : -1) * Math.cos(angle) * offsetDistance
      
      // Calculate the segment length
      property real segmentLength: calculateSegmentLength(currentVertex, nextVertex)
      
      // Format the segment length with appropriate units
      property string formattedLength: formatSegmentLength(segmentLength)
      
      // Position at the midpoint of the segment with offset
      x: midX + offsetX
      y: midY + offsetY
      
      // Segment label background
      Rectangle {
        id: labelBackground
        anchors.centerIn: parent
        width: segmentLengthText.width + 10
        height: segmentLengthText.height + 6
        color: "#ccf0f0f0"
        border.color: "#96000000"
        border.width: 1
        radius: 4
        // Add a subtle shadow for better visibility
        Rectangle {
          anchors.fill: parent
          anchors.leftMargin: -1
          anchors.topMargin: -1
          anchors.rightMargin: -3
          anchors.bottomMargin: -3
          radius: 4
          color: "#30000000"
          z: -1
        }
      }
      
      // Segment length text
      Text {
        id: segmentLengthText
        anchors.centerIn: labelBackground
        text: segmentLabelItem.formattedLength
        font.pixelSize: 12
        color: "#000000"
        font.bold: true
      }
      
      function calculateSegmentLength(vertex1, vertex2) {
        if (!vertex1 || !vertex2) return 0
        return GeometryUtils.distanceBetweenPoints(vertex1, vertex2)
      }
      
      function formatSegmentLength(length) {
        if (typeof UnitTypes !== 'undefined' && distanceUnits) {
          return UnitTypes.formatDistance(distanceArea.convertLengthMeansurement(length, distanceUnits), 2, distanceUnits)
        } else {
          return (Math.round(length * 100) / 100) + " m"
        }
      }
    }
  }

  Rubberband {
    id: rubberband
    color: '#96000000'

    model: RubberbandModel {
      frozen: false
      geometryType: isClosingArea || isArea ? Qgis.GeometryType.Polygon : Qgis.GeometryType.Line
      crs: rubberband.mapSettings.destinationCrs
    }
  }

  Connections {
    target: rubberband.model

    function onVertexCountChanged() {
      if (rubberband.model.vertexCount > 2 && vertexFirstLastDistance.screenDistance < 10) {
        isArea = true;
      } else if (rubberband.model.vertexCount <= 1) {
        isArea = false;
      }
    }
  }
}
