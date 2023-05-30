import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    id: root
    title: "Settings"
    property bool useHardCodedPosition
    property real hardcodedLongitude
    property real hardcodedLatitude

    Header {
        id: header
        text: "Settings"
    }

    ScrollView {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        ListModel {
            id: contactModel

            ListElement {
                name: "Use current location"
            }
            ListElement {
                name: "Use hardcoded location"
            }
        }

        Column {
            width: parent.width

            Label {
                text: "Location"
            }

            Rectangle {
                width: root.width; height: 80

                Component {
                    id: contactDelegate
                    Item {
                        width: root.width; height: 40
                        Column {
                            Text { text: name }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: listView.currentIndex = index
                        }
                    }
                }

                ListView {
                    id: listView
                    currentIndex: useHardCodedPosition ? 1 : 0
                    onCurrentIndexChanged: {
                        root.useHardCodedPosition = currentIndex === 1
                    }

                    anchors.fill: parent
                    model: contactModel
                    delegate: contactDelegate
                    highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
                    focus: true
                }
            }

            Label {
                text: "Longitude"
                visible: listView.currentIndex === 1
            }
            TextField {
                visible: listView.currentIndex === 1
                width: root.width
                height: 40
                placeholderText: "Enter longitude"
                text: root.hardcodedLongitude
                onTextChanged: {
                    const parsedValue = parseFloat(text)
                    if (!isNaN(parsedValue)) {
                        root.hardcodedLongitude = parsedValue
                    }
                }
            }

            Label {
                text: "Latitude"
                visible: listView.currentIndex === 1
            }
            TextField {
                visible: listView.currentIndex === 1
                width: root.width
                height: 40
                placeholderText: "Enter latitude"
                text: root.hardcodedLatitude
                onTextChanged: {
                    const parsedValue = parseFloat(text)
                    if (!isNaN(parsedValue)) {
                        root.hardcodedLatitude = parsedValue
                    }
                }
            }
        }
    }
}
