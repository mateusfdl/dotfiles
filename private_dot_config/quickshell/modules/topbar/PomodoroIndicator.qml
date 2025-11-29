import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    implicitWidth: contentRow.width + 16
    implicitHeight: contentRow.height

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            id: icon

            text: {
                if (Pomodoro.state === Pomodoro.State.Working)
                    return "timer"
                else if (Pomodoro.state === Pomodoro.State.ShortBreak ||
                         Pomodoro.state === Pomodoro.State.LongBreak)
                    return "coffee"
                else if (Pomodoro.isPaused)
                    return "pause_circle"
                else
                    return "timer"
            }
            iconSize: 20
            fill: Pomodoro.isRunning ? 1 : 0
            color: {
                if (Pomodoro.state === Pomodoro.State.Working)
                    return Qt.rgba(1, 0.4, 0.4, 0.9)  // Red for work
                else if (Pomodoro.state === Pomodoro.State.ShortBreak ||
                         Pomodoro.state === Pomodoro.State.LongBreak)
                    return Qt.rgba(0.4, 0.8, 1, 0.9)  // Blue for break
                else
                    return Qt.rgba(1, 1, 1, 0.7)      // White for idle
            }

            Behavior on color {
                ColorAnimation {
                    duration: 300
                }
            }
        }

        Text {
            id: timerText

            text: Pomodoro.displayTime
            color: {
                if (Pomodoro.state === Pomodoro.State.Working)
                    return Qt.rgba(1, 0.4, 0.4, 0.9)
                else if (Pomodoro.state === Pomodoro.State.ShortBreak ||
                         Pomodoro.state === Pomodoro.State.LongBreak)
                    return Qt.rgba(0.4, 0.8, 1, 0.9)
                else
                    return Qt.rgba(1, 1, 1, 0.7)
            }
            font.pixelSize: 14
            font.weight: Font.Medium
            font.family: "monospace"
            verticalAlignment: Text.AlignVCenter
            visible: Pomodoro.isRunning || Pomodoro.isPaused

            Behavior on color {
                ColorAnimation {
                    duration: 300
                }
            }
        }

        // Cycle indicator dots
        Row {
            spacing: 3
            visible: Pomodoro.isRunning || Pomodoro.isPaused

            Repeater {
                model: Pomodoro.pomodorosUntilLongBreak

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: index < Pomodoro.currentCycle ?
                        Qt.rgba(1, 0.4, 0.4, 0.9) :
                        Qt.rgba(1, 1, 1, 0.3)

                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
        radius: 4
        z: -1

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var pos = mapToItem(null, 0, 0)
            var iconRightX = pos.x + root.width
            var popupX = iconRightX - 350  // Popup width is 350
            var popupY = 2  // Right below the topbar, matching control center
            Topbar.PomodoroPopup.togglePopup(popupX, popupY)
        }
    }
}
