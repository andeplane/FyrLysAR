import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import HeightReader 1.0
import QtPositioning

import "qrc:/"

Window {
    id: root
    width: 720
    height: 1280
    visible: true
    property alias debug: settings.debug

    Settings {
        property alias useHardCodedPosition: settings.useHardCodedPosition
        property alias hardcodedLongitude: settings.hardcodedLongitude
        property alias hardcodedLatitude: settings.hardcodedLatitude
    }

    ARViewer {
        id: mainView
        debug: root.debug
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

    // Button {
    //     id: button
    //     onClicked: {
    //         // 59.87493, 10.646793333333333, 3 vs 58.9952381, 11.0584886, NaN
    //         let source = QtPositioning.coordinate(59.87493, 10.646793333333333, 3)
    //         let target = QtPositioning.coordinate(58.9952381, 11.0584886, 2)
    //         console.log(`Checking ${source.latitude}, ${source.longitude}, ${source.altitude} vs ${target.latitude}, ${target.longitude}, ${target.altitude} with distance ${source.distanceTo(target)}. Hidden by land: ${!heightReader.lineIsAboveLand(source, target)}`);
    //         console.log("Height source: ", heightReader.findHeight(source))
    //         console.log("Height target: ", heightReader.findHeight(target))
    //         console.log(heightReader.lineIsAboveLand(source, target))
    //         // source = QtPositioning.coordinate(58.994165, 11.068447, 0)
    //         // console.log(heightReader.findHeight(source))

    //     }
    // }

    // HeightReader {
    //     id: heightReader
    // }
}
