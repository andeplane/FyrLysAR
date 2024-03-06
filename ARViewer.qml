import QtQuick
import QtSensors
import QtMultimedia
import QtPositioning
import QtQuick.Controls
import QtQuick.Layouts
import HeightReader 1.0

import "qrc:/"

Item {
    id: root

    property bool debug
    property var lighthouses
    property var lighthouseComponent
    property var nearbyLighthouses: []
    property real numLighthousesNotHiddenByLand: 0
    property real numLighthousesAboveHorizon: 0
    property real numLighthousesInNearbyList: 0
    property bool useHardCodedPosition
    property real hardcodedLongitude
    property real hardcodedLatitude
    property real selfHeight
    property real crosshairRadius: 0.1
    property var selfCoord

    onDebugChanged: {
        // Reset stats
        accelerometer.accumulatedTime = 0
        accelerometer.numUpdates = 1
        positionSource.accumulatedTime = 0
        positionSource.numUpdates = 1
    }

    Component.onCompleted: {
        lighthouseComponent = Qt.createComponent("qrc:/Lighthouse.qml");
    }

    Lighthouses {
        id: lighthousesSource
        Component.onCompleted: {
            root.lighthouses = JSON.parse(jsonString)
            // Some lighthouses don't have height from source.
            // Assume 1 meter for calculations
            lighthouses.forEach(lighthouse => {
                if (lighthouse.height === undefined) {
                    lighthouse.height = 1.0
                }
            })
        }
    }

    property real fovL: 69
    property real fovP: 38
    property real smoothingN: 3
    property real earthRadius: 6371009 // meters

    function deg2rad(deg) {
        return deg / 180 * Math.PI
    }

    function visibilityRange(height) {
        return Math.sqrt(2*earthRadius * height)
    }

    function calculateDistance(lat1, lon1, lat2, lon2) {
      lat1 = deg2rad(lat1)
      lat2 = deg2rad(lat2)
      lon1 = deg2rad(lon1)
      lon2 = deg2rad(lon2)

      const dLat = lat2 - lat1
      const dLon = lon2 - lon1
      const a = (Math.pow(Math.sin(dLat / 2), 2) +
        Math.pow(Math.sin(dLon / 2), 2) *
        Math.cos(lat1) * Math.cos(lat2));
      return earthRadius * 2 * Math.asin(Math.sqrt(a))
    }

    function calculateAngle(lat1, lon1, lat2, lon2) {
      lat1 = deg2rad(lat1)
      lat2 = deg2rad(lat2)
      lon1 = deg2rad(lon1)
      lon2 = deg2rad(lon2)

      const dLon = (lon2 - lon1);

      const y = Math.sin(dLon) * Math.cos(lat2);
      const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1)
        * Math.cos(lat2) * Math.cos(dLon);

      return Math.atan2(y, x)
    }

    function createLighthouseObjects() {
        nearbyLighthouses.forEach(lighthouse => {
            if (lighthouse.sprite === undefined && lighthouseComponent.status === Component.Ready) {
                lighthouse.sprite = lighthouseComponent.createObject(lighthouseContainer, {
                    coordinates: QtPositioning.coordinate(lighthouse.latitude, lighthouse.longitude, lighthouse.height),
                    heightOverSea: lighthouse.height,
                    pattern: lighthouse.pattern,
                    name: lighthouse.name,
                    maxRange: lighthouse.maxRange,
                    sectors: lighthouse.sectors,
                    accelerometerReading: accelerometer.reading,
                    x: 100,
                    y: 100,
                    crosshairRadius: crosshairRadius,
                    radius: 10,
                    width: 10,
                    height: 10,
                    color: Qt.rgba(1.0, 0.0, 0.0, 1.0)
                });
            }
        })
    }

    function updateVisibilityBasedOnLand(selfCoord, lighthouses) {
        numLighthousesNotHiddenByLand = 0
        numLighthousesAboveHorizon = 0
        numLighthousesInNearbyList = nearbyLighthouses.length
        lighthouses.forEach(lighthouse => {
            const lighthouseCoord = QtPositioning.coordinate(lighthouse.latitude, lighthouse.longitude, lighthouse.height)
            lighthouse.isHiddenByLand = !heightReader.lineIsAboveLand(selfCoord, lighthouseCoord)
            lighthouse.isAboveHorizon = selfCoord.distanceTo(lighthouseCoord) < visibilityRange(selfCoord.altitude) + visibilityRange(lighthouse.height)
            if (lighthouse.sprite) {
                lighthouse.sprite.visible = !lighthouse.isHiddenByLand && lighthouse.isAboveHorizon
            }

            numLighthousesNotHiddenByLand += !lighthouse.isHiddenByLand ? 1 : 0
            numLighthousesAboveHorizon += lighthouse.isAboveHorizon ? 1 : 0
        })
    }

    PositionSource {
        id: positionSource
        updateInterval: 250
        active: true
        property var lastUpdatedCoord: undefined
        property real accumulatedTime: 0
        property real numUpdates: 1
        property real timePerUpdate: accumulatedTime/numUpdates

        onPositionChanged: {
            const t0 = Date.now()
            root.selfCoord = positionSource.position.coordinate

            if (useHardCodedPosition) {
                root.selfCoord = QtPositioning.coordinate(hardcodedLatitude, hardcodedLongitude, 0)
            }

            const altitude = heightReader.findHeight(root.selfCoord)
            root.selfCoord = QtPositioning.coordinate(root.selfCoord.latitude, root.selfCoord.longitude, selfHeight + altitude)

            let shouldScanForNewNearbyLighthouses = lastUpdatedCoord===undefined || calculateDistance(selfCoord.latitude, selfCoord.longitude, lastUpdatedCoord.latitude, lastUpdatedCoord.longitude) > 1852
            let shouldUpdateVisibilityBasedOnLand = lastUpdatedCoord===undefined || calculateDistance(selfCoord.latitude, selfCoord.longitude, lastUpdatedCoord.latitude, lastUpdatedCoord.longitude) > 20

            if (shouldScanForNewNearbyLighthouses) {
                lighthouses.forEach(lighthouse => {
                    var lighthouseCoord = QtPositioning.coordinate(lighthouse.latitude, lighthouse.longitude, lighthouse.height)

                    if (selfCoord.distanceTo(lighthouseCoord) < visibilityRange(selfCoord.altitude) + visibilityRange(lighthouse.height)) {
                        if (nearbyLighthouses.indexOf(lighthouse) < 0) {

                            nearbyLighthouses.push(lighthouse)
                        }
                    }
                })
                lastUpdatedCoord = selfCoord
                createLighthouseObjects()
            }

            if (shouldUpdateVisibilityBasedOnLand) {
                updateVisibilityBasedOnLand(selfCoord, nearbyLighthouses)
            }

            const t1 = Date.now()
            accumulatedTime += t1-t0
            numUpdates += 1
        }
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
        property real x: 0
        property real y: 0
        property real z: 0
        property real xx: 0
        property real yy: 0
        property real zz: 0
        property real theta: 0
        property real phi: 0
        property real xyAngle: 0
        property var rotationMatrix

        onReadingChanged: {
            const t0 = Date.now()
            x = reading.x
            y = reading.y
            z = reading.z

            const g = Qt.vector3d(0, 0, 1)
            let gp = Qt.vector3d(-x, y, -z).normalized()

            const angle = Math.acos(gp.dotProduct(g))
            const gCrossGp = gp.crossProduct(g).normalized()
            let xyAngle = Math.atan2(x,y) * 180 / Math.PI

            const U = Qt.matrix4x4()
            U.rotate(compass.azimuth + 2*xyAngle, g )

            const V = Qt.matrix4x4()
            V.rotate(angle * 180 / Math.PI, gCrossGp)

            const R = V.times(U)

            let lighthouseNearestCenterOnScreen = undefined
            let nearestCenterOnScreenDistance = 1e9

            nearbyLighthouses.forEach(lighthouse => {
                if (lighthouse.sprite && !lighthouse.isHiddenByLand && lighthouse.isAboveHorizon) {
                    lighthouse.sprite.update(selfCoord, R, fovP, fovL, root.width, root.height)
                    if (lighthouse.sprite.visible && lighthouse.sprite.normalizedDistanceToScreenCenter < nearestCenterOnScreenDistance) {
                        nearestCenterOnScreenDistance = lighthouse.sprite.normalizedDistanceToScreenCenter
                        lighthouseNearestCenterOnScreen = lighthouse
                    }
                }
            })

            if (nearestCenterOnScreenDistance < crosshairRadius) {
                infoBox.visible = true
                infoBox.lighthouse = lighthouseNearestCenterOnScreen.sprite
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

    HeightReader {
        id: heightReader
    }

    InfoBox {
        id: infoBox
    }

    DebugBox {
        visible: debug
    }

    Rectangle {
        anchors.centerIn: parent
        radius: width/2
        width: root.width * crosshairRadius * 2
        height: width
        color: "transparent"
        border.color: "white"
        border.width: root.width * 0.01
    }

    Rectangle {
        anchors.centerIn: parent
        radius: width/2
        width: root.width * 0.01
        height: width
        color: "white"
    }
}
