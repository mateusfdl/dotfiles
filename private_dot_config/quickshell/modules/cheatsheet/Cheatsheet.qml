pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.effects
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: cheatsheetScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: cheatsheetWindow

            required property var modelData

            screen: modelData
            visible: GlobalStates.cheatsheetOpen
            color: "transparent"

            WlrLayershell.namespace: "quickshell:cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.cheatsheetOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: GlobalStates.cheatsheetOpen
                onClicked: {
                    GlobalStates.cheatsheetOpen = false;
                }
            }

            Elevation {
                id: panelElevation

                anchors.fill: panelBackground
                radius: panelBackground.radius
                level: GlobalStates.cheatsheetOpen ? 4 : 0
            }

            Rectangle {
                id: panelBackground

                anchors.horizontalCenter: parent.horizontalCenter
                y: GlobalStates.cheatsheetOpen ? (parent.height - height) / 2 : -1000
                width: cheatsheetContent.implicitWidth
                height: cheatsheetContent.implicitHeight

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

                focus: GlobalStates.cheatsheetOpen
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                        GlobalStates.cheatsheetOpen = false;
                        event.accepted = true;
                    }
                }

                CheatsheetContent {
                    id: cheatsheetContent
                    maxWidth: Math.min(cheatsheetWindow.width * 0.95, 1700)
                    maxHeight: cheatsheetWindow.height * 0.45
                    width: parent.width
                    height: parent.height
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

    IpcHandler {
        target: "cheatsheet"

        function toggle() {
            GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen;
        }
        function close() {
            GlobalStates.cheatsheetOpen = false;
        }
        function open() {
            GlobalStates.cheatsheetOpen = true;
        }
    }

    GlobalShortcut {
        name: "cheatsheetToggle"
        description: qsTr("Toggles keybind cheatsheet")
        onPressed: {
            GlobalStates.cheatsheetOpen = !GlobalStates.cheatsheetOpen;
        }
    }

    GlobalShortcut {
        name: "cheatsheetClose"
        description: qsTr("Closes keybind cheatsheet")
        onPressed: {
            GlobalStates.cheatsheetOpen = false;
        }
    }
}
