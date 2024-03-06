import QtQuick

Rectangle {
    id: infoBox
    property var lighthouse

    height: 90
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    color: Qt.rgba(1.0, 1.0, 1.0, 0.7)
    visible: false

    Column {
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
    }

    Sector {
        id: sector
        width: 70
        height: 70

        anchors.rightMargin: 10
        anchors.topMargin: 10
        anchors.right: parent.right
        anchors.top: parent.top
        lighthouse: infoBox.lighthouse
    }
}
