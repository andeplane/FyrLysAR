import QtQuick

Rectangle {
    id: root
    property real smoothingN: 3
    property real xx: 0
    property real yy: 0
    property real zz: 0
    property var sprite
    property var coordinates
    property real distance
    property string pattern
    property int flashPeriod
    property string name
    property real heightOverSea
    property real maxRange
    property var sectors: []
    property var flashValues: []

    function parseFlash(pattern) {
      let re = /\s[WGR]+\s*/
      const splitted = pattern.split(re)
      splitted[0].substr()
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

    function update(deviceCoordinate, R, fovP, fovL, width, height, time) {
        var angle = deviceCoordinate.azimuthTo(coordinates)
        distance = deviceCoordinate.distanceTo(coordinates)

        angle = (angle + 2 * 180) % (2 * 180)
        let color = null
        sectors.forEach(sector => {
            if (sector.start <= angle && angle < sector.stop) {
              color = sector.color
            }
        })
        if (color == null) {
//            visible = false
            root.color = Qt.rgba(0.0, 0.0, 1.0, 1.0)
        } else {
            root.color = color
        }
        angle *= Math.PI / 180

        const v = Qt.vector3d(Math.sin(angle), Math.cos(angle), 0)
        const vPrime = R.times(v)
        xx -= xx / smoothingN
        xx += vPrime.x / smoothingN

        yy -= yy / smoothingN
        yy += vPrime.y / smoothingN

        zz -= zz / smoothingN
        zz += vPrime.z / smoothingN

        x = 180 / Math.PI * Math.atan2(xx, zz)/fovP * width + width/2 - root.width/2
        y = 180 / Math.PI * Math.atan2(yy, zz)/fovL * height + height/2 - root.height/2

        if (flashValues && flashValues.length > 0 & flashPeriod > 0) {
            let index = Math.floor(time/1000) % (flashPeriod / flashValues.length)

            index = index % flashValues.length
//            let lightOn = flashValues[index]
//            if (!lightOn) {
//                root.color = Qt.rgba(0.0, 0.0, 0.0, 1.0)
//            }
        }

        function lerp (start, end, amt){
          return (1-amt)*start+amt*end
        }

        let size = lerp(100, 0, distance/maxRange)
        size = Math.max(size, 0)

        root.radius = size
        root.width = size
        root.height = size
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            infoBox.visible = !infoBox.visible
        }
    }

    Rectangle {
        id: infoBox
        width: 170
        height: 70
        x: 30
        y: -50
        radius: 10
        opacity: 0.9
        visible: false
        MouseArea {
            anchors.fill: parent
            onClicked: {
                infoBox.visible = false
            }
        }

        // visible: Math.sqrt( Math.pow(root.x-root.parent.width/2,2) + Math.pow(root.y-root.parent.height/2,2)) < 50
        Column {
            Row {
                Text {
                    text: "Name: "
                }
                Text {
                    text: name
                }
            }

            Row {
                Text {
                    text: "Distance: "
                }
                Text {
                    text: distance.toFixed(0.0) + ' m'
                }
            }

            Row {
                Text {
                    text: "Height: "
                }
                Text {
                    text: heightOverSea + ' m'
                }
            }
        }



    }
}
