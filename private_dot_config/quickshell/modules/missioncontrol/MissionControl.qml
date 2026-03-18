import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QsUtils
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: missionControlScope

    MissionControlModel {
        id: mcModel
    }

    Connections {
        target: mcModel
        function onRestored() {
            GlobalStates.missionControlOpen = false
        }
    }

    Variants {
        id: missionControlVariants
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            readonly property bool monitorIsFocused: Hyprland.focusedMonitor?.id == monitor.id

            screen: modelData
            visible: GlobalStates.missionControlOpen
            color: "transparent"

            WlrLayershell.namespace: "quickshell:missioncontrol"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: GlobalStates.missionControlOpen ? clickCatcher : null }
            HyprlandWindow.visibleMask: Region { item: GlobalStates.missionControlOpen ? clickCatcher : null }

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active) closeMissionControl()
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive) return
                    grab.active = GlobalStates.missionControlOpen
                }
            }

            Connections {
                target: GlobalStates
                function onMissionControlOpenChanged() {
                    if (GlobalStates.missionControlOpen) {
                        openMissionControl()
                    }
                }
            }

            function openMissionControl() {
                mcModel.refresh(
                    root.width,
                    root.height,
                    root.monitor.x,
                    root.monitor.y,
                    root.monitor.id,
                    root.monitor.activeWorkspace?.id ?? -1,
                    28
                )
                delayedGrabTimer.start()
                exposeTimer.start()
            }

            function closeMissionControl() {
                if (mcModel.animating) return
                if (mcModel.exposed) {
                    mcModel.restore("")
                } else {
                    GlobalStates.missionControlOpen = false
                }
            }

            Timer {
                id: exposeTimer
                interval: 50
                repeat: false
                onTriggered: {
                    mcModel.expose()
                }
            }

            // Transparent full-screen click catcher
            Item {
                id: clickCatcher
                anchors.fill: parent

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        closeMissionControl()
                        event.accepted = true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                    onClicked: (event) => {
                        if (mcModel.animating) return

                        const addr = mcModel.windowAt(event.x, event.y)

                        if (event.button === Qt.LeftButton) {
                            // Restore all windows, then focus the clicked one
                            mcModel.restore(addr)
                        } else if (event.button === Qt.MiddleButton && addr !== "") {
                            // Close the clicked window
                            Hyprland.dispatch(`closewindow address:${addr}`)
                            // Re-expose after a short delay
                            refreshAfterCloseTimer.start()
                        }
                    }
                }

                Timer {
                    id: refreshAfterCloseTimer
                    interval: 250
                    repeat: false
                    onTriggered: {
                        // Re-fetch and re-expose with updated window list
                        mcModel.refresh(
                            root.width, root.height,
                            root.monitor.x, root.monitor.y,
                            root.monitor.id,
                            root.monitor.activeWorkspace?.id ?? -1,
                            28
                        )
                        exposeTimer.start()
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "missioncontrol"

        function toggle() {
            if (GlobalStates.missionControlOpen) {
                for (let i = 0; i < missionControlVariants.instances.length; i++) {
                    const inst = missionControlVariants.instances[i]
                    if (inst.monitorIsFocused) {
                        inst.closeMissionControl()
                        return
                    }
                }
                GlobalStates.missionControlOpen = false
            } else {
                GlobalStates.missionControlOpen = true
            }
        }
        function close() {
            for (let i = 0; i < missionControlVariants.instances.length; i++) {
                const inst = missionControlVariants.instances[i]
                if (inst.monitorIsFocused) {
                    inst.closeMissionControl()
                    return
                }
            }
            GlobalStates.missionControlOpen = false
        }
        function open() {
            GlobalStates.missionControlOpen = true
        }
    }

    GlobalShortcut {
        name: "missionControlToggle"
        description: qsTr("Toggle Mission Control expose view")

        onPressed: {
            if (GlobalStates.missionControlOpen) {
                for (let i = 0; i < missionControlVariants.instances.length; i++) {
                    const inst = missionControlVariants.instances[i]
                    if (inst.monitorIsFocused) {
                        inst.closeMissionControl()
                        return
                    }
                }
                GlobalStates.missionControlOpen = false
            } else {
                GlobalStates.missionControlOpen = true
            }
        }
    }
}
