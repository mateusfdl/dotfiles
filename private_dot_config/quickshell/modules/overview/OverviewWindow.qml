import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QsUtils
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Rectangle { // Window
    id: root
    property var windowData
    property var monitorData
    property var scale
    property var availableWorkspaceWidth
    property var availableWorkspaceHeight
    property bool restrictToWorkspace: true
    property real initX: Math.max((windowData?.at[0] - monitorData?.reserved[0] - monitorData?.x) * root.scale, 0) + xOffset
    property real initY: Math.max((windowData?.at[1] - monitorData?.reserved[1] - monitorData?.y) * root.scale, 0) + yOffset
    property real xOffset: 0
    property real yOffset: 0

    property var targetWindowWidth: windowData?.size[0] * scale
    property var targetWindowHeight: windowData?.size[1] * scale
    property bool hovered: false
    property bool pressed: false

    property var iconToWindowRatio: 0.35
    property var xwaylandIndicatorToIconRatio: 0.35
    property var iconToWindowRatioCompact: 0.6
    property var iconPath: Quickshell.iconPath(AppSearch.guessIcon(windowData?.class), "image-missing")
    property bool compactMode: Appearance.font.pixelSize.textSmall * 4 > targetWindowHeight || Appearance.font.pixelSize.textSmall * 4 > targetWindowWidth

    property bool indicateXWayland: (Config.options.overview.showXwaylandIndicator && windowData?.xwayland) ?? false

    // Find the matching Toplevel for window preview using ToplevelManager
    property var toplevel: {
        if (!windowData) return null;
        const windowClass = windowData.class?.toLowerCase() ?? "";
        const windowTitle = windowData.title ?? "";

        // First try exact match by appId and title
        for (let i = 0; i < ToplevelManager.toplevels.values.length; i++) {
            const tl = ToplevelManager.toplevels.values[i];
            if (tl.appId?.toLowerCase() === windowClass && tl.title === windowTitle) {
                return tl;
            }
        }
        // Fallback: match by appId only
        for (let i = 0; i < ToplevelManager.toplevels.values.length; i++) {
            const tl = ToplevelManager.toplevels.values[i];
            if (tl.appId?.toLowerCase() === windowClass) {
                return tl;
            }
        }
        return null;
    }

    x: initX
    y: initY
    width: Math.min(windowData?.size[0] * root.scale, (restrictToWorkspace ? windowData?.size[0] : availableWorkspaceWidth - x + xOffset))
    height: Math.min(windowData?.size[1] * root.scale, (restrictToWorkspace ? windowData?.size[1] : availableWorkspaceHeight - y + yOffset))

    radius: 8
    color: pressed ? Appearance.colors.colLayer2Active : hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
    border.color: hovered ? Appearance.m3colors.m3accentPrimary : Colors.transparentize(Appearance.m3colors.m3borderPrimary, 0.5)
    border.pixelAligned: false
    border.width: hovered ? 2 : 1
    clip: true

    // Scale up slightly on hover
    scale: hovered ? 1.02 : 1.0
    transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    Behavior on border.width {
        NumberAnimation { duration: 100 }
    }
    Behavior on x {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Window preview using ScreencopyView
    ScreencopyView {
        id: windowPreview
        anchors.fill: parent
        anchors.margins: 1
        captureSource: root.toplevel
        visible: root.toplevel !== null
    }

    // Hover overlay
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.pressed ? Appearance.colors.colLayer2Active : root.hovered ? Appearance.colors.colLayer2Hover : "transparent"
        opacity: windowPreview.visible ? (root.hovered || root.pressed ? 0.25 : 0) : 1

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    // Fallback icon/title when no preview
    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4
        visible: !windowPreview.visible

        IconImage {
            id: windowIcon
            Layout.alignment: Qt.AlignHCenter
            source: root.iconPath
            implicitSize: Math.min(targetWindowWidth, targetWindowHeight) * (root.compactMode ? root.iconToWindowRatioCompact : root.iconToWindowRatio)

            Behavior on implicitSize {
                NumberAnimation { duration: 150 }
            }
        }

        StyledText {
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            visible: !compactMode
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 10
            font.weight: Font.Medium
            elide: Text.ElideRight
            text: windowData?.title ?? ""
            color: Appearance.colors.colOnLayer2
        }
    }
}
