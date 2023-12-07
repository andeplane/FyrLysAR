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

    // Settings {
    //     property alias useHardCodedPosition: settings.useHardCodedPosition
    //     property alias hardcodedLongitude: settings.hardcodedLongitude
    //     property alias hardcodedLatitude: settings.hardcodedLatitude
    // }

    // ARViewer {
    //     id: mainView
    //     useHardCodedPosition: settings.useHardCodedPosition
    //     hardcodedLongitude: settings.hardcodedLongitude
    //     hardcodedLatitude: settings.hardcodedLatitude
    // }

    // SettingsView {
    //     id: settings
    // }

    // StackView {
    //     id: stack
    //     initialItem: mainView
    //     anchors.fill: parent
    // }

    // Image {
    //     anchors.top: parent.top
    //     anchors.right: parent.right
    //     anchors.topMargin: 20
    //     anchors.rightMargin: 20
    //     width: 40
    //     height: 40
    //     source: "qrc:/images/gear.svg"
    //     MouseArea {
    //         anchors.fill: parent
    //         onClicked: {
    //             if (stack.depth === 1) {
    //                 stack.push(settings)
    //             } else {
    //                 stack.pop()
    //             }
    //         }
    //     }
    // }

    Button {
        id: button
        onClicked: {
            let source = QtPositioning.coordinate(59.000208, 11.057198, 0)
            let target = QtPositioning.coordinate(58.994308, 11.075194, 0)
            console.log("Height source: ", heightReader.findHeight(source))
            console.log("Height target: ", heightReader.findHeight(target))
            console.log(heightReader.lineIsAboveLand(source, source))
        }
    }
    HeightReader {
        id: heightReader
    }
}
