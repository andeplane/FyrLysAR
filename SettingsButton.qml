import QtQuick

Rectangle {
    Image {
        anchors.centerIn: parent
        width: 32
        height: 32
        source: "qrc:/images/gear.svg"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (stack.depth === 1) {
                    stack.push(settings)
                } else {
                    stack.pop()
                }
            }
        }
    }
}
