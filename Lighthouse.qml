import QtQuick

Rectangle {
    id: root
    property real smoothingN: 3
    property real xx: 0
    property real yy: 0
    property real zz: 0
    property var accelerometerReading
    property real baseSize
    property real sizeScaleFactor: 1.0
    property real normalizedDistanceToScreenCenter
    property var coordinates
    property real distance
    property string pattern
    property int flashPeriod
    property string name
    property real heightOverSea
    property real maxRange
    property real crosshairRadius
    property var sectors: []
    property var flashValues: []
    property bool isHiddenByLand: false
    property bool isAboveHorizon: true

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

    function parseFlash(pattern) {
      let re = /\s[WGR]+\s*/
      const splitted = pattern.split(re)
      const paranthesesIndex = splitted[0].indexOf('(')

      let flashClass = splitted[0]
      let flashNumber = 1
      if (paranthesesIndex > -1) { // Q (3) W 10s
        flashNumber = parseInt(splitted[0][paranthesesIndex + 1])
        flashClass = flashClass.substr(0, paranthesesIndex).trim()
      }

      let flashPeriod = 1
      let flashClassExtra = null
      if (splitted.length > 1) {
        let flashPeriodString = splitted[1]

        if (flashPeriodString.includes('LFl')) { // VQ (6) W LFl 10s
          flashClassExtra = 'LFl'
          flashPeriodString = flashPeriodString.replace('LFl', '').trim()
        }

        if (flashPeriodString.includes('s')) {
          flashPeriod = parseFloat(flashPeriodString.replace('s', '').replace(',', '.'))
        }
      }

      return {
        flashClass,
        flashClassExtra,
        flashNumber,
        flashPeriod
      }
    }

    function convertFlash(lightClass, n, p, extraLightClass) {
      let range = n => Array.from(Array(n).keys())

      if (lightClass === 'Iso') {
        return [1, 0]
      }

      if (lightClass === "Fast") {
        return [1]
      }

      const flash = [];
        let l0, d0, d1
      if (lightClass === "Fl" || lightClass === "FFl") {
        // Max 30 flashes per minute, i.e. max 0.5 Hz
        // Set lengths for l0, d0 and d1

        if (p >= 2 * (n + 1)) { // periode is long enough for d=1s
          l0 = 1
          d0 = 1
          d1 = p - n * l0 - (n - 1) * d0
          if (n > 1) {
            while (n * l0 + (n - 1) * d0 < d1 / 3) { // periode is very long
              d0 += 1
              d1 -= (n - 1)
            }
          }
        } else { // periode is too short for d=1s
          l0 = 1
          d0 = 2
          d1 = 2 * p - n * l0 - (n - 1) * d0
        }
        // build list of lights on/off
        range(n - 1).forEach(i => { // all but last light
          range(l0).forEach(j => { // light parts
            flash.push(1)
          })
          range(d0).forEach(j => { // dark parts
            flash.push(0)
          })
        })
        flash.push(1) // Last light
        range(d1).forEach(k => { // long dark between
          flash.push(0)
        })
        return flash
      }

      if (lightClass === "Oc") {
        let d0, l0, l1
        if (p >= 2 * (n + 1)) { // periode is long enough for d=1s
          d0 = 1
          l0 = 1
          l1 = p - n * d0 - (n - 1) * l0
        } else { // periode is too short for d=1s
          print(`Seems a periode of ${p}s is a bit short for ${lightClass} (${n}) ${p}s.`)
        }
        range(n - 1).forEach(i => { // all but last occult
          range(d0).forEach(j => { // dark parts
            flash.push(0)
          })
          range(l0).forEach(j => { // light parts
            flash.push(1)
          })
        })
        flash.push(0) // Last occult
        range(l1).forEach(k => { // long light between
          flash.push(1)
        })
        return flash
      }

      if (lightClass === "Q") { // 60 flashes per minute, i.e. = 1 Hz
        l0 = 1
        d0 = 1
        if (n == 0) {
          flash.push(1)
          flash.push(0)
        } else {
          d1 = 2 * p - 2 * n // Two timeslots per second
          range(n).forEach(i => {
            flash.push(1)
            flash.push(0)
          })
          if (extraLightClass === "LFl") {
            // This is highly likely a Q (6) + LFl 15s i.e. Cardinal South.
            d1 -= 4
            range(4).forEach(x => {
              flash.push(1)
            })
          }
          range(d1).forEach(k => {
            flash.push(0)
          })
        }
        return flash
      }

      if (lightClass === "VQ") { // 120 flashes per minute, i.e. = 2 Hz
        let l0 = 1
        let d0 = 1
        if (n == 0) {
          flash.push(1)
          flash.push(0)
        } else {
          d1 = 4 * p - 2 * n // Four timeslots per second
          range(n).forEach(i => {
            flash.push(1)
            flash.push(0)
          })
          if (extraLightClass === "LFl") {
            // This is highly likely a VQ (6) + LFl 10s i.e. Cardinal South.
            d1 -= 8
            range(8).forEach(x => {
              flash.push(1)
            })
          }
          range(d1).forEach(k => {
            flash.push(0)
          })
        }
        return flash
      }

      if (lightClass === "UQ") { // 240 flashes per minute, i.e. = 4 Hz
        console.log("Parsing of UQ not implemented") // not used in Norway, I think
        return [0]
      }

      if (lightClass === "LFl") {
        let l = 2
        let d = p - l // TODO might need tweeking for (very) long periodes like 20s
        range(l).forEach(j => { // light parts
          flash.push(1)
        })

        range(d).forEach(j => { // dark parts
          flash.push(0)
        })
        return flash
      }

      console.log(`Could not convert ${lightClass}`)
      return null
    }

    Component.onCompleted: {
        const {
            flashClass,
            flashClassExtra,
            flashNumber,
            flashPeriod
          } = parseFlash(pattern)
        root.flashPeriod = flashPeriod
        flashValues = convertFlash(flashClass, flashNumber, flashPeriod, flashClassExtra)
    }

    function updateColor(deviceCoordinate) {
        let newColor = null
        const time = Date.now()

        let lightOn = true;
        if (flashValues && flashValues.length > 0 && flashPeriod > 0) {
            let index = Math.floor(((time/1000 % flashPeriod) / flashPeriod) * flashValues.length)
            lightOn = index >= 0 && index < flashValues.length ? flashValues[index] : true
        }

        if (!lightOn) {
            // If light is off, set color to black and return
            root.color = Qt.rgba(0.0, 0.0, 0.0, 1.0)
            return;
        }

        var angle = deviceCoordinate.azimuthTo(coordinates)
        distance = deviceCoordinate.distanceTo(coordinates)

        angle = (angle + 2 * 180) % (2 * 180) // Deal with boundary conditions on angles in range [0, 2pi]
        let sector = null

        // Loop through all sectors to find our position
        sectors.forEach(sectorCandidate => {
            let start = sectorCandidate.start
            let stop = sectorCandidate.stop
            if (stop < start) {
                // If we wrap around 0
                stop += 360
            }

            if (start <= angle && angle < stop) {
                sector = sectorCandidate
            }
        })

        if (sector == null) {
            // No sector was found which means we don't see any light from the lighthouse
            newColor = null;
            visible = false
        } else {
            // Make colors more pretty based on research from
            // https://www.iala-aism.org/product/r0201/ and http://colormine.org/convert/rgb-to-yxy
            newColor = sector.color

            // We will thus override green, blue and yellow colors, but
            // keep red and white as they are.
            if (newColor === "green") {
                newColor = Qt.rgba(0, 1.0, 0.5, 1.0)
            } else if (newColor === "blue") {
                newColor = Qt.rgba(0.0, 80/255, 1.0, 1.0)
            } else if (newColor === "yellow") {
                newColor = Qt.rgba(1.0, 200/255, 0.0, 1.0)
            }
        }
        root.color = newColor
    }

    function updatePositionOnScreen(deviceCoordinate, R, fovP, fovL, screenWidth, screenHeight) {
        let angle = deviceCoordinate.azimuthTo(coordinates)
        angle *= Math.PI / 180

        const HEIGHT_FACTOR = 4; // Increasing effect of height to improve visuals.
        const v = Qt.vector3d(Math.sin(angle), Math.cos(angle), HEIGHT_FACTOR*(root.heightOverSea - deviceCoordinate.altitude)/root.distance)

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
        const maxRange = Math.max(500, root.maxRange)
        // Linear interpolate between 0 and 30 based on distance / maxRange
        let baseSize = lerp(15, 5, root.distance/maxRange)
        baseSize = Math.max(baseSize, 5)

        // sizeScaleFactor will scale if the object is
        // within the crosshair on the screen
        root.radius = baseSize * sizeScaleFactor
        root.width = baseSize * sizeScaleFactor
        root.height = baseSize * sizeScaleFactor
    }

    function update(deviceCoordinate, R, fovP, fovL, screenWidth, screenHeight) {
        root.distance = deviceCoordinate.distanceTo(coordinates)

        updateColor(deviceCoordinate)
        updatePositionOnScreen(deviceCoordinate, R, fovP, fovL, screenWidth, screenHeight)
        updateDistanceFromScreenCenter(screenWidth, screenHeight)
        updateCircleSize()
    }

    function lerp (start, end, amt){
      return (1-amt)*start+amt*end
    }
}
