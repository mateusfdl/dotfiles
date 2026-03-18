pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: sessionMenuScope

    readonly property bool menuVisible: GlobalStates.sessionOpen

    function show() {
        GlobalStates.sessionOpen = true;
    }

    function hide() {
        GlobalStates.sessionOpen = false;
    }

    function toggle() {
        GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
    }

    function doLock() {
        hide();
        GlobalStates.screenLocked = true;
    }

    function doSuspend() {
        hide();
        Quickshell.exec(["systemctl", "suspend"]);
    }

    function doReboot() {
        hide();
        Quickshell.exec(["systemctl", "reboot"]);
    }

    function doShutdown() {
        hide();
        Quickshell.exec(["systemctl", "poweroff"]);
    }

    function doLogout() {
        hide();
        Hyprland.dispatch("exit");
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: menuWindow

            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(menuWindow.screen)
            readonly property bool isActive: sessionMenuScope.menuVisible && (Hyprland.focusedMonitor?.id == monitor.id)

            screen: modelData
            visible: sessionMenuScope.menuVisible
            color: "transparent"

            WlrLayershell.namespace: "quickshell:sessionmenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: sessionMenuScope.menuVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusiveZone: 0

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [menuWindow]
                active: false
                onCleared: () => {
                    if (!active) sessionMenuScope.hide();
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: 100
                repeat: false
                onTriggered: {
                    grab.active = sessionMenuScope.menuVisible;
                }
            }

            Connections {
                target: sessionMenuScope
                function onMenuVisibleChanged() {
                    if (sessionMenuScope.menuVisible) {
                        delayedGrabTimer.start();
                    } else {
                        delayedGrabTimer.stop();
                        grab.active = false;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.7

                MouseArea {
                    anchors.fill: parent
                    onClicked: sessionMenuScope.hide()
                }
            }

            Item {
                anchors.fill: parent
                visible: menuWindow.isActive

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        sessionMenuScope.hide();
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 24

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Session"
                        color: Appearance.m3colors.m3primaryText
                        font.pixelSize: 28
                        font.family: Appearance.font.family.uiFont
                        font.weight: Font.Light
                    }

                    Item { Layout.preferredHeight: 16 }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 32

                        SessionButton {
                            icon: "lock"
                            label: "Lock"
                            onClicked: sessionMenuScope.doLock()
                        }

                        SessionButton {
                            icon: "bedtime"
                            label: "Suspend"
                            onClicked: sessionMenuScope.doSuspend()
                        }

                        SessionButton {
                            icon: "logout"
                            label: "Logout"
                            onClicked: sessionMenuScope.doLogout()
                        }

                        SessionButton {
                            icon: "restart_alt"
                            label: "Reboot"
                            iconColor: Appearance.color.primary
                            onClicked: sessionMenuScope.doReboot()
                        }

                        SessionButton {
                            icon: "power_settings_new"
                            label: "Shutdown"
                            iconColor: "#ff5555"
                            onClicked: sessionMenuScope.doShutdown()
                        }
                    }

                    Item { Layout.preferredHeight: 32 }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Press Escape or click outside to cancel"
                        color: Appearance.m3colors.m3secondaryText
                        font.pixelSize: 12
                        font.family: Appearance.font.family.uiFont
                    }
                }
            }
        }
    }

    component SessionButton: Item {
        id: btn
        property string icon: ""
        property string label: ""
        property color iconColor: Appearance.m3colors.m3primaryText

        signal clicked()

        implicitWidth: 80
        implicitHeight: 100

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 32
                color: btnMouseArea.containsMouse
                    ? Appearance.colors.colLayer1Hover
                    : Appearance.colors.colLayer2
                border.color: Appearance.m3colors.m3borderSecondary
                border.width: 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                scale: btnMouseArea.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: btn.icon
                    font.pixelSize: 28
                    color: btn.iconColor
                }

                MouseArea {
                    id: btnMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: btn.clicked()
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: btn.label
                color: Appearance.m3colors.m3primaryText
                font.pixelSize: 13
                font.family: Appearance.font.family.uiFont
            }
        }
    }
}
