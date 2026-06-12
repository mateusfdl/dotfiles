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
    id: obsidianTodoScope

    property bool isOpen: GlobalStates.obsidianTodoOpen

    onIsOpenChanged: {
        if (isOpen)
            ObsidianTodo.fetchTags();
    }

    function closeWindow() {
        GlobalStates.obsidianTodoOpen = false;
    }

    Variants {
        model: Quickshell.screens

        FocusedMonitorPanel {
            id: todoWindow

            requestVisible: GlobalStates.obsidianTodoOpen

            WlrLayershell.namespace: "quickshell:obsidiantodo"
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
                        obsidianTodoScope.closeWindow();
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

                    radius: Appearance.rounding?.large ?? 23
                    color: Appearance.m3colors?.m3windowBackground ?? "#1a1b26"
                    border.color: Appearance.m3colors?.m3borderSecondary ?? "#414868"
                    border.width: 1
                    z: 10

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            mouse.accepted = true;
                        }
                        z: -1
                    }

                    ObsidianTodoContent {
                        id: todoContent
                        width: parent.width
                        isOpen: GlobalStates.obsidianTodoOpen
                        onCloseRequested: obsidianTodoScope.closeWindow()
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveEnter.duration
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: ObsidianTodo
        function onSaved() {
            obsidianTodoScope.closeWindow();
        }
        function onSaveFailed(error) {
            console.warn("[ObsidianTodo] Save failed:", error);
            obsidianTodoScope.closeWindow();
        }
    }

    IpcHandler {
        target: "obsidiantodo"

        function toggle() {
            GlobalStates.obsidianTodoOpen = !GlobalStates.obsidianTodoOpen;
        }
        function close() {
            GlobalStates.obsidianTodoOpen = false;
        }
        function open() {
            GlobalStates.obsidianTodoOpen = true;
        }
    }

    GlobalShortcut {
        name: "obsidianTodoToggle"
        description: qsTr("Toggles Obsidian TODO popup")
        onPressed: {
            GlobalStates.obsidianTodoOpen = !GlobalStates.obsidianTodoOpen;
        }
    }

    GlobalShortcut {
        name: "obsidianTodoClose"
        description: qsTr("Closes Obsidian TODO popup")
        onPressed: {
            GlobalStates.obsidianTodoOpen = false;
        }
    }
}
