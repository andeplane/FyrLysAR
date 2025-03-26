import QtQuick
import QtLocation
import QtPositioning
import QtSensors
import QtQuick.Shapes 1.15

Item {
    id: root
    property var selfCoord
    property real compassBearing
    property alias center: map.center
    // flag to indicate if we are animating a reset
    property bool rotationAnimatingReset: false
    property bool scaleAnimatingReset: false
    property bool positionAnimatingReset: false
    property real cumulativeDeltaRotation: 0
    property bool customRotation: false
    property bool customScale: false
    property bool customCenter: false

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
        map.center = selfCoord;
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

    WheelHandler {
        id: wheel
        // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
        acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                         ? PointerDevice.Mouse | PointerDevice.TouchPad
                         : PointerDevice.Mouse
        rotationScale: 1/120
        property: "zoomLevel"
    }

    DragHandler {
        id: drag
        target: null
        onTranslationChanged: (delta) => {
            map.pan(-delta.x, -delta.y)
            customCenter = true
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
        width: 40
        height: 40
        // while animating, use the map’s current bearing
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
        width: 40
        height: 40
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 55
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
}
