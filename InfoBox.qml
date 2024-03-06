import QtQuick

Rectangle {
    id: infoBox
    property var lighthouse
    property var deviceCoordinate
    property real heading: {
        if (deviceCoordinate && lighthouse) {
            return deviceCoordinate.azimuthTo(lighthouse.coordinates) * Math.PI / 180
        }
        return 0
    }

    height: 110
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    color: Qt.rgba(1.0, 1.0, 1.0, 0.7)
    visible: false

    Column {
        leftPadding: 10
        topPadding: 5
        Row {
            Text {
                text: "Name: "
            }
            Text {
                text: infoBox.lighthouse ? infoBox.lighthouse.name : ""
            }
        }

        Row {
            Text {
                text: "Distance: "
            }
            Text {
                text: infoBox.lighthouse ? infoBox.lighthouse.distance.toFixed(0.0) + ' m' : ""
            }
        }

        Row {
            Text {
                text: "Height: "
            }
            Text {
                text: infoBox.lighthouse ? infoBox.lighthouse.heightOverSea + ' m' : ""
            }
        }

        Row {
            Text {
                text: "Heading: "
            }
            Text {
                text: Math.round(infoBox.heading / Math.PI * 180, 0)
            }
        }
    }

    Sector {
        id: sector
        property real margin: 20

        width: parent.height - 2*margin
        height: parent.height - 2*margin

        anchors.rightMargin: margin
        anchors.topMargin: margin
        anchors.leftMargin: margin
        anchors.bottomMargin: margin
        anchors.right: parent.right
        anchors.top: parent.top
        lighthouse: infoBox.lighthouse

        Rectangle {
            // Assuming you want a circle, ensure width and height are equal and based on a factor of infoBox.width
            width: 0.02 * infoBox.width
            height: width  // Makes the shape a square, which will look like a circle with the corner radius
            color: "red"

            property real outerRadius: parent.width / 2 + sector.margin / 2
            x: parent.width / 2 + outerRadius * Math.cos(heading + 0.5*Math.PI) - width / 2
            y: parent.height / 2 + outerRadius * Math.sin(heading + 0.5*Math.PI) - height / 2

            // Apply a radius to make the rectangle look like a circle
            radius: width / 2
        }
    }
}
