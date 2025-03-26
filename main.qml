import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import HeightReader 1.0
import QtPositioning
import QtSensors

import "qrc:/"

Window {
    id: root
    width: 720
    height: 1280
    visible: true
    property alias debug: settings.debug
    property var selfCoord
    property alias spritesDirty: mainView.spritesDirty

    Settings {
        property alias useHardCodedPosition: settings.useHardCodedPosition
        property alias hardcodedLongitude: settings.hardcodedLongitude
        property alias hardcodedLatitude: settings.hardcodedLatitude
        property alias selfHeight: settings.selfHeight
        onHardcodedLatitudeChanged: {
            if (useHardCodedPosition) {
                root.selfCoord = QtPositioning.coordinate(hardcodedLatitude, hardcodedLongitude, 0)
            }
        }
        onHardcodedLongitudeChanged: {
            if (useHardCodedPosition) {
                root.selfCoord = QtPositioning.coordinate(hardcodedLatitude, hardcodedLongitude, 0)
            }
        }
    }

    LighthouseProvider {
        id: lighthouseProvider
        property alias spritesDirty: mainView.spritesDirty
        // selfCoord: stack.currentItem === map ? map. : root.selfCoord
        selfCoord: root.selfCoord
    }

    HeightReader {
        id: heightReader
    }

    ARViewer {
        id: mainView
        debug: root.debug
        nearbyLighthouses: lighthouseProvider.nearbyLighthouses
        selfCoord: root.selfCoord
    }

    MapMode {
        id: map
        compassBearing: sensors.compass
        selfCoord: root.selfCoord
        onCenterChanged: {
            console.log("Got new center: ", center.latitude, center.longitude)
        }
    }

    SettingsView {
        id: settings
    }

    StackView {
        id: stack
        initialItem: mainView
        anchors.fill: parent
        onCurrentItemChanged: {
            map.resetView()
        }
    }

    SettingsButton {
        id: settingsButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10
        width: 40
        height: 40
        color: Qt.rgba(1.0, 1.0, 1.0, 0.0)
        border.color: "#000"
        border.width: stack.currentItem === map ? 2 : 0
        radius: 5
    }

    WelcomeScreen {
        id: welcomeScreen
        visible: true
        anchors.fill: parent
    }

    Sensors {
        id: sensors
        onPositionChanged: {
            let selfCoord
            if (settings.useHardCodedPosition && settings.hardcodedLatitude && settings.hardcodedLongitude) {
                selfCoord = QtPositioning.coordinate(settings.hardcodedLatitude, settings.hardcodedLongitude, 0)
            } else {
                selfCoord = position
            }

            const altitude = heightReader.findHeight(selfCoord)
            root.selfCoord = QtPositioning.coordinate(selfCoord.latitude, selfCoord.longitude, settings.selfHeight + altitude)
        }

        onAccelerometerChanged: {
            const g = 9.81;
            let thresholdTransitionToMap = g * (Math.sqrt(3) / 2);
            let thresholdTransitionToAR = g * (Math.sqrt(1) / 2);

            if (stack.currentItem === map && accelerometer.z < thresholdTransitionToAR) {
                stack.replace(mainView);
            }
            else if (stack.currentItem === mainView && accelerometer.z > thresholdTransitionToMap) {
                stack.replace(map);
            }
        }
    }
}
