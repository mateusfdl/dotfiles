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
    id: tasksScope

    property bool isOpen: GlobalStates.tasksOpen

    onIsOpenChanged: {
        if (isOpen)
            Tasks.fetchTags();
    }

    function closeWindow() {
        GlobalStates.tasksOpen = false;
    }

    Variants {
        model: Quickshell.screens

        FocusedMonitorPanel {
            id: todoWindow

            requestVisible: GlobalStates.tasksOpen

            WlrLayershell.namespace: "quickshell:tasks"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: todoWindow.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Item {
                id: keyHandler
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    enabled: todoWindow.isActive
                    onClicked: {
                        tasksScope.closeWindow();
                    }
                }

                Elevation {
                    anchors.fill: panelBackground
                    radius: panelBackground.radius
                    level: todoWindow.isActive ? 4 : 0
                }

                Rectangle {
                    id: panelBackground

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: todoWindow.isActive ? (parent.height - height) / 2 : -1000
                    width: 950
                    height: todoContent.implicitHeight

                    radius: Appearance.rounding.large
                    color: Appearance.m3colors.m3windowBackground
                    border.color: Appearance.m3colors.m3borderSecondary
                    border.width: 1
                    z: 10

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            mouse.accepted = true;
                        }
                        z: -1
                    }

                    TasksContent {
                        id: todoContent
                        width: parent.width
                        isOpen: GlobalStates.tasksOpen
                        onCloseRequested: tasksScope.closeWindow()
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

    Connections {
        target: Tasks
        function onSaved() {
            tasksScope.closeWindow();
        }
        function onSaveFailed(error) {
            console.warn("[Tasks] Save failed:", error);
            tasksScope.closeWindow();
        }
    }

    IpcHandler {
        target: "tasks"

        function toggle() {
            GlobalStates.tasksOpen = !GlobalStates.tasksOpen;
        }
        function close() {
            GlobalStates.tasksOpen = false;
        }
        function open() {
            GlobalStates.tasksOpen = true;
        }
    }

    GlobalShortcut {
        name: "tasksToggle"
        description: qsTr("Toggles Tasks popup")
        onPressed: {
            GlobalStates.tasksOpen = !GlobalStates.tasksOpen;
        }
    }

    GlobalShortcut {
        name: "tasksClose"
        description: qsTr("Closes Tasks popup")
        onPressed: {
            GlobalStates.tasksOpen = false;
        }
    }
}
