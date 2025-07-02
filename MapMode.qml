import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import QtSensors
import QtQuick.Shapes 1.15

Item {
    id: root
    property var selfCoord
    property real compassBearing
    property var nearbyLighthouses
    property alias center: map.center
    // flag to indicate if we are animating a reset
    property bool rotationAnimatingReset: false
    property bool scaleAnimatingReset: false
    property bool positionAnimatingReset: false
    property real cumulativeDeltaRotation: 0
    property bool customRotation: false
    property bool customScale: false
    property bool customCenter: false
    property bool isSettingHardcodedLocation: false

    signal hardcodedLocationSet(real latitude, real longitude)
    signal hardcodedLocationCancelled()

    // activeBearing uses the animated value when animating, otherwise uses
    // either map.bearing (if customRotation) or the compass value.
    property real activeBearing: rotationAnimatingReset ? map.bearing : (customRotation ? map.bearing : compassBearing)

    function resetView() {
        customRotation = false
        customScale = false
        customCenter = false
    }

    // If updates come from outside while not animating, update immediately.
    onSelfCoordChanged: {
        if (customCenter || positionAnimatingReset)
            return;
        if (selfCoord) {
            map.center = selfCoord;
        }
    }

    onCompassBearingChanged: {
        if (customRotation || rotationAnimatingReset)
            return;
        map.bearing = compassBearing;
    }

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        zoomLevel: 14
        bearing: compassBearing
        copyrightsVisible: false

        WheelHandler {
            id: wheel
            // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
            acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                             ? PointerDevice.Mouse | PointerDevice.TouchPad
                             : PointerDevice.Mouse
            rotationScale: 1/120
            property: "zoomLevel"
        }

        PinchHandler {
            id: pinch
            target: null
            onActiveChanged: {
                if (!active) {
                    root.cumulativeDeltaRotation = 0
                }
            }

            onScaleChanged: (delta) => {
                customScale = true
                map.zoomLevel += Math.log2(delta)
            }

            onRotationChanged: (delta) => {
                cumulativeDeltaRotation += delta
                if (Math.abs(cumulativeDeltaRotation) > 7) {
                    root.customRotation = true
                }
                if (root.customRotation) {
                    map.bearing -= delta
                }
            }
            grabPermissions: PointerHandler.TakeOverForbidden
        }

        DragHandler {
            id: drag
            target: null
            onTranslationChanged: (delta) => {
                map.pan(-delta.x, -delta.y)
                customCenter = true
            }
        }

        MapItemView {
            anchors.fill: parent
            model: nearbyLighthouses

            delegate: MapQuickItem {
                // The coordinate where the sector is displayed
                coordinate: modelData.coordinates
                // Setting zoomLevel makes the item scale with the map
                zoomLevel: 14
                anchorPoint.x: sourceItem.width / 2
                anchorPoint.y: sourceItem.height / 2

                sourceItem: RenderableSectors {
                    width: 50
                    height: 50
                    sectors: modelData.sectors
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            infoBox.lighthouse = modelData
                        }
                    }
                }
            }
        }

    }

    ParallelAnimation {
        id: resetRotationAnimation
        PropertyAnimation { target: map; property: "bearing"; duration: 250; to: compassBearing }
        onFinished: {
            root.rotationAnimatingReset = false;
        }
    }

    ParallelAnimation {
        id: resetPositionAnimation
        PropertyAnimation { target: map; property: "center"; duration: 250; to: selfCoord }
        onFinished: {
            root.positionAnimatingReset = false;
        }
    }

    ParallelAnimation {
        id: resetScaleAnimation
        PropertyAnimation { target: map; property: "zoomLevel"; duration: 250; to: 14 }
        onFinished: {
            root.scaleAnimatingReset = false;
        }
    }

    Shortcut {
        enabled: map.zoomLevel < map.maximumZoomLevel
        sequence: StandardKey.ZoomIn
        onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
    }

    Shortcut {
        enabled: map.zoomLevel > map.minimumZoomLevel
        sequence: StandardKey.ZoomOut
        onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
    }

    CompassNeedle {
        id: compassNeedle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10
        compassStrokeStyle: (customRotation) ? ShapePath.DashLine : ShapePath.SolidLine
        width: 56
        height: 56
        // while animating, use the map's current bearing
        rotation: -activeBearing

        MouseArea {
            anchors.fill: parent
            onClicked: {
                customRotation = false
                rotationAnimatingReset = true
                resetRotationAnimation.start()
            }
        }
    }

    ResetLocationButton {
        width: 44
        height: 44
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 59
        anchors.rightMargin: 10
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (customCenter) {
                    customCenter = false
                    positionAnimatingReset = true
                    resetPositionAnimation.start()
                } else if (customScale) {
                    customScale = false
                    scaleAnimatingReset = true
                    resetScaleAnimation.start()
                }
            }
        }
    }

    InfoBox {
        id: infoBox
        deviceCoordinate: root.selfCoord
        visible: lighthouse != null
        MouseArea {
            anchors.fill: parent
            onClicked: {
                infoBox.lighthouse = null
            }
        }
    }

    // Center crosshair lines when setting hardcoded location
    Rectangle {
        id: verticalLine
        visible: isSettingHardcodedLocation
        width: 1
        height: parent.height
        color: "red"
        opacity: 0.7
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Rectangle {
        id: horizontalLine
        visible: isSettingHardcodedLocation
        width: parent.width
        height: 1
        color: "red"
        opacity: 0.7
        anchors.verticalCenter: parent.verticalCenter
    }

    // Coordinates display at the top right (where settings button normally is)
    Rectangle {
        id: coordinatesBox
        visible: isSettingHardcodedLocation
        width: parent.width / 2 - 20
        height: 44
        color: "black"
        opacity: 0.8
        radius: 5
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                id: latText
                color: "white"
                font.pixelSize: 12
                text: isSettingHardcodedLocation ? "Latitude: " + map.center.latitude.toFixed(3) : ""
            }

            Text {
                id: lonText
                color: "white"
                font.pixelSize: 12
                text: isSettingHardcodedLocation ? "Longitude: " + map.center.longitude.toFixed(3) : ""
            }
        }
    }

    Button {
        text: "Add"
        visible: isSettingHardcodedLocation
        width: 80
        height: 44
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 20
        anchors.rightMargin: 20
        onClicked: {
            hardcodedLocationSet(map.center.latitude, map.center.longitude)
        }
    }

    Button {
        text: "Cancel"
        visible: isSettingHardcodedLocation
        width: 80
        height: 44
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 20
        anchors.leftMargin: 20
        background: Rectangle {
            color: parent.pressed ? "#e3f2fd" : "white"
            border.color: "#2196f3"
            border.width: 1
            radius: 4
        }
        contentItem: Text {
            text: parent.text
            color: "#2196f3"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }
        onClicked: {
            hardcodedLocationCancelled()
        }
    }
}
