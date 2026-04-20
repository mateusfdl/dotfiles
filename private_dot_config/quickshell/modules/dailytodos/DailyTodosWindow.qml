pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.effects
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

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: todosWindow

            required property var modelData

            screen: modelData
            visible: GlobalStates.dailyTodosOpen
            color: "transparent"

            WlrLayershell.namespace: "quickshell:dailytodos"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.dailyTodosOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Item {
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    enabled: GlobalStates.dailyTodosOpen
                    onClicked: {
                        dailyTodosScope.closeWindow();
                    }
                }

                Elevation {
                    anchors.fill: panelBackground
                    radius: panelBackground.radius
                    level: GlobalStates.dailyTodosOpen ? 4 : 0
                }

                Rectangle {
                    id: panelBackground

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: GlobalStates.dailyTodosOpen ? (parent.height - height) / 2 : -1000
                    width: 700
                    height: Math.min(todosContent.implicitHeight, parent.height - 120)

                    radius: Appearance.rounding?.large ?? 23
                    color: Appearance.m3colors?.m3windowBackground ?? "#1a1b26"
                    border.color: Appearance.m3colors?.m3borderSecondary ?? "#414868"
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
                            duration: Appearance.animation.elementMoveEnter.duration
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
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
