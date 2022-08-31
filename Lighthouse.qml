import QtQuick

Rectangle {
    id: root
    property real smoothingN: 5
    property real xx: 0
    property real yy: 0
    property real zz: 0
    property var sprite
    property var coordinates
    property string pattern
    property string name
    property real heightOverSea
    property var sectors: []

    function update(deviceCoordinate, R, fovP, fovL, width, height, time) {
        var angle = deviceCoordinate.azimuthTo(coordinates)

        angle = (angle + 2 * Math.PI) % (2 * Math.PI)
        let color = null
        sectors.forEach(sector => {
            if (sector.start <= angle && angle < sector.stop) {
              color = sector.color
            }
        })
        if (color == null) {
            console.log('Cannot find sector with angle ', angle)
        } else {
            root.color = color
        }

        const v = Qt.vector3d(Math.sin(angle / 180 * Math.PI), Math.cos(angle / 180 * Math.PI), 0)
        const vPrime = R.times(v)
        xx -= xx / smoothingN
        xx += vPrime.x / smoothingN

        yy -= yy / smoothingN
        yy += vPrime.y / smoothingN

        zz -= zz / smoothingN
        zz += vPrime.z / smoothingN

        x = 180 / Math.PI * Math.atan2(xx, zz)/fovP * width + width/2
        y = 180 / Math.PI * Math.atan2(yy, zz)/fovL * height + height/2
    }
}
