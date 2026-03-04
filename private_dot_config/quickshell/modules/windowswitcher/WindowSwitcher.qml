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

    readonly property int maxHistorySize: 20
    readonly property int focusGrabDelay: 100

    property int currentIndex: 0
    property var filteredWindows: []
    property var windowAddresses: []
    property string snapshotFocusedAddress: ""
    property string lastActivatedAddress: ""
    property var windowHistory: []

    Process {
        id: getActiveWindowProcess
        running: false
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            id: activeWindowCollector
            onStreamFinished: {
                try {
                    const activeWindow = JSON.parse(activeWindowCollector.text)
                    snapshotFocusedAddress = activeWindow.address || ""
                } catch (e) {
                    console.error("Failed to parse active window:", e)
                    snapshotFocusedAddress = ""
                } finally {
                    windowSwitcherScope.continueUpdateWindowList()
                }
            }
        }
    }

    function updateWindowList() {
        getActiveWindowProcess.running = true
    }

    function updateHistory(address) {
        if (!address || address === lastActivatedAddress) return

        windowHistory = windowHistory.filter(addr => addr !== address)
        windowHistory = [address].concat(windowHistory)

        if (windowHistory.length > maxHistorySize) {
            windowHistory = windowHistory.slice(0, maxHistorySize)
        }
    }

    function sortWindowsByHistory(windows) {
        return windows.sort((a, b) => {
            const indexA = windowHistory.indexOf(a.address)
            const indexB = windowHistory.indexOf(b.address)

            if (indexA !== -1 && indexB !== -1) return indexA - indexB
            if (indexA !== -1) return -1
            if (indexB !== -1) return 1
            return 0
        })
    }

    function continueUpdateWindowList() {
        updateHistory(snapshotFocusedAddress)

        const windows = HyprlandData.windowList.filter(win => !win.hidden && win.mapped)
        const sortedWindows = sortWindowsByHistory(windows)

        filteredWindows = sortedWindows
        windowAddresses = sortedWindows.map(w => w.address)
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

        const selectedAddress = windowAddresses[currentIndex]
        lastActivatedAddress = selectedAddress

        GlobalStates.windowSwitcherOpen = false
        Hyprland.dispatch(`focuswindow address:${selectedAddress}`)
        Hyprland.dispatch(`bringactivetotop`)
    }

    Variants {
        id: windowSwitcherVariants
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            readonly property bool monitorIsFocused: Hyprland.focusedMonitor?.id == monitor.id

            screen: modelData
            visible: GlobalStates.windowSwitcherOpen
            color: "transparent"

            WlrLayershell.namespace: "quickshell:windowswitcher"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region { item: GlobalStates.windowSwitcherOpen ? switcherLayout : null }
            HyprlandWindow.visibleMask: Region { item: GlobalStates.windowSwitcherOpen ? switcherLayout : null }

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

                readonly property bool canBeActive: root.monitorIsFocused

                onCleared: {
                    if (!active) GlobalStates.windowSwitcherOpen = false
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: focusGrabDelay
                repeat: false

                onTriggered: {
                    if (grab.canBeActive) {
                        grab.active = GlobalStates.windowSwitcherOpen
                    }
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

                    readonly property int containerPadding: 60
                    readonly property int containerHeight: 160

                    implicitWidth: listView.contentWidth + containerPadding
                    implicitHeight: containerHeight

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

                        readonly property int itemSpacing: 15
                        readonly property int listMargin: 30

                        anchors.fill: parent
                        anchors.margins: listMargin

                        orientation: ListView.Horizontal
                        spacing: itemSpacing
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

                            readonly property bool isSelected: index === windowSwitcherScope.currentIndex
                            readonly property string iconPath: Quickshell.iconPath(
                                AppSearch.guessIcon(modelData?.class),
                                "image-missing"
                            )

                            readonly property int itemSize: 100
                            readonly property int iconContainerSize: 80
                            readonly property int iconSize: 48
                            readonly property int borderWidth: 2
                            readonly property real selectedScale: 1.15

                            width: itemSize
                            height: itemSize
                            scale: isSelected ? selectedScale : 1.0

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: iconContainerSize
                                height: iconContainerSize
                                radius: Appearance.rounding.large

                                color: isSelected
                                    ? Appearance.m3colors.m3selectionBackground
                                    : Appearance.m3colors.m3layerBackground1

                                border.color: isSelected ? Appearance.m3colors.m3accentPrimary : "transparent"
                                border.width: isSelected ? borderWidth : 0

                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                Image {
                                    anchors.centerIn: parent
                                    source: windowItem.iconPath
                                    width: iconSize
                                    height: iconSize
                                    sourceSize: Qt.size(iconSize, iconSize)
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
        description: "Switch to next window"

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
        description: "Switch to previous window"

        onPressed: {
            if (GlobalStates.windowSwitcherOpen) {
                windowSwitcherScope.previous()
            }
        }
    }

    GlobalShortcut {
        name: "windowSwitcherActivate"
        description: "Activate selected window"

        onReleased: {
            if (GlobalStates.windowSwitcherOpen) {
                windowSwitcherScope.activateSelected()
            }
        }
    }
}
