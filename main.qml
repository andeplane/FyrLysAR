import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings 1.0
import HeightReader 1.0
import QtPositioning

import "qrc:/"

Window {
    id: root
    width: 720
    height: 1280
    visible: true

    Settings {
        property alias useHardCodedPosition: settings.useHardCodedPosition
        property alias hardcodedLongitude: settings.hardcodedLongitude
        property alias hardcodedLatitude: settings.hardcodedLatitude
    }

    ARViewer {
        id: mainView
        useHardCodedPosition: settings.useHardCodedPosition
        hardcodedLongitude: settings.hardcodedLongitude
        hardcodedLatitude: settings.hardcodedLatitude
    }

    SettingsView {
        id: settings
    }

    StackView {
        id: stack
        initialItem: mainView
        anchors.fill: parent
    }

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

    HeightReader {
        id: heightReader
    }
}
