import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
pragma Singleton

Scope {
    id: controlCenterScope

    property bool popupVisible: false
    property real popupX: 0
    property real popupY: 0

    function showPopup(x, y) {
        popupX = x;
        popupY = y;
        popupVisible = true;
    }

    function hidePopup() {
        popupVisible = false;
    }

    function togglePopup(x, y) {
        if (popupVisible) {
            hidePopup();
        } else {
            Topbar.PopupManager.closeAllExcept("controlcenter");
            showPopup(x, y);
        }
    }


    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popup

            required property var modelData

            screen: modelData
            visible: controlCenterScope.popupVisible
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: controlCenterScope.popupVisible
                onClicked: {
                    controlCenterScope.hidePopup();
                }
            }

            Rectangle {
                id: panelBackground

                x: controlCenterScope.popupX
                y: controlCenterScope.popupVisible ? controlCenterScope.popupY : -1000
                width: 420
                height: Math.max(contentColumn.implicitHeight + 40, 800)
                radius: 20
                color: Appearance.colors.colLayer1
                border.color: Appearance.m3colors.m3borderSecondary
                border.width: 1
                z: 10
                layer.enabled: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        mouse.accepted = true;
                    }
                    z: -1
                }

                ColumnLayout {
                    id: contentColumn

                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        radius: 16
                        color: Appearance.colors.colLayer2
                        border.color: Appearance.m3colors.m3borderSecondary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 24
                                color: Qt.rgba(1, 0.8, 0.2, 0.9)

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "person"
                                    iconSize: 28
                                    fill: 1
                                    color: Qt.rgba(0.1, 0.1, 0.1, 1)
                                }

                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                StyledText {
                                    text: SystemInfo.username
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: Appearance.m3colors.m3primaryText
                                }

                                RowLayout {
                                    spacing: 6

                                    MaterialSymbol {
                                        text: "schedule"
                                        iconSize: 14
                                        fill: 0
                                        color: Appearance.m3colors.m3secondaryText
                                    }

                                    StyledText {
                                        text: "Uptime: " + SystemInfo.uptime
                                        font.pixelSize: 12
                                        color: Appearance.m3colors.m3secondaryText
                                    }

                                }

                            }

                            RippleButton {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                buttonRadius: 24
                                onClicked: {
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "power_settings_new"
                                    iconSize: 24
                                    fill: 0
                                    color: Qt.rgba(1, 0.3, 0.3, 1)
                                }

                            }

                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        radius: 16
                        color: Appearance.colors.colLayer2
                        border.color: Appearance.m3colors.m3borderSecondary
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                MaterialSymbol {
                                    text: "wb_sunny"
                                    iconSize: 28
                                    fill: 1
                                    color: Qt.rgba(1, 0.8, 0.2, 1)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    StyledText {
                                        text: "Weather"
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: Appearance.m3colors.m3secondaryText
                                    }

                                }

                                StyledText {
                                    text: "20°C"
                                    font.pixelSize: 36
                                    font.weight: Font.Bold
                                    color: Appearance.m3colors.m3primaryText
                                }

                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: ["Mon", "Tue", "Wed", "Thu", "Fri"]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 70
                                        radius: 8
                                        color: Appearance.m3colors.m3layerBackground3

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            StyledText {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: modelData
                                                font.pixelSize: 11
                                                color: Appearance.m3colors.m3surfaceText
                                            }

                                            MaterialSymbol {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "cloud"
                                                iconSize: 20
                                                fill: 1
                                                color: Appearance.m3colors.m3secondaryText
                                            }

                                            StyledText {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "18°"
                                                font.pixelSize: 12
                                                font.weight: Font.Medium
                                                color: Appearance.m3colors.m3surfaceText
                                            }

                                        }

                                    }

                                }

                            }

                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        radius: 16
                        color: Appearance.colors.colLayer2
                        border.color: Appearance.m3colors.m3borderSecondary
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                MaterialSymbol {
                                    text: "music_note"
                                    iconSize: 20
                                    fill: 1
                                    color: Qt.rgba(1, 0.6, 0.8, 1)
                                }

                                StyledText {
                                    text: "Now Playing"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.m3surfaceText
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: MediaPlayer.hasActivePlayer ? (MediaPlayer.identity || "") : "No player"
                                    font.pixelSize: 11
                                    color: Appearance.m3colors.m3secondaryText
                                }

                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 80
                                    Layout.preferredHeight: 80
                                    radius: 10
                                    color: Appearance.m3colors.m3layerBackground3

                                    Image {
                                        id: albumArt

                                        anchors.fill: parent
                                        source: MediaPlayer.hasActivePlayer ? MediaPlayer.artUrl : ""
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        asynchronous: true
                                        visible: MediaPlayer.hasActivePlayer && status === Image.Ready
                                        layer.enabled: true

                                        layer.effect: OpacityMask {

                                            maskSource: Rectangle {
                                                width: albumArt.width
                                                height: albumArt.height
                                                radius: 10
                                            }

                                        }

                                    }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "album"
                                        iconSize: 40
                                        fill: 1
                                        color: Appearance.m3colors.m3secondaryText
                                        visible: !MediaPlayer.hasActivePlayer || albumArt.status !== Image.Ready
                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: MediaPlayer.hasActivePlayer ? (MediaPlayer.title || "No track") : "No media playing"
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                        color: Appearance.m3colors.m3primaryText
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: MediaPlayer.hasActivePlayer ? (MediaPlayer.artist || "Unknown Artist") : "Start playing music to see controls"
                                        font.pixelSize: 12
                                        color: Appearance.m3colors.m3surfaceText
                                        elide: Text.ElideRight
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                    }

                                    Item {
                                        Layout.fillHeight: true
                                    }

                                }

                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                spacing: 8
                                opacity: MediaPlayer.hasActivePlayer ? 1 : 0.4

                                Item {
                                    Layout.fillWidth: true
                                }

                                RippleButton {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    buttonRadius: 22
                                    enabled: MediaPlayer.hasActivePlayer && MediaPlayer.canGoPrevious
                                    onClicked: MediaPlayer.previous()

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "skip_previous"
                                        iconSize: 24
                                        fill: 1
                                        color: (MediaPlayer.hasActivePlayer && MediaPlayer.canGoPrevious) ? Appearance.m3colors.m3primaryText : Appearance.m3colors.m3secondaryText
                                    }

                                }

                                RippleButton {
                                    Layout.preferredWidth: 52
                                    Layout.preferredHeight: 52
                                    buttonRadius: 26
                                    enabled: MediaPlayer.hasActivePlayer
                                    onClicked: MediaPlayer.playPause()

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: MediaPlayer.isPlaying ? "pause" : "play_arrow"
                                        iconSize: 32
                                        fill: 1
                                        color: Qt.rgba(1, 0.6, 0.8, 1)
                                    }

                                }

                                RippleButton {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    buttonRadius: 22
                                    enabled: MediaPlayer.hasActivePlayer && MediaPlayer.canGoNext
                                    onClicked: MediaPlayer.next()

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "skip_next"
                                        iconSize: 24
                                        fill: 1
                                        color: (MediaPlayer.hasActivePlayer && MediaPlayer.canGoNext) ? Appearance.m3colors.m3primaryText : Appearance.m3colors.m3secondaryText
                                    }

                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                            }

                        }

                    }

                    Process {
                        id: themeSwitchProcess

                        running: false
                        command: ["/home/matheus/scripts/switch-theme-mode"]
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: [{
                                "icon": "wifi",
                                "label": "Wi-Fi",
                                "active": true
                            }, {
                                "icon": "bluetooth",
                                "label": "Bluetooth",
                                "active": false
                            }, {
                                "icon": Appearance.currentThemeMode === "dark" ? "nightlight" : "light_mode",
                                "label": Appearance.currentThemeMode === "dark" ? "Dark" : "Light",
                                "active": false
                            }]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                radius: 16
                                color: modelData.active ? Appearance.m3colors.m3selectionBackground : Appearance.colors.colLayer2
                                border.color: Appearance.m3colors.m3borderSecondary
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    MaterialSymbol {
                                        text: modelData.icon
                                        iconSize: 24
                                        fill: modelData.active ? 1 : 0
                                        color: modelData.active ? Appearance.m3colors.m3accentPrimary : Appearance.m3colors.m3surfaceText
                                    }

                                    StyledText {
                                        text: modelData.label
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: Appearance.m3colors.m3surfaceText
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    z: 10
                                    onClicked: {
                                        if (modelData.label === "Dark" || modelData.label === "Light")
                                            themeSwitchProcess.running = true;

                                    }
                                }

                            }

                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: [{
                                "icon": "settings",
                                "label": "Settings",
                                "action": ""
                            }, {
                                "icon": "radio_button_checked",
                                "label": "Record",
                                "action": "record"
                            }, {
                                "icon": "wallpaper",
                                "label": "Wallpaper",
                                "action": ""
                            }]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                radius: 14
                                color: (modelData.action === "record" && ScreenRecorder.isRecording) ? Qt.rgba(1, 0.2, 0.2, 0.3) : Appearance.colors.colLayer2
                                border.color: (modelData.action === "record" && ScreenRecorder.isRecording) ? Qt.rgba(1, 0.3, 0.3, 0.8) : Appearance.m3colors.m3borderSecondary
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    MaterialSymbol {
                                        text: (modelData.action === "record" && ScreenRecorder.isRecording) ? "stop_circle" : modelData.icon
                                        iconSize: 20
                                        fill: (modelData.action === "record" && ScreenRecorder.isRecording) ? 1 : 0
                                        color: (modelData.action === "record" && ScreenRecorder.isRecording) ? Qt.rgba(1, 0.3, 0.3, 1) : Appearance.m3colors.m3surfaceText

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 300
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: (modelData.action === "record" && ScreenRecorder.isRecording) ? "Stop" : modelData.label
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: (modelData.action === "record" && ScreenRecorder.isRecording) ? Qt.rgba(1, 0.3, 0.3, 1) : Appearance.m3colors.m3surfaceText

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 300
                                            }
                                        }
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    z: 100
                                    onClicked: {
                                        if (modelData.action === "record") {
                                            ScreenRecorder.toggle();
                                        } else if (modelData.label === "Wallpaper") {
                                            GlobalStates.wallpaperSelectorOpen = true;
                                        }
                                    }
                                }

                            }

                        }

                    }

                }

                Behavior on y {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }

                }

                layer.effect: DropShadow {
                    radius: 32
                    samples: 65
                    color: Qt.rgba(0, 0, 0, 0.7)
                    verticalOffset: 8
                    horizontalOffset: 0
                }

            }

        }

    }

}
