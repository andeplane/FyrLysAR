import QtQuick

Rectangle {
    property bool isMapMode: false
    
    Image {
        id: gearIcon
        anchors.centerIn: parent
        width: 33
        height: 33
        source: {
            if (isMapMode) {
                return "qrc:/images/gear.svg"  // Map mode: always use dark gear
            } else {
                // AR mode: use white gear only in dark mode
                var isDarkMode = (palette.window.r + palette.window.g + palette.window.b) / 3 < 0.5
                return isDarkMode ? "qrc:/images/gear-white.svg" : "qrc:/images/gear.svg"
            }
        }
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
