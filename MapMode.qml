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
    property bool customView: false
    // flag to indicate if we are animating a reset
    property bool animatingReset: false
    property real cumulativeDeltaRotation: 0
    property bool activeRotation: false
    property bool customScale: false

    // activeBearing uses the animated value when animating, otherwise uses
    // either map.bearing (if custom view) or the compass value.
    property real activeBearing: animatingReset ? map.bearing : (customView ? map.bearing : compassBearing)

    function resetView() {
        // disable any custom view so external updates are ignored during animation
        customView = false
        customScale = false
        animatingReset = true
        resetAnimation.start()
    }

    // If updates come from outside while not animating, update immediately.
    onSelfCoordChanged: {
        if (customView || animatingReset)
            return;
        map.center = selfCoord;
    }

    onCompassBearingChanged: {
        if (customView || animatingReset)
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
        // center is normally updated via onSelfCoordChanged or via the animation
        // during resetView the animations will drive map.center, map.bearing and map.zoomLevel
    }

    // Animate the center, bearing and zoomLevel concurrently.
    ParallelAnimation {
        id: resetAnimation
        // duration can be adjusted as desired (here 500ms)
        PropertyAnimation { target: map; property: "center"; duration: 500; to: selfCoord }
        PropertyAnimation { target: map; property: "bearing"; duration: 500; to: compassBearing }
        PropertyAnimation { target: map; property: "zoomLevel"; duration: 500; to: 14 }
        onFinished: {
            // Once done, allow external updates again.
            root.animatingReset = false;
        }
    }

    PinchHandler {
        id: pinch
        target: null
        onActiveChanged: if (active) {
            map.startCentroid = map.toCoordinate(pinch.centroid.position, false)
            if (!active) {
                root.cumulativeDeltaRotation = 0
                root.activeRotation = false
            }
        }
        onScaleChanged: (delta) => {
            customScale = true
            map.zoomLevel += Math.log2(delta)
            map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
        }
        onRotationChanged: (delta) => {
            cumulativeDeltaRotation += delta
            console.log("cumulativeDeltaRotation: ", cumulativeDeltaRotation)
            if (Math.abs(cumulativeDeltaRotation) > 60) {
                root.activeRotation = true
            }
            if (root.activeRotation) {
                customView = true
                map.bearing -= delta
                map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
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
            customView = true
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
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 20
        anchors.leftMargin: 20
        compassStrokeStyle: (customView || customScale) ? ShapePath.DashLine : ShapePath.SolidLine
        width: 50
        height: 50
        // while animating, use the map’s current bearing
        rotation: -activeBearing

        MouseArea {
            anchors.fill: parent
            onClicked: {
                // Trigger the animated reset.
                resetView()
            }
        }
    }
}
