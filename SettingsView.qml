import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtPositioning
import QtCore

Page {
    id: root
    title: "Settings"
    property bool debug
    property bool useHardCodedPosition
    property real hardcodedLongitude
    property real hardcodedLatitude
    property real selfHeight: 2.0

    // Settings for persistent storage
    Settings {
        id: settings
        property alias useHardCodedPosition: root.useHardCodedPosition
        property alias hardcodedLongitude: root.hardcodedLongitude
        property alias hardcodedLatitude: root.hardcodedLatitude
        property alias selfHeight: root.selfHeight
        property string customLocations: "[]" // JSON string for custom locations
    }

    // Custom locations data
    property var customLocations: []

    // Default locations that will be installed on first run
    property var defaultLocations: [
        { name: "Herfølrenna nord", latitude: 59.006630, longitude: 11.057814 },
        { name: "Lauersvelgen", latitude: 59.01487, longitude: 11.0295 },
        { name: "Sørenga", latitude: 59.901484, longitude: 10.751129 },
        { name: "Ytre Oslofjord", latitude: 58.982769, longitude: 10.763596 }
    ]

    // Load custom locations from settings on component creation
    Component.onCompleted: {
        try {
            // Check if settings string is empty or invalid
            if (settings.customLocations === "" || settings.customLocations === "[]" || settings.customLocations === "null") {
                // First run - load default locations
                customLocations = defaultLocations.slice()
                saveCustomLocations()
            } else {
                const locations = JSON.parse(settings.customLocations)
                if (Array.isArray(locations)) {
                    customLocations = locations
                } else {
                    // Invalid data - load default locations
                    customLocations = defaultLocations.slice()
                    saveCustomLocations()
                }
            }
            updateLocationModel()
        } catch (e) {
            console.log("Error parsing custom locations:", e)
            // Error parsing - load default locations
            customLocations = defaultLocations.slice()
            saveCustomLocations()
            updateLocationModel()
        }
    }

    // Function to save custom locations to settings
    function saveCustomLocations() {
        settings.customLocations = JSON.stringify(customLocations)
    }

    // Function to update the location model
    function updateLocationModel() {
        locationModel.clear()

        // Add "Use current location" option
        locationModel.append({
            name: "Use current location",
            isCustom: false,
            latitude: 0,
            longitude: 0
        })

        // Add custom locations
        for (let i = 0; i < customLocations.length; i++) {
            const location = customLocations[i]
            locationModel.append({
                name: location.name,
                isCustom: true,
                latitude: location.latitude,
                longitude: location.longitude
            })
        }
    }

    // Function to add a new custom location
    function addCustomLocation(name, latitude, longitude) {
        customLocations.push({
            name: name,
            latitude: latitude,
            longitude: longitude
        })
        saveCustomLocations()
        updateLocationModel()
    }

    // Function to remove a custom location
    function removeCustomLocation(index) {
        if (index > 0 && index < locationModel.count) { // Skip "Use current location"
            const customIndex = index - 1
            customLocations.splice(customIndex, 1)
            saveCustomLocations()
            // updateLocationModel()

            // // If the removed location was selected, switch to current location
            // if (listView.currentIndex === index) {
            //     listView.currentIndex = 0
            // }
        }
    }

    // Function to edit a custom location
    function editCustomLocation(index) {
        if (index > 0 && index < locationModel.count) { // Skip "Use current location"
            const customIndex = index - 1
            const location = customLocations[customIndex]

            // Set dialog properties for editing
            addLocationDialog.locationName = location.name
            addLocationDialog.latitude = location.latitude
            addLocationDialog.longitude = location.longitude
            addLocationDialog.editingIndex = customIndex
            addLocationDialog.isEditing = true
            addLocationDialog.open()
        }
    }

    // Function to handle location editing
    function handleLocationEdited(index, name, latitude, longitude) {
        if (index >= 0 && index < customLocations.length) {
            customLocations[index] = {
                name: name,
                latitude: latitude,
                longitude: longitude
            }
            saveCustomLocations()
            updateLocationModel()
        }
    }

    Header {
        id: header
        text: "Settings"
    }

    ScrollView {
        id: scrollView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        ListModel {
            id: locationModel
        }

        Column {
            width: parent.width
            spacing: 20

            // Observer height section
            Column {
                width: parent.width
                spacing: 10

                Label {
                    text: "Observer height (meters)"
                    font.bold: true
                }

                SpinBox {
                    from: 0
                    to: 100
                    editable: true
                    stepSize: 1
                    value: root.selfHeight
                    onValueChanged: {
                        root.selfHeight = value
                    }
                }
            }

            // Location section
            Column {
                width: parent.width
                spacing: 10

                Label {
                    text: "Location"
                    font.bold: true
                }

                ListView {
                    id: listView
                    width: parent.width
                    height: Math.max(80, locationModel.count * 60)
                    model: locationModel

                    currentIndex: useHardCodedPosition ? 1 : 0

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && currentIndex < locationModel.count) {
                            const item = locationModel.get(currentIndex)
                            root.useHardCodedPosition = currentIndex > 0
                            if (item.isCustom) {
                                root.hardcodedLatitude = item.latitude
                                root.hardcodedLongitude = item.longitude
                            }
                        }
                    }

                    delegate: SwipeDelegate {
                        id: swipeDelegate
                        text: model.name
                        width: listView.width
                        onClicked: listView.currentIndex = index
                        swipe.enabled: index > 0 // Disable swiping for "Use current location" (index 0)

                        background: Rectangle {
                            color: listView.currentIndex === index ? "#e0e0e0" : "white"
                            radius: 4
                        }

                        ListView.onRemove: removeAnimation.start()

                        SequentialAnimation {
                            id: removeAnimation

                            PropertyAction {
                                target: swipeDelegate
                                property: "ListView.delayRemove"
                                value: true
                            }
                            NumberAnimation {
                                target: swipeDelegate
                                property: "height"
                                to: 0
                                easing.type: Easing.InOutQuad
                            }
                            PropertyAction {
                                target: swipeDelegate
                                property: "ListView.delayRemove"
                                value: false
                            }
                        }

                        swipe.right: Label {
                            id: deleteLabel
                            text: qsTr("Delete")
                            color: "white"
                            verticalAlignment: Label.AlignVCenter
                            padding: 12
                            height: parent.height
                            anchors.right: parent.right

                            SwipeDelegate.onClicked: {
                                removeCustomLocation(index)
                                listView.model.remove(index)
                            }

                            background: Rectangle {
                                color: deleteLabel.SwipeDelegate.pressed ? Qt.darker("tomato", 1.1) : "tomato"
                            }
                        }
                    }
                }

                // Add location button
                Button {
                    text: "Add Custom Location"
                    width: parent.width
                    height: 40
                    onClicked: {
                        addLocationDialog.open()
                    }
                }
            }
        }
    }

    // Add Location Dialog
    AddLocationDialog {
        id: addLocationDialog
        onLocationAdded: function(name, lat, lon) {
            addCustomLocation(name, lat, lon)
        }
        onLocationEdited: function(index, name, lat, lon) {
            handleLocationEdited(index, name, lat, lon)
        }
    }
}
