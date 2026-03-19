pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Fullscreen overlay displayed during Pomodoro breaks when lockOnBreak is enabled.
 * Covers all screens with a dark backdrop and a countdown timer.
 * Auto-dismisses when the break ends (state transitions to Idle).
 * The user cannot dismiss it manually — they must wait for the break to finish.
 */
Scope {
    id: overlayScope

    readonly property bool shouldShow: Pomodoro.lockOnBreak && Pomodoro.isOnBreak

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlayWindow

            required property var modelData

            screen: modelData
            visible: overlayScope.shouldShow
            color: "transparent"

            WlrLayershell.namespace: "quickshell:pomodoro-break"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: overlayScope.shouldShow ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // Eat all mouse events so nothing underneath is clickable
            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: overlayScope.shouldShow
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
                onClicked: mouse => {
                    mouse.accepted = true;
                }
                onPressed: mouse => {
                    mouse.accepted = true;
                }
                onReleased: mouse => {
                    mouse.accepted = true;
                }
                onWheel: wheel => {
                    wheel.accepted = true;
                }
            }

            // Dark backdrop
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: overlayScope.shouldShow ? 0.88 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Centered content
            Item {
                anchors.fill: parent
                z: 10
                opacity: overlayScope.shouldShow ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.OutCubic
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 24

                    // Break type icon
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: Pomodoro.state === Pomodoro.State.LongBreak ? "self_improvement" : "coffee"
                        iconSize: 64
                        fill: 1
                        color: Qt.rgba(0.4, 0.8, 1, 0.9)
                    }

                    // Break label
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Pomodoro.state === Pomodoro.State.LongBreak ? "Long Break" : "Short Break"
                        color: Qt.rgba(1, 1, 1, 0.9)
                        font.pixelSize: 28
                        font.family: Appearance.font.family.uiFont
                        font.weight: Font.Light
                    }

                    // Spacer
                    Item {
                        Layout.preferredHeight: 8
                    }

                    // Circular progress ring + countdown
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 240
                        Layout.preferredHeight: 240

                        // Background ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: 240
                            height: 240
                            radius: 120
                            color: Qt.rgba(1, 1, 1, 0.05)
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            border.width: 2
                        }

                        // Progress arc
                        Canvas {
                            id: overlayProgress

                            property real progress: Pomodoro.progress

                            anchors.centerIn: parent
                            width: 240
                            height: 240
                            onProgressChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                var centerX = width / 2;
                                var centerY = height / 2;
                                var r = 112;
                                // Background track
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, r, 0, 2 * Math.PI, false);
                                ctx.lineWidth = 6;
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                                ctx.stroke();
                                // Progress arc
                                if (progress > 0) {
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, r, -Math.PI / 2, -Math.PI / 2 + (progress * 2 * Math.PI), false);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = Qt.rgba(0.4, 0.8, 1, 0.9);
                                    ctx.lineCap = "round";
                                    ctx.stroke();
                                }
                            }
                        }

                        // Countdown text
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Pomodoro.displayTime
                                color: "#ffffff"
                                font.pixelSize: 64
                                font.weight: Font.Bold
                                font.family: "monospace"
                            }

                            // Cycle dots
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                Repeater {
                                    model: Pomodoro.pomodorosUntilLongBreak

                                    Rectangle {
                                        required property int index
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: index < Pomodoro.currentCycle ? Qt.rgba(0.4, 0.8, 1, 0.9) : Qt.rgba(1, 1, 1, 0.2)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 300
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Spacer
                    Item {
                        Layout.preferredHeight: 8
                    }

                    // Info text
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Screen will unlock when break ends"
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 14
                        font.family: Appearance.font.family.uiFont
                    }

                    // Completed pomodoros count
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Completed: " + Pomodoro.completedPomodoros + " pomodoros"
                        color: Qt.rgba(1, 1, 1, 0.3)
                        font.pixelSize: 12
                        font.family: Appearance.font.family.uiFont
                    }
                }
            }
        }
    }
}
