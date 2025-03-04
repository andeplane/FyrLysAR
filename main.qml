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

    ARViewer {
        id: mainView
        debug: root.debug
        useHardCodedPosition: settings.useHardCodedPosition
        hardcodedLongitude: settings.hardcodedLongitude
        hardcodedLatitude: settings.hardcodedLatitude
        selfHeight: settings.selfHeight
    }

    MapMode {
        id: map
        compassBearing: sensors.compass
        longitude: root.selfCoord ? root.selfCoord.longitude : 0
        latitude: root.selfCoord ? root.selfCoord.latitude : 0
    }

    SettingsView {
        id: settings
    }

    StackView {
        id: stack
        initialItem: mainView
        anchors.fill: parent
    }

    SettingsButton {
        id: settingsButton
    }

    WelcomeScreen {
        id: welcomeScreen
        visible: true
        anchors.fill: parent
    }

    Sensors {
        id: sensors
        onPositionChanged: {
            if (settings.useHardCodedPosition && settings.hardcodedLatitude && settings.hardcodedLongitude) {
                root.selfCoord = QtPositioning.coordinate(settings.hardcodedLatitude, settings.hardcodedLongitude, 0)
            } else {
                root.selfCoord = position
            }
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
