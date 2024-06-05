import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import HeightReader 1.0
import QtPositioning

import "qrc:/"

Window {
    id: root
    width: 720
    height: 1280
    visible: true
    property alias debug: settings.debug

    Settings {
        property alias useHardCodedPosition: settings.useHardCodedPosition
        property alias hardcodedLongitude: settings.hardcodedLongitude
        property alias hardcodedLatitude: settings.hardcodedLatitude
        property alias selfHeight: settings.selfHeight
    }

    ARViewer {
        id: mainView
        debug: root.debug
        useHardCodedPosition: settings.useHardCodedPosition
        hardcodedLongitude: settings.hardcodedLongitude
        hardcodedLatitude: settings.hardcodedLatitude
        selfHeight: settings.selfHeight
    }

    SettingsView {
        id: settings
    }

    StackView {
        id: stack
        initialItem: mainView
        anchors.fill: parent
    }

    SettingsButton {
        id: settingsButton
    }

    WelcomeScreen {
        id: welcomeScreen
        visible: true
        anchors.fill: parent
    }
}
