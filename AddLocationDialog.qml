import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Dialog {
    id: root
    title: "Add Custom Location"
    modal: true
    x: (parent ? parent.width - width : 0) / 2
    y: 20
    width: parent.width * 0.95
    height: parent.height * 0.6
    
    property string locationName: ""
    property real latitude: 0.0
    property real longitude: 0.0
    
    signal locationAdded(string name, real lat, real lon)
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        Label {
            text: "Location Name"
            font.bold: true
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
        }
        
        TextField {
            id: latField
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            placeholderText: "Enter latitude (e.g., 59.901484)"
            text: root.latitude
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            validator: DoubleValidator { bottom: -90.0; top: 90.0; notation: DoubleValidator.StandardNotation }
            onTextChanged: {
                const parsedValue = parseFloat(text)
                if (!isNaN(parsedValue)) {
                    root.latitude = parsedValue
                }
            }
        }
        
        Label {
            text: "Longitude"
            font.bold: true
        }
        
        TextField {
            id: lonField
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            placeholderText: "Enter longitude (e.g., 10.751129)"
            text: root.longitude
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            validator: DoubleValidator { bottom: -180.0; top: 180.0; notation: DoubleValidator.StandardNotation }
            onTextChanged: {
                const parsedValue = parseFloat(text)
                if (!isNaN(parsedValue)) {
                    root.longitude = parsedValue
                }
            }
        }
        
        Item {
            Layout.fillHeight: true
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
                text: "Add"
                Layout.preferredWidth: 100
                Layout.preferredHeight: 40
                enabled: nameField.text.trim() !== "" && 
                         !isNaN(parseFloat(latField.text)) && 
                         !isNaN(parseFloat(lonField.text))
                onClicked: {
                    root.locationAdded(nameField.text.trim(), 
                                     parseFloat(latField.text), 
                                     parseFloat(lonField.text))
                    root.close()
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
    }
} 
