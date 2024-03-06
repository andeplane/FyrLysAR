import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    height: 200
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    color: Qt.rgba(1.0, 1.0, 1.0, 0.7)

    GridLayout {
        id: grid
        columns: 1
        Label {
            text: `Current position: ${root.selfCoord?.latitude.toFixed(4)} ${root.selfCoord?.longitude.toFixed(4)}`
            color: "red"
        }
        Label {
            text: `Current altitude: ${root.selfCoord?.altitude.toFixed(0.1)}`
            color: "red"
        }
        Label {
            text: `Position update Δt: ${positionSource.timePerUpdate.toFixed(2)}`
            color: "red"
        }
        Label {
            text: `Accelerometer update Δt: ${accelerometer.timePerUpdate.toFixed(2)}`
            color: "red"
        }
        Label {
            text: `Lighthouses above horizon: ${numLighthousesAboveHorizon}`
            color: "red"
        }
        Label {
            text: `Lighthouses not hidden by land: ${numLighthousesNotHiddenByLand}`
            color: "red"
        }
        Label {
            text: `Nearby lighthouse length: ${numLighthousesInNearbyList}`
            color: "red"
        }
    }
}
