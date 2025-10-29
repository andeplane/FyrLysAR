import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtPositioning

Dialog {
    id: root
    property var selfCoord
    title: isEditing ? "Edit Custom Location" : "Add Custom Location"
    modal: true
    
    // Dynamic positioning and sizing for better mobile support
    width: parent ? parent.width * 0.95 : 400
    height: parent ? parent.height * 0.8 : 500
    anchors.centerIn: parent
    
    property string locationName: ""
    property real latitude: 0.0
    property real longitude: 0.0
    property bool isEditing: false
    property int editingIndex: -1
    
    // Margin constants for consistent spacing
    readonly property int horizontalMargin: 16
    readonly property int verticalMargin: 8
    
    signal locationAdded(string name, real lat, real lon)
    signal locationEdited(int index, string name, real lat, real lon)

    onOpened: {
        // Ensure TextField values are properly set
        nameField.text = root.locationName
        latField.text = root.latitude.toString()
        lonField.text = root.longitude.toString()
    }
    
    // Use ScrollView to handle content overflow on small screens
    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
        anchors.topMargin: root.verticalMargin
        anchors.bottomMargin: root.verticalMargin
        clip: true
        
        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 8
            
            Label {
                text: "Location Name"
                font.bold: true
                color: palette.windowText
                Layout.fillWidth: true
            }
            
            TextField {
                id: nameField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                placeholderText: "Enter location name"
                text: root.locationName
                focus: true
                onTextChanged: root.locationName = text
            }
            
            Label {
                text: "Latitude"
                font.bold: true
                color: palette.windowText
                Layout.fillWidth: true
            }
            
            TextField {
                id: latField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                placeholderText: "Enter latitude (e.g., 59.901484)"
                text: root.latitude.toString()
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: {
                    const parsedValue = parseFloat(text.replace(",","."))
                    if (!isNaN(parsedValue)) {
                        root.latitude = parsedValue
                    }
                }
            }
            
            Label {
                text: "Longitude"
                font.bold: true
                color: palette.windowText
                Layout.fillWidth: true
            }
            
            TextField {
                id: lonField
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                placeholderText: "Enter longitude (e.g., 10.751129)"
                text: root.longitude.toString()
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: {
                    const parsedValue = parseFloat(text.replace(",","."))
                    if (!isNaN(parsedValue)) {
                        root.longitude = parsedValue
                    }
                }
            }
            
            // Choose on Map button
            Button {
                text: "Choose on Map"
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                background: Rectangle {
                    color: parent.pressed ? "#e3f2fd" : "#2196f3"
                    border.color: "#1976d2"
                    border.width: 1
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.bold: true
                }
                onClicked: {
                    mapDialog.open()
                }
            }
            
            // Add some spacing before buttons
            Item {
                Layout.preferredHeight: 10
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 8
                
                Button {
                    text: "Cancel"
                    flat: true // Makes it look like a less prominent action
                    palette.buttonText: "gray"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 35
                    onClicked: root.close()
                }
                
                Button {
                    text: isEditing ? "Save" : "Add"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 35
                    enabled: nameField.text.trim() !== "" && 
                             !isNaN(root.latitude) &&
                             !isNaN(root.longitude)
                    onClicked: {
                        if (isEditing) {
                            root.locationEdited(editingIndex, nameField.text.trim(), root.latitude, root.longitude)
                        } else {
                            root.locationAdded(nameField.text.trim(), root.latitude, root.longitude)
                        }
                        root.close()
                    }
                }
            }
        }
    }
    
    // Map selection dialog
    Dialog {
        id: mapDialog
        property var initialCenter: QtPositioning.coordinate(0, 0)
        title: "Choose Location on Map"
        modal: true
        width: root.width
        height: root.height
        anchors.centerIn: parent

        onOpened: {
            initialCenter = root.selfCoord
        }
        
        MapLocationSelector {
            id: mapSelector
            anchors.fill: parent
            selfCoord: root.selfCoord
            center: (root.latitude === 0.0 && root.longitude === 0.0) ? mapDialog.initialCenter : QtPositioning.coordinate(root.latitude, root.longitude)

            onHardcodedLocationSet: function(lat, lon) {
                root.latitude = lat
                root.longitude = lon
                latField.text = lat.toString()
                lonField.text = lon.toString()
                mapDialog.close()
            }
            
            onHardcodedLocationCancelled: function() {
                mapDialog.close()
            }
        }
    }
    
    onClosed: {
        // Reset fields when dialog is closed
        nameField.text = ""
        latField.text = ""
        lonField.text = ""
        root.locationName = ""
        root.latitude = 0.0
        root.longitude = 0.0
        root.isEditing = false
        root.editingIndex = -1
    }
} 
