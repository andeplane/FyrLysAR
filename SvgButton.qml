import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Shapes 1.15

Rectangle {
    id: root
    width: 44
    height: 44
    radius: 5
    color: Qt.rgba(1.0, 1.0, 1.0, 0.0)
    border.color: "#000"
    border.width: 2
    property var fileName

    signal clicked()

    Image {
        id: image
        source: fileName
        anchors.fill: parent
        x: parent.width / 2 - image.width / 2 - 1
        y: parent.height / 2 - image.height / 2 + 1
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}


