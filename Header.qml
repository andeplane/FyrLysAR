import QtQuick
import QtQuick.Controls

Rectangle {
    id: header
    property string text
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.left: parent.left
    height: 80
    color: "white"
    opacity: 0.8

    Label {
        text: header.text
        color: "black"
        font.pixelSize: 16 * Screen.devicePixelRatio
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
