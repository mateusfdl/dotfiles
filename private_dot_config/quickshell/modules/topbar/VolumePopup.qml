pragma Singleton
import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Scope {
    id: volumePopupScope

    property bool popupVisible: false
    property real popupX: 0
    property real popupY: 0
    property string outputDeviceName: "Speaker"

    function showPopup(x, y) {
        popupX = x;
        popupY = y;
        popupVisible = true;
        updateOutputDevice();
    }

    function hidePopup() {
        popupVisible = false;
    }

    function togglePopup(x, y) {
        if (popupVisible) {
            hidePopup();
        } else {
            Topbar.PopupManager.closeAllExcept("volume");
            showPopup(x, y);
        }
    }

    function updateOutputDevice() {
        deviceNameProcess.running = true;
    }

    property bool protectionTriggered: false
    property string protectionReason: ""

    Connections {
        target: Audio
        function onSinkProtectionTriggered(reason) {
            volumePopupScope.protectionTriggered = true;
            volumePopupScope.protectionReason = reason;
            protectionResetTimer.restart();
        }
    }

    Timer {
        id: protectionResetTimer
        interval: 2000
        onTriggered: {
            volumePopupScope.protectionTriggered = false;
        }
    }

    Process {
        id: deviceNameProcess

        running: false
        command: ["sh", "-c", "pactl list sinks | grep -A 1 'State: RUNNING' | grep 'Description:' | cut -d':' -f2 | xargs"]
        onExited: (exitCode, stdout, stderr) => {
            if (exitCode === 0 && stdout) {
                var device = stdout.trim();
                if (device)
                    volumePopupScope.outputDeviceName = device;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popup

            required property var modelData

            screen: modelData
            visible: volumePopupScope.popupVisible
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
                enabled: volumePopupScope.popupVisible
                onClicked: {
                    volumePopupScope.hidePopup();
                }
            }

            Rectangle {
                id: popupBackground

                x: volumePopupScope.popupX
                y: volumePopupScope.popupY
                width: 280
                height: volumePopupScope.protectionTriggered ? 130 : 100
                radius: 12
                color: Appearance.colors.colLayer1
                border.color: Appearance.m3colors.m3borderSecondary
                border.width: 1
                z: 10
                layer.enabled: true

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        mouse.accepted = true;
                    }
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Protection warning (only shown when triggered)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 6
                        color: Qt.rgba(1, 0.6, 0, 0.15)
                        border.color: Qt.rgba(1, 0.6, 0, 0.4)
                        border.width: 1
                        visible: volumePopupScope.protectionTriggered

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "warning"
                                iconSize: 14
                                fill: 1
                                color: Qt.rgba(1, 0.7, 0, 1)
                            }

                            StyledText {
                                text: "Volume protection active"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Qt.rgba(1, 0.8, 0.4, 1)
                            }
                        }
                    }

                    // Main content
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Volume slider row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                RippleButton {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    buttonRadius: 8
                                    onClicked: {
                                        if (Audio.sink?.audio) {
                                            Audio.sink.audio.muted = !Audio.sink.audio.muted;
                                        }
                                    }

                                    contentItem: MaterialSymbol {
                                        id: volumeIcon

                                        text: {
                                            if (Audio.sink?.audio?.muted ?? false)
                                                return "volume_off";

                                            const volume = (Audio.sink?.audio?.volume ?? 0) * 100;
                                            if (volume >= 70)
                                                return "volume_up";

                                            if (volume >= 30)
                                                return "volume_down";

                                            if (volume > 0)
                                                return "volume_mute";

                                            return "volume_off";
                                        }
                                        iconSize: 24
                                        fill: 1
                                        color: Audio.sink?.audio?.muted ? Appearance.m3colors.m3secondaryText : Appearance.m3colors.m3primaryText
                                    }
                                }

                                StyledSlider {
                                    id: volumeSlider

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    from: 0
                                    to: 1
                                    value: Audio.sink?.audio?.volume ?? 0
                                    onMoved: {
                                        if (Audio.sink?.audio) {
                                            Audio.sink.audio.volume = value;
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.preferredWidth: 36
                                    text: Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.m3primaryText
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            // Output device info
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                MaterialSymbol {
                                    text: "speaker"
                                    iconSize: 16
                                    fill: 1
                                    color: Appearance.m3colors.m3secondaryText
                                }

                                StyledText {
                                    text: volumePopupScope.outputDeviceName
                                    font.pixelSize: 12
                                    color: Appearance.m3colors.m3secondaryText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                layer.effect: DropShadow {
                    radius: 24
                    samples: 49
                    color: Qt.rgba(0, 0, 0, 0.6)
                    verticalOffset: 6
                    horizontalOffset: 0
                }
            }
        }
    }
}
