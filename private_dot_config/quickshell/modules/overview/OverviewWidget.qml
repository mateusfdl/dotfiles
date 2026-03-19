import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QsUtils
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    required property var panelWindow
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property var toplevels: ToplevelManager.toplevels
    property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor.id)
    property var windows: HyprlandData.windowList
    property var windowByAddress: HyprlandData.windowByAddress
    property var windowAddresses: HyprlandData.addresses
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor.id)
    property var monitorWorkspaceIds: HyprlandData.workspaces.filter(ws => ws.monitorID === root.monitor.id).map(ws => ws.id)
    property real scale: Config.options.overview.scale
    property color activeBorderColor: Appearance.m3colors.m3accentSecondary

    property real workspaceImplicitWidth: Math.max(100, (monitorData?.transform % 2 === 1) ? ((monitor.height - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale) : ((monitor.width - monitorData?.reserved[0] - monitorData?.reserved[2]) * root.scale / monitor.scale))
    property real workspaceImplicitHeight: Math.max(60, (monitorData?.transform % 2 === 1) ? ((monitor.width - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale) : ((monitor.height - monitorData?.reserved[1] - monitorData?.reserved[3]) * root.scale / monitor.scale))

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: (Config.options.overview.workspaceNumberSize > 0) ? Config.options.overview.workspaceNumberSize : Math.min(workspaceImplicitHeight, workspaceImplicitWidth) * monitor.scale
    property int workspaceZ: 0
    property int windowZ: 1
    property int windowDraggingZ: 99999
    property real workspaceSpacing: 16

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    implicitWidth: overviewBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    property Component windowComponent: OverviewWindow {}
    property list<OverviewWindow> windowWidgets: []

    // Refresh wallpaper path from swww when overview becomes visible
    onVisibleChanged: {
        if (visible)
            Appearance.refreshWallpaper();
    }

    // Shared wallpaper image - loaded once and reused, only when visible
    Image {
        id: sharedWallpaper
        source: root.visible ? (Appearance.background_image ? "file://" + Appearance.background_image : "") : ""
        visible: false // Hidden as it's only used as a source
        cache: true
        asynchronous: true
        smooth: true
        opacity: Appearance.workpaceTransparency ?? 1.0
    }

    StyledRectangularShadow {
        target: overviewBackground
    }
    Rectangle { // Background
        id: overviewBackground
        property real padding: 20
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        border.color: Colors.transparentize(Appearance.m3colors.m3borderPrimary, 0.3)
        border.width: 1

        implicitWidth: workspaceColumnLayout.implicitWidth + padding * 2
        implicitHeight: workspaceColumnLayout.implicitHeight + padding * 2
        radius: 16
        color: Appearance.colors.colBackground

        RowLayout { // Workspaces - horizontal flow of open workspaces only
            id: workspaceColumnLayout

            z: root.workspaceZ
            anchors.centerIn: parent
            spacing: workspaceSpacing

            Repeater {
                // Workspace repeater - only open workspaces for this monitor
                model: monitorWorkspaceIds.slice().sort((a, b) => a - b)
                Rectangle { // Workspace
                    id: workspace
                    required property var modelData
                    property int workspaceValue: modelData
                    property string workspaceName: HyprlandData.workspaceById[workspaceValue]?.name ?? String(workspaceValue)
                    property color defaultWorkspaceColor: Appearance.colors.colLayer1
                    property color hoveredWorkspaceColor: Colors.mix(defaultWorkspaceColor, Appearance.colors.colLayer1Hover, 0.1)
                    property color hoveredBorderColor: Appearance.colors.colLayer2Hover
                    property bool hoveredWhileDragging: false
                    readonly property int padding: Config.options.overview.windowPadding
                    property int workspaceIndex: {
                        const sorted = monitorWorkspaceIds.slice().sort((a, b) => a - b);
                        return sorted.indexOf(workspaceValue);
                    }

                    Layout.preferredWidth: root.workspaceImplicitWidth
                    Layout.preferredHeight: root.workspaceImplicitHeight
                    Layout.minimumWidth: 100
                    Layout.minimumHeight: 60

                    width: root.workspaceImplicitWidth
                    height: root.workspaceImplicitHeight
                    color: "transparent"
                    radius: 12
                    clip: true

                    // Workspace background with wallpaper
                    Rectangle {
                        id: wallpaperContainer
                        anchors.fill: parent
                        radius: parent.radius
                        color: workspace.defaultWorkspaceColor
                        clip: true

                        ShaderEffectSource {
                            id: wallpaperSource
                            anchors.fill: parent
                            sourceItem: sharedWallpaper
                            visible: sharedWallpaper.status === Image.Ready
                            smooth: true

                            transform: Scale {
                                property real aspectRatio: sharedWallpaper.implicitWidth / Math.max(1, sharedWallpaper.implicitHeight)
                                property real containerRatio: wallpaperContainer.width / Math.max(1, wallpaperContainer.height)

                                xScale: aspectRatio > containerRatio ? wallpaperContainer.height * aspectRatio / wallpaperContainer.width : 1
                                yScale: aspectRatio > containerRatio ? 1 : wallpaperContainer.width / (wallpaperContainer.height * aspectRatio)

                                origin.x: wallpaperContainer.width / 2
                                origin.y: wallpaperContainer.height / 2
                            }
                        }

                        // Fallback color
                        Rectangle {
                            anchors.fill: parent
                            color: workspace.defaultWorkspaceColor
                            visible: sharedWallpaper.status !== Image.Ready
                        }

                        // Dim overlay
                        Rectangle {
                            anchors.fill: parent
                            color: hoveredWhileDragging ? Appearance.colors.colLayer1Hover : "black"
                            opacity: hoveredWhileDragging ? 0.4 : 0.2

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }

                    // Border
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: parent.radius
                        border.width: hoveredWhileDragging ? 2 : 1
                        border.color: hoveredWhileDragging ? Appearance.m3colors.m3accentPrimary : Colors.transparentize(Appearance.m3colors.m3borderPrimary, 0.5)
                        z: 10

                        Behavior on border.width {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }

                    // Workspace number badge
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: 8
                        anchors.leftMargin: 8
                        width: workspaceLabel.implicitWidth + 12
                        height: workspaceLabel.implicitHeight + 6
                        radius: 6
                        color: Colors.transparentize(Appearance.colors.colLayer0, 0.3)
                        z: 15

                        StyledText {
                            id: workspaceLabel
                            anchors.centerIn: parent
                            text: workspaceName
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }

                    MouseArea {
                        id: workspaceArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        z: 20
                        onClicked: {
                            if (root.draggingTargetWorkspace === -1) {
                                GlobalStates.overviewOpen = false;
                                Hyprland.dispatch(`workspace ${workspaceName}`);
                            }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        z: 20
                        onEntered: {
                            root.draggingTargetWorkspace = workspaceValue;
                            if (root.draggingFromWorkspace == root.draggingTargetWorkspace)
                                return;
                            hoveredWhileDragging = true;
                        }
                        onExited: {
                            hoveredWhileDragging = false;
                            if (root.draggingTargetWorkspace == workspaceValue)
                                root.draggingTargetWorkspace = -1;
                        }
                    }
                }
            }
        }

        Item { // Windows & focused workspace indicator
            id: windowSpace
            anchors.centerIn: parent
            implicitWidth: workspaceColumnLayout.implicitWidth
            implicitHeight: workspaceColumnLayout.implicitHeight

            Repeater {
                // Window repeater
                model: ScriptModel {
                    values: windowAddresses.filter(address => {
                        var win = windowByAddress[address];
                        // Only show windows in workspaces belonging to this monitor
                        return monitorWorkspaceIds.includes(win?.workspace?.id);
                    })
                }
                delegate: OverviewWindow {
                    id: window
                    windowData: windowByAddress[modelData]
                    monitorData: HyprlandData.monitors.find(m => m.id === windowData?.monitor)
                    scale: root.scale * (monitorData?.scale / root.monitor?.scale)
                    availableWorkspaceWidth: root.workspaceImplicitWidth
                    availableWorkspaceHeight: root.workspaceImplicitHeight

                    property bool atInitPosition: (initX == x && initY == y)
                    restrictToWorkspace: Drag.active || atInitPosition

                    // Calculate workspace index in sorted list for horizontal positioning
                    property var sortedWorkspaces: monitorWorkspaceIds.slice().sort((a, b) => a - b)
                    property int workspaceIndex: sortedWorkspaces.indexOf(windowData?.workspace?.id)
                    xOffset: (root.workspaceImplicitWidth + workspaceSpacing) * workspaceIndex
                    yOffset: 0

                    Timer {
                        id: updateWindowPosition
                        interval: Config.options.hacks.arbitraryRaceConditionDelay
                        repeat: false
                        running: false
                        onTriggered: {
                            window.x = Math.max((windowData?.at[0] - monitorData?.reserved[0] - monitorData?.x) * root.scale, 0) + xOffset;
                            window.y = Math.max((windowData?.at[1] - monitorData?.reserved[1] - monitorData?.y) * root.scale, 0) + yOffset;
                        }
                    }

                    z: atInitPosition ? root.windowZ : root.windowDraggingZ
                    Drag.hotSpot.x: targetWindowWidth / 2
                    Drag.hotSpot.y: targetWindowHeight / 2
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true
                        onExited: hovered = false
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        drag.target: parent
                        onPressed: {
                            root.draggingFromWorkspace = windowData?.workspace.id;
                            window.pressed = true;
                            window.Drag.active = true;
                            window.Drag.source = window;
                        }
                        onReleased: {
                            const targetWorkspace = root.draggingTargetWorkspace;
                            window.pressed = false;
                            window.Drag.active = false;
                            root.draggingFromWorkspace = -1;
                            if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) {
                                Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${window.windowData?.address}`);
                                updateWindowPosition.restart();
                            } else {
                                window.x = window.initX;
                                window.y = window.initY;
                            }
                        }
                        onClicked: event => {
                            if (!windowData)
                                return;

                            if (event.button === Qt.LeftButton) {
                                GlobalStates.overviewOpen = false;
                                Hyprland.dispatch(`focuswindow address:${windowData.address}`);
                                event.accepted = true;
                            } else if (event.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`closewindow address:${windowData.address}`);
                                event.accepted = true;
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: dragArea.containsMouse && !window.Drag.active
                            content: `${windowData.title}\n[${windowData.class}] ${windowData.xwayland ? "[XWayland] " : ""}\n`
                        }
                    }
                }
            }

            Rectangle { // Focused workspace indicator
                id: focusedWorkspaceIndicator
                property var sortedWorkspaces: monitorWorkspaceIds.slice().sort((a, b) => a - b)
                property int activeWorkspaceIndex: sortedWorkspaces.indexOf(monitor.activeWorkspace?.id ?? -1)
                x: (root.workspaceImplicitWidth + workspaceSpacing) * activeWorkspaceIndex
                y: 0
                z: root.windowZ + 5
                width: Math.max(100, root.workspaceImplicitWidth)
                height: Math.max(60, root.workspaceImplicitHeight)
                color: "transparent"
                radius: 12
                border.width: 3
                border.color: Appearance.m3colors.m3accentPrimary
                visible: width > 0 && height > 0 && activeWorkspaceIndex >= 0

                Behavior on x {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
