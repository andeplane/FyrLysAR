import QtQuick
import QtSensors
import QtMultimedia
import QtPositioning
import QtQuick.Controls
import QtQuick.Layouts

import "qrc:/"

Item {
    id: root

    property bool debug
    property var  lighthouseProvider
    property var  lighthouseComponent
    property real crosshairRadius: 0.1
    property var  selfCoord
    property real fovL: 69
    property real fovP: 38
    property real smoothingN: 3
    property var  nearbyLighthouses: []
    property real nearbyLighthousesLengthLastUpdate: 0
    property bool spritesDirty: false

    onDebugChanged: {
        // Reset stats
        accelerometer.accumulatedTime = 0
        accelerometer.numUpdates = 1
    }

    Component.onCompleted: {
        lighthouseComponent = Qt.createComponent("qrc:/ARLighthouseCircle.qml");
    }

    Timer {
        repeat: true
        interval: 250
        running: true
        onTriggered: {
            if (nearbyLighthouses.length !== nearbyLighthousesLengthLastUpdate) {
                createLighthouseSprites()
                nearbyLighthousesLengthLastUpdate = nearbyLighthouses.length
            }
        }
    }

    function createLighthouseSprites() {
        // Will create the sprites (aka objects that are rendered on screen)
        // for all lighthouse objects in nearbyLighthouses
        nearbyLighthouses.forEach(lighthouse => {
            if (lighthouse.arSprite === undefined && lighthouseComponent.status === Component.Ready) {
                lighthouse.arSprite = lighthouseComponent.createObject(lighthouseContainer, {
                    accelerometerReading: accelerometer.reading,
                    x: 100,
                    y: 100,
                    crosshairRadius: crosshairRadius,
                    radius: 10,
                    width: 10,
                    height: 10,
                    lighthouse: lighthouse,
                    visible: false
                });
                root.spritesDirty = true
            }
        })
    }

    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: true
        }
        videoOutput: viewfinder
    }

    VideoOutput {
        id: viewfinder
        visible: true
        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        orientation: 0
    }

    Accelerometer {
        id: accelerometer
        active: true
        dataRate: 25

        property real accumulatedTime: 0
        property real numUpdates: 1
        property real timePerUpdate: accumulatedTime/numUpdates

        onReadingChanged: {
            const t0 = Date.now()
            if (!root.selfCoord) {
                return
            }

            // Device coordinate system is:
            // x to the left
            // y down
            // z outwards from back camera
            // accelerometer reading follows this coordinate system

            const g = Qt.vector3d(0, 0, 1)
            let gp = Qt.vector3d(-reading.x, reading.y, -reading.z).normalized()

            const angle = Math.acos(gp.dotProduct(g))
            const gCrossGp = gp.crossProduct(g).normalized()
            let xyAngle = Math.atan2(reading.x,reading.y) * 180 / Math.PI

            const U = Qt.matrix4x4()
            U.rotate(compass.azimuth + 2*xyAngle, g )

            const V = Qt.matrix4x4()
            V.rotate(angle * 180 / Math.PI, gCrossGp)

            const R = V.times(U)

            let lighthouseNearestCenterOnScreen = undefined
            let nearestCenterOnScreenDistance = 1e9

            nearbyLighthouses.forEach(lighthouse => {
                if (lighthouse.arSprite && !lighthouse.isHiddenByLand && lighthouse.isAboveHorizon) {
                    lighthouse.arSprite.update(root.selfCoord, R, fovP, fovL, root.width, root.height)
                    if (lighthouse.arSprite.visible && lighthouse.arSprite.normalizedDistanceToScreenCenter < nearestCenterOnScreenDistance) {
                        nearestCenterOnScreenDistance = lighthouse.arSprite.normalizedDistanceToScreenCenter
                        lighthouseNearestCenterOnScreen = lighthouse
                    }
                }
            })

            if (nearestCenterOnScreenDistance < crosshairRadius) {
                infoBox.visible = true
                infoBox.lighthouse = lighthouseNearestCenterOnScreen
            } else {
                infoBox.visible = false
            }

            const t1 = Date.now()
            accumulatedTime += t1-t0
            numUpdates += 1
        }
    }

    Compass {
        id: compass
        active: true
        dataRate: 7
        property real azimuth: 0
        onReadingChanged: {
            azimuth = reading.azimuth
        }
    }

    Item {
        id: lighthouseContainer
        anchors.fill: parent
    }

    InfoBox {
        id: infoBox
        deviceCoordinate: root.selfCoord
    }

    // DebugBox {
    //     visible: debug
    // }

    Crosshair {
        crosshairRadius: root.crosshairRadius
    }
}
