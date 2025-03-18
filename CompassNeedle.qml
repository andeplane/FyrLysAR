import QtQuick 2.15
import QtQuick.Shapes 1.15

Rectangle {
    id: compassNeedle
    radius: width

    property var compassStrokeStyle
    color: "transparent"
    border.color: "transparent"
    border.width: 2

    property real circleRadius: width/2
    property real needleSize: width * 0.9

    // Outer dashed circle
    Shape {
        anchors.fill: parent
        rotation: -compassNeedle.rotation

        ShapePath {
            strokeWidth: 2
            strokeColor: "black"
            strokeStyle: compassStrokeStyle
            dashPattern: [4, 4]  // Adjust the numbers for different dash lengths/gaps
            fillColor: "transparent"

            // Draw a full circle using two arcs
            startX: circleRadius; startY: 0
            PathArc {
                x: circleRadius; y: height
                radiusX: circleRadius; radiusY: circleRadius
                useLargeArc: true
                direction: PathArc.Clockwise
            }
            PathArc {
                x: circleRadius; y: 0
                radiusX: circleRadius; radiusY: circleRadius
                useLargeArc: true
                direction: PathArc.Clockwise
            }
        }
    }
    Shape {
        anchors.fill: parent

        ShapePath {
            strokeWidth: 2
            strokeColor: "black"
            fillColor: "white"
            startX: -needleSize/8 + circleRadius; startY: circleRadius
            PathLine {
                x: circleRadius;
                y: needleSize/2 + circleRadius
            }
            PathLine {
                x: needleSize/8 + circleRadius;
                y: circleRadius
            }
            PathLine {
                x: -needleSize/8 + circleRadius;
                y: circleRadius
            }
        }

        ShapePath {
            strokeWidth: 2
            strokeColor: "black"
            fillColor: "red"
            startX: -needleSize/8 + circleRadius; startY: circleRadius
            PathLine {
                x: circleRadius;
                y: -needleSize/2 + circleRadius
            }
            PathLine {
                x: needleSize/8 + circleRadius;
                y: circleRadius
            }
            PathLine {
                x: -needleSize/8 + circleRadius;
                y: circleRadius
            }
        }
    }
}
