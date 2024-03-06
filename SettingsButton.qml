import QtQuick

Image {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 20
    anchors.rightMargin: 20
    width: 40
    height: 40
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
