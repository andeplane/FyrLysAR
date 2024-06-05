import QtQuick 2.15
import QtQuick.Controls 2.15
import QtPositioning

Page {
    id: root
    title: "Settings"
    property bool debug
    property bool useHardCodedPosition
    property real hardcodedLongitude
    property real hardcodedLatitude
    property real selfHeight: 2.0

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
                text: "Observer height"
                onTextChanged: {
                    const parsedValue = parseFloat(text)
                    if (!isNaN(parsedValue)) {
                        root.selfHeight = parsedValue
                    }
                }
            }

            SpinBox {
                from: 0
                editable: true
                stepSize: 1
                value: root.selfHeight
                onValueChanged: {
                    root.selfHeight = value
                }
            }

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

            ComboBox {
                visible: listView.currentIndex === 1
                model: ListModel {
                    id: model

                    ListElement {
                        text: "Custom"
                    }
                    // ListElement {
                    //     text: "Herfølhytta"
                    // }
                    ListElement {
                        text: "Herfølrenna nord"
                    }
                    ListElement {
                        text: "Lauersvelgen"
                    }
                    ListElement {
                        text: "Sørenga"
                    }
                    ListElement {
                        text: "Ytre Oslofjord"
                    }
                    // ListElement {
                    //     text: "Special place"
                    // }
                }
                onCurrentTextChanged: {
                    const locations = {
                        // "Herfølhytta": QtPositioning.coordinate(58.9952381,11.0584886),
                        "Herfølrenna nord": QtPositioning.coordinate(59.006630, 11.057814),
                        "Lauersvelgen": QtPositioning.coordinate(59.014167, 11.042647),
                        "Sørenga": QtPositioning.coordinate(59.901484, 10.751129),
                        "Ytre Oslofjord": QtPositioning.coordinate(58.982769, 10.763596),
                        // "Special place": QtPositioning.coordinate(59.014167, 11.042647)
                    }
                    const location = locations[currentText]
                    if (location) {
                        longitudeText.text = location.longitude
                        latitudeText.text = location.latitude
                    }
                }
            }

            Label {
                text: "Latitude"
                visible: listView.currentIndex === 1
            }
            TextField {
                id: latitudeText
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

            Label {
                text: "Longitude"
                visible: listView.currentIndex === 1
            }
            TextField {
                id: longitudeText
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
            // Switch {
            //     text: "Debug"
            //     onToggled: {
            //         root.debug = checked
            //     }
            // }
        }
    }
}
