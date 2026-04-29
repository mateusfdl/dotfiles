pragma Singleton
import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.effects
import qs.modules.common.widgets
import qs.services
import QsUtils

Scope {
    id: pomodoroPopupScope

    property bool popupVisible: false
    property real popupX: 0
    property real popupY: 0
    property bool todoPickerExpanded: false

    function showPopup(x, y) {
        popupX = x;
        popupY = y;
        popupVisible = true;
        ObsidianTodo.fetchTodos();
    }

    function hidePopup() {
        popupVisible = false;
        todoPickerExpanded = false;
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

            WlrLayershell.namespace: "quickshell:pomodoro"

            HyprlandWindow.visibleMask: Region {
                item: pomodoroPopupScope.popupVisible ? popupBackground : null
            }

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // Background overlay — click to dismiss
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
                y: pomodoroPopupScope.popupY
                width: 350
                height: popupColumn.implicitHeight + 48  // 24 margin × 2
                radius: 16
                color: Qt.rgba(0.08, 0.08, 0.09, 0.78)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                z: 10

                // Prevent clicks from passing through
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => {
                        mouse.accepted = true;
                    }
                    z: -1
                }

                // Gear icon — absolute top-right corner
                RippleButton {
                    id: gearButton
                    z: 20
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 10
                    anchors.rightMargin: 10
                    width: 26
                    height: 26
                    buttonRadius: 13
                    toggled: settingsSection.visible
                    onClicked: settingsSection.visible = !settingsSection.visible

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "settings"
                        iconSize: 15
                        fill: settingsSection.visible ? 1 : 0
                        color: Appearance.m3colors.m3secondaryText

                        Behavior on fill {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: popupColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24
                    spacing: 20

                    // ── Header ──
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

                    // ── Active Todo / Todo Picker ──
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: Pomodoro.currentTodo !== null || (!Pomodoro.isRunning && !Pomodoro.isPaused)

                        // Active todo display (shown when a todo is picked)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: activeTodoRow.implicitHeight + 16
                            radius: 8
                            color: Pomodoro.currentTodo !== null ? Qt.rgba(1, 0.4, 0.4, 0.08) : "transparent"
                            border.color: Pomodoro.currentTodo !== null ? Qt.rgba(1, 0.4, 0.4, 0.25) : Appearance.m3colors.m3borderSecondary
                            border.width: 1
                            visible: Pomodoro.currentTodo !== null || (!Pomodoro.isRunning && !Pomodoro.isPaused)

                            RowLayout {
                                id: activeTodoRow
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                MaterialSymbol {
                                    text: Pomodoro.currentTodo !== null ? "task_alt" : "add_task"
                                    iconSize: 18
                                    fill: Pomodoro.currentTodo !== null ? 1 : 0
                                    color: Pomodoro.currentTodo !== null ? Qt.rgba(1, 0.4, 0.4, 0.9) : Appearance.m3colors.m3secondaryText
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Pomodoro.currentTodo !== null ? Pomodoro.currentTodo.description : "Pick a task..."
                                    font.pixelSize: 12
                                    font.weight: Pomodoro.currentTodo !== null ? Font.Medium : Font.Normal
                                    color: Pomodoro.currentTodo !== null ? Appearance.m3colors.m3primaryText : Appearance.m3colors.m3secondaryText
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                // Clear button (only when todo is picked and idle)
                                RippleButton {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    buttonRadius: 11
                                    visible: Pomodoro.currentTodo !== null && !Pomodoro.isRunning && !Pomodoro.isPaused
                                    onClicked: {
                                        Pomodoro.clearTodo();
                                        pomodoroPopupScope.todoPickerExpanded = false;
                                    }

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 14
                                        color: Appearance.m3colors.m3secondaryText
                                    }
                                }

                                // Expand/collapse chevron (only when idle)
                                MaterialSymbol {
                                    text: pomodoroPopupScope.todoPickerExpanded ? "expand_less" : "expand_more"
                                    iconSize: 16
                                    color: Appearance.m3colors.m3secondaryText
                                    visible: !Pomodoro.isRunning && !Pomodoro.isPaused
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: (!Pomodoro.isRunning && !Pomodoro.isPaused) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                enabled: !Pomodoro.isRunning && !Pomodoro.isPaused
                                onClicked: {
                                    pomodoroPopupScope.todoPickerExpanded = !pomodoroPopupScope.todoPickerExpanded;
                                    if (pomodoroPopupScope.todoPickerExpanded) {
                                        ObsidianTodo.fetchTodos();
                                    }
                                }
                            }
                        }

                        // Todo list (expanded when picker is open)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(todoListView.contentHeight + 4, 180)
                            radius: 8
                            color: Appearance.colors.colLayer2
                            border.color: Appearance.m3colors.m3borderSecondary
                            border.width: 1
                            visible: pomodoroPopupScope.todoPickerExpanded && !Pomodoro.isRunning && !Pomodoro.isPaused
                            clip: true

                            ListView {
                                id: todoListView
                                anchors.fill: parent
                                anchors.margins: 2
                                model: ObsidianTodo.todos
                                spacing: 1

                                delegate: Rectangle {
                                    id: todoDelegate

                                    required property var modelData
                                    required property int index

                                    width: todoListView.width
                                    height: todoDelegateRow.implicitHeight + 12
                                    radius: 6
                                    color: todoDelegateMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"

                                    RowLayout {
                                        id: todoDelegateRow
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 8

                                        MaterialSymbol {
                                            text: "radio_button_unchecked"
                                            iconSize: 14
                                            color: Appearance.m3colors.m3secondaryText
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: todoDelegate.modelData.description || ""
                                                font.pixelSize: 12
                                                color: Appearance.m3colors.m3primaryText
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }

                                            // Tags row
                                            Row {
                                                spacing: 4
                                                visible: todoDelegate.modelData.tags && todoDelegate.modelData.tags.length > 0

                                                Repeater {
                                                    model: todoDelegate.modelData.tags || []

                                                    Rectangle {
                                                        required property var modelData

                                                        width: tagLabel.implicitWidth + 8
                                                        height: tagLabel.implicitHeight + 4
                                                        radius: 3
                                                        color: Qt.rgba(1, 1, 1, 0.06)

                                                        StyledText {
                                                            id: tagLabel
                                                            anchors.centerIn: parent
                                                            text: "#" + parent.modelData
                                                            font.pixelSize: 9
                                                            color: Appearance.m3colors.m3secondaryText
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: todoDelegateMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const todo = todoDelegate.modelData;
                                            let noteId = todo.noteId || "";

                                            // If no linked note, create one
                                            if (noteId === "") {
                                                noteId = ObsidianTodo.ensureNoteFile(todo.description, todo.tags || []);
                                                if (noteId === "")
                                                    return; // failed
                                                // Refresh todos to get updated data
                                                ObsidianTodo.fetchTodos();
                                            }

                                            Pomodoro.pickupTodo(todo.description, noteId, todo.tags || []);
                                            pomodoroPopupScope.todoPickerExpanded = false;
                                        }
                                    }
                                }

                                // Empty state
                                StyledText {
                                    anchors.centerIn: parent
                                    text: "No open tasks for today"
                                    font.pixelSize: 11
                                    color: Appearance.m3colors.m3secondaryText
                                    visible: todoListView.count === 0
                                }
                            }
                        }
                    }

                    // ── Circular progress and timer display ──
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

                    // ── Control buttons ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        spacing: 12

                        // Start (visible when idle)
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

                        // Pause (visible when running)
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

                        // Resume (visible when paused)
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

                        // Stop
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

                        // Skip
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

                    // ── Separator ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Appearance.m3colors.m3borderSecondary
                    }

                    // ── Duration info (always visible, compact) ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        StyledText {
                            text: "Focus: " + (Pomodoro.workDuration / 60) + "m"
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: Appearance.m3colors.m3secondaryText
                        }

                        StyledText {
                            text: "Break: " + (Pomodoro.shortBreakDuration / 60) + "m"
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: Appearance.m3colors.m3secondaryText
                        }

                        StyledText {
                            text: "Long: " + (Pomodoro.longBreakDuration / 60) + "m"
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: Appearance.m3colors.m3secondaryText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        MaterialSymbol {
                            text: Pomodoro.lockOnBreak ? "lock" : "lock_open"
                            iconSize: 14
                            fill: Pomodoro.lockOnBreak ? 1 : 0
                            color: Pomodoro.lockOnBreak ? Qt.rgba(0.4, 0.8, 1, 0.9) : Appearance.m3colors.m3secondaryText
                        }
                    }

                    // ── Settings section (toggled by gear icon) ──
                    ColumnLayout {
                        id: settingsSection

                        Layout.fillWidth: true
                        spacing: 12
                        visible: false

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Appearance.m3colors.m3borderSecondary
                        }

                        StyledText {
                            text: "Settings"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3primaryText
                        }

                        // Focus duration
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialSymbol {
                                text: "target"
                                iconSize: 18
                                color: Qt.rgba(1, 0.4, 0.4, 0.8)
                            }

                            StyledText {
                                text: "Focus"
                                font.pixelSize: 12
                                color: Appearance.m3colors.m3surfaceText
                                Layout.fillWidth: true
                            }

                            StyledSpinBox {
                                id: workSpinBox
                                from: 1
                                to: 120
                                stepSize: 5
                                value: Pomodoro.workDuration / 60
                                onValueModified: Pomodoro.setWorkDuration(value)
                            }

                            StyledText {
                                text: "min"
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3secondaryText
                            }
                        }

                        // Short break duration
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialSymbol {
                                text: "coffee"
                                iconSize: 18
                                color: Qt.rgba(0.4, 0.8, 1, 0.8)
                            }

                            StyledText {
                                text: "Short Break"
                                font.pixelSize: 12
                                color: Appearance.m3colors.m3surfaceText
                                Layout.fillWidth: true
                            }

                            StyledSpinBox {
                                id: shortBreakSpinBox
                                from: 1
                                to: 60
                                stepSize: 1
                                value: Pomodoro.shortBreakDuration / 60
                                onValueModified: Pomodoro.setShortBreakDuration(value)
                            }

                            StyledText {
                                text: "min"
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3secondaryText
                            }
                        }

                        // Long break duration
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialSymbol {
                                text: "self_improvement"
                                iconSize: 18
                                color: Qt.rgba(0.6, 0.4, 1, 0.8)
                            }

                            StyledText {
                                text: "Long Break"
                                font.pixelSize: 12
                                color: Appearance.m3colors.m3surfaceText
                                Layout.fillWidth: true
                            }

                            StyledSpinBox {
                                id: longBreakSpinBox
                                from: 1
                                to: 60
                                stepSize: 5
                                value: Pomodoro.longBreakDuration / 60
                                onValueModified: Pomodoro.setLongBreakDuration(value)
                            }

                            StyledText {
                                text: "min"
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3secondaryText
                            }
                        }

                        // Lock on break toggle
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialSymbol {
                                text: "lock"
                                iconSize: 18
                                color: Pomodoro.lockOnBreak ? Qt.rgba(0.4, 0.8, 1, 0.9) : Qt.rgba(1, 1, 1, 0.4)
                            }

                            StyledText {
                                text: "Lock screen on break"
                                font.pixelSize: 12
                                color: Appearance.m3colors.m3surfaceText
                                Layout.fillWidth: true
                            }

                            StyledSwitch {
                                checked: Pomodoro.lockOnBreak
                                onCheckedChanged: Pomodoro.lockOnBreak = checked
                            }
                        }

                        // Bottom padding
                        Item {
                            Layout.preferredHeight: 4
                        }
                    }
                }



            }

            Elevation {
                anchors.fill: popupBackground
                radius: popupBackground.radius
                level: pomodoroPopupScope.popupVisible ? 4 : 0
            }
        }
    }
}
