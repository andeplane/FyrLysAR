import QtQuick

Rectangle {
    id: root
    property var lighthouse
    property var deviceCoordinate
    property real heading: {
        if (root.deviceCoordinate && root.lighthouse) {
            const heading_value = deviceCoordinate.azimuthTo(lighthouse.coordinates) * Math.PI / 180
            return heading_value
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
                text: root.lighthouse ? root.lighthouse.name : ""
            }
        }

        Row {
            Text {
                text: "Distance: "
            }
            Text {
                text: root.lighthouse ? root.lighthouse.distance.toFixed(0.0) + ' m' : ""
            }
        }

        Row {
            Text {
                text: "Height: "
            }
            Text {
                text: root.lighthouse ? root.lighthouse.heightOverSea + ' m' : ""
            }
        }

        Row {
            Text {
                text: "Heading: "
            }
            Text {
                text: Math.round(root.heading / Math.PI * 180, 0)
            }
        }
    }

    RenderableSectors {
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
        sectors: root.lighthouse.sectors

        Rectangle {
            // Assuming you want a circle, ensure width and height are equal and based on a factor of root.width
            width: 0.02 * root.width
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
