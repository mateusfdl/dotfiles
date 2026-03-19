pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: launcherScope

    Variants {
        id: launcherVariants
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            readonly property bool isActive: GlobalStates.launcherOpen && (Hyprland.focusedMonitor?.id == monitor.id)

            screen: modelData
            visible: isActive

            WlrLayershell.namespace: "quickshell:launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            mask: Region {
                item: isActive ? launcherContent : null
            }
            HyprlandWindow.visibleMask: Region {
                item: isActive ? launcherContent : null
            }

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                active: false
                onCleared: () => {
                    if (!active)
                        GlobalStates.launcherOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onLauncherOpenChanged() {
                    if (GlobalStates.launcherOpen) {
                        delayedGrabTimer.start();
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!root.isActive)
                        return;
                    grab.active = GlobalStates.launcherOpen;
                }
            }

            implicitWidth: launcherContent.implicitWidth
            implicitHeight: launcherContent.implicitHeight

            Item {
                id: launcherContent
                visible: root.isActive
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: Math.max(parent.height * 0.15, 80)
                }

                implicitWidth: wrapper.implicitWidth
                implicitHeight: wrapper.implicitHeight

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.launcherOpen = false;
                    }
                }

                Loader {
                    id: wrapper
                    active: root.isActive
                    sourceComponent: WrapperSimple {
                        screen: root.screen
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            GlobalStates.launcherOpen = !GlobalStates.launcherOpen;
        }
        function close() {
            GlobalStates.launcherOpen = false;
        }
        function open() {
            GlobalStates.launcherOpen = true;
        }
    }

    GlobalShortcut {
        name: "launcherToggle"
        description: qsTr("Toggles launcher on press")

        onPressed: {
            GlobalStates.launcherOpen = !GlobalStates.launcherOpen;
        }
    }

    GlobalShortcut {
        name: "launcherClose"
        description: qsTr("Closes launcher")

        onPressed: {
            GlobalStates.launcherOpen = false;
        }
    }
}
