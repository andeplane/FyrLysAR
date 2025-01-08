import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    anchors.fill: parent
    color: "#000000"
    property real scalingFactor: Math.max(width, 320)/430 // Looks good on 430 screen
    property real textFontSize: 20*scalingFactor

      ColumnLayout {
          anchors.fill: parent

          Rectangle {
              color: "black"
              Text {
                  text: "Welcome to"
                  y: 20
                  anchors { horizontalCenter: parent.horizontalCenter }
                  font.pixelSize: 50
                  color: "#ffffff"
              }
              Text {
                  text: "FyrLysAR"
                  y: 25 + font.pixelSize
                  anchors { horizontalCenter: parent.horizontalCenter }
                  font.pixelSize: 50
                  color: "#ffffff"
              }
              Layout.fillWidth: true
              Layout.fillHeight: false
              Layout.minimumHeight: 200*scalingFactor
          }
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 75
            Rectangle {
                color: "black"
                Layout.fillWidth: true
                Layout.fillHeight: true
                RowLayout {
                    Layout.margins: 10
                    Rectangle {
                        color: "black"
                        width: 110*scalingFactor
                        Layout.fillHeight: true
                        AnimatedImage {
                            width: 45*scalingFactor
                            height: 75*scalingFactor
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: "qrc:///images/light2.gif"
                        }
                    }

                    ColumnLayout {
                        Layout.minimumHeight: 75
                        Text {
                            Layout.fillWidth: true
                            text: "Lighthouses during daytime"
                            font.pixelSize: textFontSize
                            font.bold: true
                            color: "#ffffff"
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                            verticalAlignment: TextInput.AlignTop
                            text: "View flash patterns from<br>nearby lighthouses even<br>during daytime."
                            font.pixelSize: textFontSize
                            color: "#ffffff"
                        }
                    }
                }
            }
            Rectangle {
                color: "black"
                Layout.fillWidth: true
                Layout.fillHeight: true
                RowLayout {
                    Layout.margins: 10
                    Rectangle {
                        color: "black"
                        width: 110*scalingFactor
                        Layout.fillHeight: true
                        AnimatedImage {
                            width: 75*scalingFactor
                            height: 75*scalingFactor
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: "qrc:///images/crosshair.png"
                        }
                    }

                    ColumnLayout {
                        Layout.minimumHeight: 75
                        Text {
                            Layout.fillWidth: true
                            text: "Lighthouse info"
                            font.pixelSize: textFontSize
                            font.bold: true
                            color: "#ffffff"
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.Wrap
                            verticalAlignment: TextInput.AlignTop
                            text: "Point the crosshair at the<br>lighthouse you want to know<br> more about."
                            font.pixelSize: textFontSize
                            color: "#ffffff"
                        }
                    }
                }
            }
            Rectangle {
                color: "black"
                Layout.fillWidth: true
                Layout.fillHeight: true
                RowLayout {
                    Layout.margins: 10
                    Rectangle {
                        color: "black"
                        width: 110*scalingFactor
                        Layout.fillHeight: true
                        Image {
                            width: 75 * scalingFactor
                            height: 75 * scalingFactor
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: "qrc:///images/gear-white.svg"
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    ColumnLayout {
                        Layout.minimumHeight: 75
                        Text {
                            Layout.fillWidth: true
                            text: "Customize position"
                            font.pixelSize: textFontSize
                            font.bold: true
                            color: "#ffffff"
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            wrapMode: Text.Wrap
                            verticalAlignment: TextInput.AlignTop
                            text: "Plan your trip by customizing<br>positions and be prepared for<br>what you will see at sea."
                            font.pixelSize: textFontSize
                            color: "#ffffff"
                        }
                    }
                }
            }
          }
          Rectangle {
              color: "black"
              Layout.fillWidth: true
              Layout.fillHeight: false
              Layout.minimumHeight: 70
              Button {
                  width: parent.width * 0.7
                  height: 50
                  anchors { horizontalCenter: parent.horizontalCenter }
                  text: "Get started"
                  onClicked: {
                      root.visible = false
                  }
              }
          }
      }
}
