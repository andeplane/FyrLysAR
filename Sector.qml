import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var lighthouse
    radius: width/2
    color: "black"
    onLighthouseChanged: {
        canvas.requestPaint()
    }

    function drawSector(ctx, color, from, to) {
        if (color === "red") {
            color = Qt.rgba(1.0, 0.0, 0.0, 1.0)
        } else if (color === "green") {
            color = Qt.rgba(0, 1.0, 0.5, 1.0)
        } else if (color === "blue") {
            color = Qt.rgba(0.0, 80/255, 1.0, 1.0)
        } else if (color === "yellow") {
            color = Qt.rgba(1.0, 200/255, 0.0, 1.0)
        } else if (color === "white") {
            // Render as yellow
            color = Qt.rgba(1.0, 200/255, 0.0, 1.0)
        }

        const radius = root.width/2
        ctx.fillStyle = color
        ctx.beginPath()
        ctx.moveTo(radius, radius);
        ctx.arc(radius, radius, radius, from, to)
        ctx.lineTo(radius, radius);
        ctx.fill()
    }

    function drawSectors(ctx, sectors) {
        sectors.forEach(sector => {
            const start = (sector.start + 90) / 180 * Math.PI
            const stop = (sector.stop + 90) / 180 * Math.PI
            drawSector(ctx, sector.color, start, stop);
          })
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            if (root.lighthouse) {
                drawSectors(ctx, root.lighthouse.sectors)
            }
        }
    }
}
