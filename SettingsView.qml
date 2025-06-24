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
            updateLocationModel()
            
            // If the removed location was selected, switch to current location
            if (listView.currentIndex === index) {
                listView.currentIndex = 0
            }
        }
    }

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

                Rectangle {
                    width: root.width
                    height: Math.max(80, locationModel.count * 50)
                    border.color: "lightgray"
                    border.width: 1

                    Component {
                        id: locationDelegate
                        Item {
                            width: root.width
                            height: 50
                            
                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                
                                Text {
                                    id: nameText
                                    text: name
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: 14
                                }
                                
                                Item { 
                                    width: parent.width - nameText.width - 50
                                }
                                
                                // Delete button for custom locations
                                Button {
                                    id: deleteButton
                                    visible: isCustom
                                    text: "×"
                                    width: 30
                                    height: 30
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: {
                                        removeCustomLocation(index)
                                    }
                                }
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
                            if (currentIndex >= 0 && currentIndex < locationModel.count) {
                                const item = locationModel.get(currentIndex)
                                root.useHardCodedPosition = currentIndex > 0
                                if (item.isCustom) {
                                    root.hardcodedLatitude = item.latitude
                                    root.hardcodedLongitude = item.longitude
                                }
                            }
                        }

                        anchors.fill: parent
                        model: locationModel
                        delegate: locationDelegate
                        highlight: Rectangle { 
                            color: "lightsteelblue"
                            radius: 5
                        }
                        focus: true
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

                // Manual coordinates section (only visible when custom location is selected)
                Column {
                    visible: listView.currentIndex > 0
                    width: parent.width
                    spacing: 10
                    
                    Label {
                        text: "Manual Coordinates"
                        font.bold: true
                    }

                    Label {
                        text: "Latitude"
                    }
                    TextField {
                        id: latitudeText
                        width: root.width
                        height: 40
                        placeholderText: "Enter latitude"
                        text: root.hardcodedLatitude
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        onTextChanged: {
                            const parsedValue = parseFloat(text)
                            if (!isNaN(parsedValue)) {
                                root.hardcodedLatitude = parsedValue
                            }
                        }
                    }

                    Label {
                        text: "Longitude"
                    }
                    TextField {
                        id: longitudeText
                        width: root.width
                        height: 40
                        placeholderText: "Enter longitude"
                        text: root.hardcodedLongitude
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        onTextChanged: {
                            const parsedValue = parseFloat(text)
                            if (!isNaN(parsedValue)) {
                                root.hardcodedLongitude = parsedValue
                            }
                        }
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
    }
}
