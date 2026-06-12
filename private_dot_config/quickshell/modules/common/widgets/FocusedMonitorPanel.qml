import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: root

    required property var modelData
    property bool requestVisible: false

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool isFocusedMonitor: Hyprland.focusedMonitor?.id === monitor?.id
    readonly property bool isActive: requestVisible && isFocusedMonitor

    screen: modelData
    visible: isActive
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
}
