import QtQuick

Rectangle {
    id: root
    property var lighthouse
    property real smoothingN: 3
    property real xx: 0
    property real yy: 0
    property real zz: 0
    property var accelerometerReading
    property real baseSize
    property real sizeScaleFactor: 1.0
    property real normalizedDistanceToScreenCenter
    property real crosshairRadius

    // Binding to adjust size based on normalizedDeltaR
    onNormalizedDistanceToScreenCenterChanged: {
        if (normalizedDistanceToScreenCenter <= crosshairRadius) {
            if (!sizeIncreaseAnimation.running && Math.abs(sizeScaleFactor - 2.0) > 1e-6) {
                if (sizeDecreaseAnimation.running) {
                    sizeDecreaseAnimation.stop()
                }

                sizeIncreaseAnimation.start();
            }
        } else {
            if (!sizeDecreaseAnimation.running && Math.abs(sizeScaleFactor - 1.0) > 1e-6) {
                if (sizeIncreaseAnimation.running) {
                    sizeIncreaseAnimation.stop()
                }

                sizeDecreaseAnimation.start();
            }
        }
    }

    NumberAnimation {
        id: sizeIncreaseAnimation
        target: root
        properties: "sizeScaleFactor"
        to: 2.0
        duration: 500 // Animation duration in milliseconds
        easing.type: Easing.InOutQuad // Easing type for the animation
    }

    NumberAnimation {
        id: sizeDecreaseAnimation
        target: root
        properties: "sizeScaleFactor"
        to: 1.0
        duration: 500 // Animation duration in milliseconds
        easing.type: Easing.InOutQuad // Easing type for the animation
    }

    function updatePositionOnScreen(deviceCoordinate, R, fovP, fovL, screenWidth, screenHeight) {
        let angle = deviceCoordinate.azimuthTo(root.lighthouse.coordinates)
        angle *= Math.PI / 180

        const tanPhi = (root.lighthouse.heightOverSea - deviceCoordinate.altitude)/root.lighthouse.distance

        const HEIGHT_FACTOR = 4; // Increasing effect of height to improve visuals.
        let phi = Math.atan(tanPhi)
        const v = Qt.vector3d(Math.sin(angle), Math.cos(angle), HEIGHT_FACTOR*Math.sin(phi))

        const vPrime = R.times(v)
        xx -= xx / smoothingN
        xx += vPrime.x / smoothingN

        yy -= yy / smoothingN
        yy += vPrime.y / smoothingN

        zz -= zz / smoothingN
        zz += vPrime.z / smoothingN

        x = 180 / Math.PI * Math.atan2(xx, zz)/fovP * screenWidth + screenWidth/2 - root.width/2
        y = 180 / Math.PI * Math.atan2(yy, zz)/fovL * screenHeight + screenHeight/2 - root.height/2
    }

    function updateDistanceFromScreenCenter(width, height) {
        const deltaX = width/2 - x - root.width/2
        const deltaY = height/2 - y - root.height/2
        const deltaR = Math.sqrt(deltaX*deltaX + deltaY*deltaY)
        normalizedDistanceToScreenCenter = deltaR / width
    }

    function updateCircleSize() {
        // Max size on screen appears at 500 meter
        const maxRange = Math.max(500, root.lighthouse.maxRange)
        // Linear interpolate between 0 and 30 based on distance / maxRange
        let baseSize = lerp(15, 5, root.lighthouse.distance/root.lighthouse.maxRange)
        baseSize = Math.max(baseSize, 5)

        // sizeScaleFactor will scale if the object is
        // within the crosshair on the screen
        root.radius = baseSize * sizeScaleFactor
        root.width = baseSize * sizeScaleFactor
        root.height = baseSize * sizeScaleFactor
    }

    function update(deviceCoordinate, R, fovP, fovL, screenWidth, screenHeight) {
        root.lighthouse.update(deviceCoordinate, true)
        updatePositionOnScreen(deviceCoordinate, R, fovP, fovL, screenWidth, screenHeight)
        updateDistanceFromScreenCenter(screenWidth, screenHeight)
        updateCircleSize()
        this.color = root.lighthouse.lightIsOn ? root.lighthouse.colorTowardsSelf : "black"
    }

    function lerp (start, end, amt){
      return (1-amt)*start+amt*end
    }
}
