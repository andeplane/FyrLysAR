import QtQuick


import QtQuick.Controls

import "qrc:/"

Window {
    id: root
    width: 640
    height: 480
    visible: true

    ARViewer {
        anchors.fill: parent
    }

    Image {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 20
        width: 50
        height: 50
        source: "qrc:/images/gear.svg"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("Clicked button")
            }
        }
    }
}
