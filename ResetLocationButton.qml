import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Shapes 1.15

Rectangle {
    id: root
    radius: 5
    color: Qt.rgba(1.0, 1.0, 1.0, 0.0)
    border.color: "#000"
    border.width: 2

    readonly property string arrowFilledFileName: "qrc:/images/location-arrow-svgrepo-com.svg"
    readonly property string arrowOpenFileName: "qrc:/images/location-arrow-o-svgrepo-com.svg"


    Image {
        id: image
        source: arrowFilledFileName
        x: parent.width / 2 - image.width / 2 - 1
        y: parent.height / 2 - image.height / 2 + 1
        width: 22
        height: 22
    }
}


