import QtQuick 2.15
import QtQuick.Shapes 1.15

Rectangle {
    id: compassNeedle
    radius: width
    color: "transparent"
    border.color: "black"
    border.width: 2
    property real circleRadius: width/2
    property real needleSize: width * 0.9

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
