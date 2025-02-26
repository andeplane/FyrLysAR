import QtQuick
import QtSensors
import QtPositioning

Item {
    id: root
    property var position
    property var accelerometer
    property real compass: 0

    PositionSource {
        updateInterval: 250
        active: true

        onPositionChanged: {
            root.position = position.coordinate
        }
    }

    Accelerometer {
        active: true
        dataRate: 25

        onReadingChanged: {
            root.accelerometer = reading
        }
    }

    Compass {
        active: true
        dataRate: 7
        property real azimuth: 0
        onReadingChanged: {
            root.compass = reading.azimuth;
        }
    }
}
