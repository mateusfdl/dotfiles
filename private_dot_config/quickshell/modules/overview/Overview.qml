import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QsUtils

Scope {
    id: overviewScope

    Variants {
        id: overviewVariants
        model: Quickshell.screens
        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor.id)
            screen: modelData
            visible: GlobalStates.overviewOpen

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: GlobalStates.overviewOpen ? contentArea : null
            }
            HyprlandWindow.visibleMask: Region {
                item: GlobalStates.overviewOpen ? contentArea : null
            }

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [ root ]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active) GlobalStates.overviewOpen = false
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen) {
                        delayedGrabTimer.start()
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive) return
                    grab.active = GlobalStates.overviewOpen
                }
            }

            implicitWidth: contentArea.implicitWidth
            implicitHeight: contentArea.implicitHeight

            Item {
                id: contentArea
                anchors.centerIn: parent
                implicitWidth: overviewLoader.item?.implicitWidth ?? 0
                implicitHeight: overviewLoader.item?.implicitHeight ?? 0
                focus: GlobalStates.overviewOpen

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false;
                        event.accepted = true;
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        var workspaceNum = event.key - Qt.Key_0;
                        GlobalStates.overviewOpen = false;
                        Hyprland.dispatch(`workspace ${workspaceNum}`);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_W || event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                        var nextId = HyprlandWorkspace.navigateForward(
                            HyprlandData.workspaceIds, root.monitor.activeWorkspace?.id ?? -1);
                        if (nextId >= 0) Hyprland.dispatch(`workspace ${nextId}`);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_B || event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                        var prevId = HyprlandWorkspace.navigateBackward(
                            HyprlandData.workspaceIds, root.monitor.activeWorkspace?.id ?? -1);
                        if (prevId >= 0) Hyprland.dispatch(`workspace ${prevId}`);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_N) {
                        var newId = HyprlandWorkspace.insertWorkspaceAfter(
                            HyprlandData.workspaceIds, root.monitor.activeWorkspace?.id ?? -1);
                        if (newId >= 0) Hyprland.dispatch(`workspace ${newId}`);
                        event.accepted = true;
                    }
                }

                Loader {
                    id: overviewLoader
                    active: GlobalStates.overviewOpen
                    anchors.centerIn: parent
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
        function close() {
            GlobalStates.overviewOpen = false
        }
        function open() {
            GlobalStates.overviewOpen = true
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false
        }
    }

    GlobalShortcut {
        name: "overviewToggle"
        description: qsTr("Toggles overview on press")

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }

    GlobalShortcut {
        name: "overviewClose"
        description: qsTr("Closes overview")

        onPressed: {
            GlobalStates.overviewOpen = false
        }
    }

    GlobalShortcut {
        name: "overviewToggleRelease"
        description: qsTr("Toggles overview on release")

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true
                return
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }

    GlobalShortcut {
        name: "overviewToggleReleaseInterrupt"
        description: qsTr("Interrupts possibility of overview being toggled on release.")

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false
        }
    }
}
