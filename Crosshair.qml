import QtQuick

Rectangle {
    property real crosshairRadius
    anchors.centerIn: parent
    radius: width/2
    width: parent.width * crosshairRadius * 2
    height: width
    color: "transparent"
    border.color: "white"
    border.width: parent.width * 0.01

    Rectangle {
        anchors.centerIn: parent
        radius: width/2
        width: parent.parent.width * 0.01
        height: width
        color: "white"
    }
}
