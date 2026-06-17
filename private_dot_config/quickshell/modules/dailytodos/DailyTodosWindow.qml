pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.effects
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QsUtils

Scope {
    id: dailyTodosScope

    property bool isOpen: GlobalStates.dailyTodosOpen

    onIsOpenChanged: {
        if (isOpen)
            ObsidianTodo.fetchTodos();
    }

    function closeWindow() {
        GlobalStates.dailyTodosOpen = false;
    }

    FileView {
        path: `${Config.vaultPath}/Journal/todos/views/pending.md`
        watchChanges: true
        onFileChanged: {
            reload();
            if (dailyTodosScope.isOpen)
                ObsidianTodo.fetchTodos();
        }
    }

    Variants {
        model: Quickshell.screens

        FocusedMonitorPanel {
            id: todosWindow

            requestVisible: GlobalStates.dailyTodosOpen

            WlrLayershell.namespace: "quickshell:dailytodos"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: todosWindow.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Item {
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    enabled: todosWindow.isActive
                    onClicked: {
                        dailyTodosScope.closeWindow();
                    }
                }

                Elevation {
                    anchors.fill: panelBackground
                    radius: panelBackground.radius
                    level: todosWindow.isActive ? 4 : 0
                }

                Rectangle {
                    id: panelBackground

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: todosWindow.isActive ? (parent.height - height) / 2 : -1000
                    width: 1000
                    height: Math.min(todosContent.implicitHeight, parent.height - 80)

                    radius: Appearance.rounding.large
                    color: Appearance.m3colors.m3windowBackground
                    border.color: Appearance.m3colors.m3borderSecondary
                    border.width: 1
                    z: 10
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            mouse.accepted = true;
                        }
                        z: -1
                    }

                    DailyTodosContent {
                        id: todosContent
                        width: parent.width
                        isOpen: GlobalStates.dailyTodosOpen
                        onCloseRequested: dailyTodosScope.closeWindow()
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: Style.animation.elementMoveEnter.duration
                            easing.type: Style.animation.elementMoveEnter.type
                            easing.bezierCurve: Style.animation.elementMoveEnter.bezierCurve
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "dailytodos"

        function toggle() {
            GlobalStates.dailyTodosOpen = !GlobalStates.dailyTodosOpen;
        }
        function close() {
            GlobalStates.dailyTodosOpen = false;
        }
        function open() {
            GlobalStates.dailyTodosOpen = true;
        }
    }

    GlobalShortcut {
        name: "dailyTodosToggle"
        description: qsTr("Toggles Daily TODOs popup")
        onPressed: {
            GlobalStates.dailyTodosOpen = !GlobalStates.dailyTodosOpen;
        }
    }

    GlobalShortcut {
        name: "dailyTodosClose"
        description: qsTr("Closes Daily TODOs popup")
        onPressed: {
            GlobalStates.dailyTodosOpen = false;
        }
    }
}
