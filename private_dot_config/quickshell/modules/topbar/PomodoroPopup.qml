import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services
pragma Singleton

Scope {
    id: pomodoroPopupScope

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
            Topbar.PopupManager.closeAllExcept("pomodoro");
            showPopup(x, y);
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popup

            required property var modelData

            screen: modelData
            visible: pomodoroPopupScope.popupVisible
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // Background overlay
            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: pomodoroPopupScope.popupVisible
                onClicked: {
                    pomodoroPopupScope.hidePopup();
                }
            }

            // Popup window
            Rectangle {
                id: popupBackground

                x: pomodoroPopupScope.popupX
                y: pomodoroPopupScope.popupVisible ? pomodoroPopupScope.popupY : -1000
                width: 350
                height: 400
                radius: 16
                color: Appearance.colors.colLayer1
                border.color: Appearance.m3colors.m3borderSecondary
                border.width: 1
                z: 10
                layer.enabled: true

                // Prevent clicks from passing through
                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        mouse.accepted = true;
                    }
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        MaterialSymbol {
                            text: "timer"
                            iconSize: 32
                            fill: 1
                            color: Qt.rgba(1, 0.5, 0.5, 1)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: "Pomodoro Timer"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: Appearance.m3colors.m3primaryText
                            }

                            StyledText {
                                text: Pomodoro.stateLabel
                                font.pixelSize: 12
                                color: {
                                    if (Pomodoro.state === Pomodoro.State.Working)
                                        return Qt.rgba(1, 0.4, 0.4, 0.9);
                                    else if (Pomodoro.state === Pomodoro.State.ShortBreak || Pomodoro.state === Pomodoro.State.LongBreak)
                                        return Qt.rgba(0.4, 0.8, 1, 0.9);
                                    else
                                        return Qt.rgba(1, 1, 1, 0.6);
                                }
                            }

                        }

                    }

                    // Circular progress and timer display
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        Layout.alignment: Qt.AlignHCenter

                        // Background circle
                        Rectangle {
                            anchors.centerIn: parent
                            width: 180
                            height: 180
                            radius: 90
                            color: Appearance.colors.colLayer2
                            border.color: Appearance.m3colors.m3borderSecondary
                            border.width: 2
                        }

                        // Progress circle
                        Canvas {
                            id: progressCircle

                            property real progress: Pomodoro.progress

                            anchors.centerIn: parent
                            width: 180
                            height: 180
                            onProgressChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = 85;
                                // Draw progress arc
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + (progress * 2 * Math.PI), false);
                                ctx.lineWidth = 8;
                                ctx.strokeStyle = Pomodoro.state === Pomodoro.State.Working ? Qt.rgba(1, 0.4, 0.4, 0.9) : Qt.rgba(0.4, 0.8, 1, 0.9);
                                ctx.lineCap = "round";
                                ctx.stroke();
                            }
                        }

                        // Timer text
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: Pomodoro.displayTime
                                font.pixelSize: 42
                                font.weight: Font.Bold
                                font.family: "monospace"
                                color: Appearance.m3colors.m3primaryText
                            }

                            // Cycle indicator
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6

                                Repeater {
                                    model: Pomodoro.pomodorosUntilLongBreak

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: index < Pomodoro.currentCycle ? Qt.rgba(1, 0.4, 0.4, 0.9) : Qt.rgba(1, 1, 1, 0.2)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 300
                                            }

                                        }

                                    }

                                }

                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Completed: " + Pomodoro.completedPomodoros
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3secondaryText
                            }

                        }

                    }

                    // Control buttons
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        spacing: 12

                        RippleButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            buttonRadius: 10
                            visible: !Pomodoro.isRunning && !Pomodoro.isPaused
                            onClicked: Pomodoro.start()

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                MaterialSymbol {
                                    text: "play_arrow"
                                    iconSize: 24
                                    fill: 1
                                    color: Appearance.m3colors.m3primaryText
                                }

                                StyledText {
                                    text: "Start"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.m3primaryText
                                }

                            }

                        }

                        RippleButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            buttonRadius: 10
                            visible: Pomodoro.isRunning
                            onClicked: Pomodoro.pause()

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                MaterialSymbol {
                                    text: "pause"
                                    iconSize: 24
                                    fill: 1
                                    color: Qt.rgba(1, 0.8, 0.4, 0.95)
                                }

                                StyledText {
                                    text: "Pause"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.m3primaryText
                                }

                            }

                        }

                        RippleButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            buttonRadius: 10
                            visible: Pomodoro.isPaused
                            onClicked: Pomodoro.resume()

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                MaterialSymbol {
                                    text: "play_arrow"
                                    iconSize: 24
                                    fill: 1
                                    color: Qt.rgba(0.4, 1, 0.4, 0.95)
                                }

                                StyledText {
                                    text: "Resume"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.m3primaryText
                                }

                            }

                        }

                        RippleButton {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            buttonRadius: 10
                            visible: Pomodoro.isRunning || Pomodoro.isPaused
                            onClicked: Pomodoro.stop()

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "stop"
                                iconSize: 24
                                fill: 1
                                color: Qt.rgba(1, 0.4, 0.4, 0.95)
                            }

                        }

                        RippleButton {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            buttonRadius: 10
                            visible: Pomodoro.isRunning || Pomodoro.isPaused
                            onClicked: Pomodoro.skip()

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_next"
                                iconSize: 24
                                fill: 1
                                color: Qt.rgba(0.7, 0.7, 1, 0.95)
                            }

                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Appearance.m3colors.m3borderSecondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: "Work:"
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3secondaryText
                                Layout.preferredWidth: 45
                            }

                            StyledText {
                                text: (Pomodoro.workDuration / 60) + " min"
                                font.pixelSize: 11
                                font.family: "monospace"
                                color: Appearance.m3colors.m3surfaceText
                                Layout.fillWidth: true
                            }

                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: "Break:"
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3secondaryText
                                Layout.preferredWidth: 45
                            }

                            StyledText {
                                text: (Pomodoro.shortBreakDuration / 60) + " min"
                                font.pixelSize: 11
                                font.family: "monospace"
                                color: Appearance.m3colors.m3surfaceText
                                Layout.fillWidth: true
                            }

                        }

                    }

                }

                // Elevator animation from top
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
