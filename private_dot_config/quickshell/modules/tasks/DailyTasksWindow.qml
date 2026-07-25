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
    id: dailyTasksScope

    property bool isOpen: GlobalStates.dailyTasksOpen

    onIsOpenChanged: {
        if (isOpen)
            Tasks.fetchTodos();
    }

    function closeWindow() {
        GlobalStates.dailyTasksOpen = false;
    }

    Variants {
        model: Quickshell.screens

        FocusedMonitorPanel {
            id: todosWindow

            requestVisible: GlobalStates.dailyTasksOpen

            WlrLayershell.namespace: "quickshell:dailytasks"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: todosWindow.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Item {
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    enabled: todosWindow.isActive
                    onClicked: {
                        dailyTasksScope.closeWindow();
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

                    DailyTasksContent {
                        id: todosContent
                        width: parent.width
                        isOpen: GlobalStates.dailyTasksOpen
                        onCloseRequested: dailyTasksScope.closeWindow()
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
        target: "dailytasks"

        function toggle() {
            GlobalStates.dailyTasksOpen = !GlobalStates.dailyTasksOpen;
        }
        function close() {
            GlobalStates.dailyTasksOpen = false;
        }
        function open() {
            GlobalStates.dailyTasksOpen = true;
        }
    }

    GlobalShortcut {
        name: "dailyTasksToggle"
        description: qsTr("Toggles Daily Tasks popup")
        onPressed: {
            GlobalStates.dailyTasksOpen = !GlobalStates.dailyTasksOpen;
        }
    }

    GlobalShortcut {
        name: "dailyTasksClose"
        description: qsTr("Closes Daily Tasks popup")
        onPressed: {
            GlobalStates.dailyTasksOpen = false;
        }
    }
}
