import QtQuick
import QtSensors
import QtMultimedia
import QtPositioning
import "qrc:/"

Item {
    id: root
    property var lighthouses
    property var lighthouseComponent
    property var visibleLighthouses: []
    width: 640
    height: 480

    Component.onCompleted: {
        lighthouseComponent = Qt.createComponent("qrc:/Lighthouse.qml");
    }

    Lighthouses {
        id: lighthousesSource
        Component.onCompleted: {
            root.lighthouses = JSON.parse(jsonString)
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
        visibleLighthouses.forEach(lighthouse => {
            let lighthouseHeight = 1.0
            if (lighthouse.height != null) {
                lighthouseHeight = lighthouse.height
            }

            if (lighthouse.sprite === undefined && lighthouseComponent.status === Component.Ready) {
                lighthouse.sprite = lighthouseComponent.createObject(lighthouseContainer, {
                    coordinates: QtPositioning.coordinate(lighthouse.latitudeDeg + lighthouse.latitudeMin/60, lighthouse.longitudeDeg + lighthouse.longitudeMin/60, lighthouseHeight),
                    heightOverSea: lighthouseHeight,
                    pattern: lighthouse.pattern,
                    name: lighthouse.name,
                    sectors: lighthouse.sectors,
                    x: 100,
                    y: 100,
                    radius: 10,
                    width: 10,
                    height: 10,
                    color: Qt.rgba(1.0, 0.0, 0.0, 1.0)
                });
            }
        })
    }

    PositionSource {
        id: src
        updateInterval: 250
        active: true

        onPositionChanged: {
            var coord = src.position.coordinate
            lighthouses.forEach(lighthouse => {
                let lighthouseHeight = 1.0
                const selfHeight = 2.0
                if (lighthouse.height !== null) {
                    lighthouseHeight = lighthouse.height
                }

                var otherCoord = QtPositioning.coordinate(lighthouse.latitudeDeg + lighthouse.latitudeMin/60, lighthouse.longitudeDeg + lighthouse.longitudeMin/60, lighthouseHeight)

                let isVisible = false

                if (coord.distanceTo(otherCoord) < visibilityRange(selfHeight) + visibilityRange(lighthouseHeight)) {
                    isVisible = true
                    if (visibleLighthouses.indexOf(lighthouse) < 0) {
                        visibleLighthouses.push(lighthouse)
                    }
                }

                const index = visibleLighthouses.indexOf(lighthouse)
                if (index >= 0) {
                   if (visibleLighthouses[index].sprite) {
                       visibleLighthouses[index].sprite.visible = isVisible
                   }
                }
            })

            createLighthouseObjects()
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
        anchors.fill: parent
    }

    Accelerometer {
        id: accelerometer
        active: true
        dataRate: 25

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
            x = reading.x
            y = reading.y
            z = reading.z

            const g = Qt.vector3d(0, 0, 1)
            let gp = Qt.vector3d(x, y, -z).normalized()

            const angle = Math.acos(gp.dotProduct(g))
            const gCrossGp = gp.crossProduct(g).normalized()

            const U = Qt.matrix4x4()
            U.rotate(compass.azimuth, g )

            const V = Qt.matrix4x4()
            V.rotate(angle * 180 / Math.PI, gCrossGp)

            const R = V.times(U)

            visibleLighthouses.forEach(lighthouse => {
                if (lighthouse.sprite && lighthouse.sprite.visible) {
                    lighthouse.sprite.update(src.position.coordinate, R, fovP, fovL, root.width, root.height, Date.now())
                }
            })
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
}
