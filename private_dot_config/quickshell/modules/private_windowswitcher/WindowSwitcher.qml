import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.modules.common.functions
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: windowSwitcherScope

    property int currentIndex: 0
    property var filteredWindows: []
    property var windowAddresses: []

    function updateWindowList() {
        let windows = HyprlandData.windowList.filter(win => !win.hidden && win.mapped)
        windows.sort((a, b) => {
            if (a.address === Hyprland.focusedWindow?.address) return -1
            if (b.address === Hyprland.focusedWindow?.address) return 1
            return 0
        })
        filteredWindows = windows
        windowAddresses = windows.map(w => w.address)
        currentIndex = filteredWindows.length > 1 ? 1 : 0
    }

    function next() {
        if (filteredWindows.length === 0) return
        currentIndex = (currentIndex + 1) % filteredWindows.length
    }

    function previous() {
        if (filteredWindows.length === 0) return
        currentIndex = (currentIndex - 1 + filteredWindows.length) % filteredWindows.length
    }

    function activateSelected() {
        if (windowAddresses.length === 0 || currentIndex >= windowAddresses.length) {
            GlobalStates.windowSwitcherOpen = false
            return
        }
        let selectedAddress = windowAddresses[currentIndex]
        GlobalStates.windowSwitcherOpen = false
        Hyprland.dispatch("focuswindow", "address:" + selectedAddress)
    }

    Variants {
        id: windowSwitcherVariants
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor.id)
            screen: modelData
            visible: GlobalStates.windowSwitcherOpen

            WlrLayershell.namespace: "quickshell:windowswitcher"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            mask: Region {
                item: GlobalStates.windowSwitcherOpen ? switcherLayout : null
            }

            HyprlandWindow.visibleMask: Region {
                item: GlobalStates.windowSwitcherOpen ? switcherLayout : null
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
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active) GlobalStates.windowSwitcherOpen = false
                }
            }

            Connections {
                target: GlobalStates
                function onWindowSwitcherOpenChanged() {
                    if (GlobalStates.windowSwitcherOpen) {
                        windowSwitcherScope.updateWindowList()
                        delayedGrabTimer.start()
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: 100
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive) return
                    grab.active = GlobalStates.windowSwitcherOpen
                }
            }

            ColumnLayout {
                id: switcherLayout
                visible: GlobalStates.windowSwitcherOpen
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.windowSwitcherOpen = false
                        event.accepted = true
                    }
                }

                Rectangle {
                    id: switcherContainer
                    implicitWidth: listView.contentWidth + 60
                    implicitHeight: 160
                    Layout.preferredWidth: Math.min(implicitWidth, root.width * 0.85)
                    Layout.preferredHeight: implicitHeight

                    radius: Appearance.rounding.large
                    color: Appearance.m3colors.m3layerBackground2
                    opacity: 0.95
                    border.width: 0

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 8
                        radius: 24
                        samples: 49
                        color: ColorUtils.transparentize(Appearance.m3colors.m3shadowColor, 0.4)
                    }

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.margins: 30
                        orientation: ListView.Horizontal
                        spacing: 15
                        clip: true

                        model: windowSwitcherScope.filteredWindows
                        currentIndex: windowSwitcherScope.currentIndex

                        highlightFollowsCurrentItem: true
                        highlightMoveDuration: 200
                        highlightMoveVelocity: -1

                        delegate: Item {
                            id: windowItem
                            required property var modelData
                            required property int index

                            property bool isSelected: index === windowSwitcherScope.currentIndex
                            property string iconPath: Quickshell.iconPath(AppSearch.guessIcon(modelData?.class), "image-missing")

                            width: 100
                            height: 100

                            Rectangle {
                                anchors.centerIn: parent
                                width: 80
                                height: 80
                                radius: Appearance.rounding.large
                                color: windowItem.isSelected ? Appearance.m3colors.m3selectionBackground : Appearance.m3colors.m3layerBackground1
                                border.color: windowItem.isSelected ? Appearance.m3colors.m3accentPrimary : "transparent"
                                border.width: windowItem.isSelected ? 2 : 0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }

                                Image {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    source: windowItem.iconPath
                                    width: 48
                                    height: 48
                                    sourceSize: Qt.size(48, 48)
                                    smooth: true

                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        horizontalOffset: 0
                                        verticalOffset: 2
                                        radius: 6
                                        samples: 13
                                        color: ColorUtils.transparentize("#000000", 0.6)
                                    }
                                }
                            }

                            scale: isSelected ? 1.15 : 1.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    windowSwitcherScope.currentIndex = index
                                    windowSwitcherScope.activateSelected()
                                }

                                onEntered: {
                                    windowSwitcherScope.currentIndex = index
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "windowSwitcherNext"
        description: "Switch to next window in window switcher"

        onPressed: {
            if (!GlobalStates.windowSwitcherOpen) {
                GlobalStates.windowSwitcherOpen = true
            } else {
                windowSwitcherScope.next()
            }
        }
    }

    GlobalShortcut {
        name: "windowSwitcherPrevious"
        description: "Switch to previous window in window switcher"

        onPressed: {
            if (GlobalStates.windowSwitcherOpen) {
                windowSwitcherScope.previous()
            }
        }
    }

    GlobalShortcut {
        name: "windowSwitcherActivate"
        description: "Activate selected window and close switcher"

        onReleased: {
            if (GlobalStates.windowSwitcherOpen) {
                windowSwitcherScope.activateSelected()
            }
        }
    }
}
