import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning
import QtSensors
import QtQuick.Shapes 1.15

 Item {
    id: root
    property var selfCoord
    property var nearbyLighthouses
    property alias center: map.center

    signal hardcodedLocationSet(real latitude, real longitude)
    signal hardcodedLocationCancelled()

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        zoomLevel: 10
        copyrightsVisible: true

        WheelHandler {
            id: wheel
            // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
            acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                             ? PointerDevice.Mouse | PointerDevice.TouchPad
                             : PointerDevice.Mouse
            rotationScale: 1/120
            property: "zoomLevel"
        }

        PinchHandler {
            id: pinch
            target: null

            onScaleChanged: (delta) => {
                map.zoomLevel += Math.log2(delta)
            }

            grabPermissions: PointerHandler.TakeOverForbidden
        }

        DragHandler {
            id: drag
            target: null
            onTranslationChanged: (delta) => {
                map.pan(-delta.x, -delta.y)
            }
        }

        MapItemView {
            anchors.fill: parent
            model: nearbyLighthouses

            delegate: MapQuickItem {
                // The coordinate where the sector is displayed
                coordinate: modelData.coordinates
                // Setting zoomLevel makes the item scale with the map
                zoomLevel: 10
                anchorPoint.x: sourceItem.width / 2
                anchorPoint.y: sourceItem.height / 2

                sourceItem: RenderableSectors {
                    width: 50
                    height: 50
                    sectors: modelData.sectors
                }
            }
        }
    }

    SvgButton {
        id: zoomInButton
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10
        fileName: "qrc:/images/plus-svgrepo-com.svg"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                map.zoomLevel *= 1.1
                map.zoomLevel = Math.min(map.zoomLevel, 14)
            }
        }
    }

    SvgButton {
        id: zoomOutButton
        anchors.top: zoomInButton.bottom
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10
        fileName: "qrc:/images/minus-svgrepo-com.svg"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                map.zoomLevel *= 0.9
                map.zoomLevel = Math.max(map.zoomLevel, 4)
            }
        }
    }

    ResetLocationButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 64
        anchors.rightMargin: 10
        MouseArea {
            anchors.fill: parent
            onClicked: {
                map.center = selfCoord
            }
        }
    }

    // Center crosshair lines when setting hardcoded location
    Rectangle {
        id: verticalLine
        width: 1
        height: parent.height
        color: "red"
        opacity: 0.7
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Rectangle {
        id: horizontalLine
        width: parent.width
        height: 1
        color: "red"
        opacity: 0.7
        anchors.verticalCenter: parent.verticalCenter
    }

    // Coordinates display at the top right (where settings button normally is)
    Rectangle {
        id: coordinatesBox
        width: parent.width / 2 - 20
        height: 44
        color: "black"
        opacity: 0.8
        radius: 5
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                id: latText
                color: "white"
                font.pixelSize: 12
                text: "Latitude: " + map.center.latitude.toFixed(3)
            }

            Text {
                id: lonText
                color: "white"
                font.pixelSize: 12
                text: "Longitude: " + map.center.longitude.toFixed(3)
            }
        }
    }

    Button {
        text: "Add"
        width: 80
        height: 44
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 20
        anchors.rightMargin: 20
        onClicked: {
            hardcodedLocationSet(map.center.latitude, map.center.longitude)
        }
    }

    Button {
        text: "Cancel"
        width: 80
        height: 44
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 20
        anchors.leftMargin: 20
        background: Rectangle {
            color: parent.pressed ? "#e3f2fd" : "white"
            border.color: "#2196f3"
            border.width: 1
            radius: 4
        }
        contentItem: Text {
            text: parent.text
            color: "#2196f3"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }
        onClicked: {
            hardcodedLocationCancelled()
        }
    }
}
