import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Dialog {
    id: root
    title: isEditing ? "Edit Custom Location" : "Add Custom Location"
    modal: true
    
    // Dynamic positioning and sizing for better mobile support
    x: Math.max(0, (parent ? parent.width - width : 0) / 2)
    y: Math.max(20, (parent ? parent.height - height : 0) / 2)
    width: parent ? parent.width * 0.95 : 400
    height: parent ? parent.height * 0.8 : 500
    
    // Ensure dialog doesn't go off-screen
    onWidthChanged: {
        if (parent && x + width > parent.width) {
            x = parent.width - width - 10
        }
    }
    
    onHeightChanged: {
        if (parent && y + height > parent.height) {
            y = parent.height - height - 10
        }
    }

    function parseStupidFloat(text) {
        const parsedValue = parseFloat(text.replace(",","."))
        return parsedValue
    }
    
    property string locationName: ""
    property real latitude: 0.0
    property real longitude: 0.0
    property bool isEditing: false
    property int editingIndex: -1
    
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
        anchors.fill: parent
        anchors.margins: 10
        clip: true
        
        ColumnLayout {
            width: parent.width
            spacing: 15
            
            Label {
                text: "Location Name"
                font.bold: true
                Layout.fillWidth: true
            }
            
            TextField {
                id: nameField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: "Enter location name"
                text: root.locationName
                focus: true
                onTextChanged: root.locationName = text
            }
            
            Label {
                text: "Latitude"
                font.bold: true
                Layout.fillWidth: true
            }
            
            TextField {
                id: latField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: "Enter latitude (e.g., 59.901484)"
                text: root.latitude.toString()
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: {
                    const parsedValue = parseStupidFloat(text)
                    if (!isNaN(parsedValue)) {
                        root.latitude = parsedValue
                    }
                }
            }
            
            Label {
                text: "Longitude"
                font.bold: true
                Layout.fillWidth: true
            }
            
            TextField {
                id: lonField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: "Enter longitude (e.g., 10.751129)"
                text: root.longitude.toString()
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: {
                    const parsedValue = parseStupidFloat(text)
                    if (!isNaN(parsedValue)) {
                        root.longitude = parsedValue
                    }
                }
            }
            
            // Add some spacing before buttons
            Item {
                Layout.preferredHeight: 20
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "Cancel"
                    flat: true // Makes it look like a less prominent action
                    palette.buttonText: "gray"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 40
                    onClicked: root.close()
                }
                
                Button {
                    text: isEditing ? "Save" : "Add"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 40
                    enabled: nameField.text.trim() !== "" && 
                             !isNaN(parseFloat(latField.text)) && 
                             !isNaN(parseFloat(lonField.text))
                    onClicked: {
                        if (isEditing) {
                            root.locationEdited(editingIndex, nameField.text.trim(), 
                                              parseStupidFloat(latField.text),
                                              parseStupidFloat(lonField.text))
                        } else {
                            root.locationAdded(nameField.text.trim(), 
                                             parseStupidFloat(latField.text),
                                             parseStupidFloat(lonField.text))
                        }
                        root.close()
                    }
                }
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
