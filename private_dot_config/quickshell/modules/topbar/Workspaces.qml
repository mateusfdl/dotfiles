import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common.widgets
import qs.modules.common

Item {
    id: root

    implicitWidth: workspacesRow.implicitWidth
    implicitHeight: workspacesRow.implicitHeight

    property int workspaceCount: HyprlandData.workspaces.length

    RowLayout {
        id: workspacesRow
        anchors.centerIn: parent
        spacing: Config.options.bar.workspaces.spacing

        Repeater {
            model: root.workspaceCount

            Rectangle {
                required property int index

                width: Config.options.bar.workspaces.size
                height: Config.options.bar.workspaces.size
                color: "transparent"
                radius: Appearance.rounding.small

                property int workspaceId: {
                  return index + 1
                }
                property bool isActive: {
                    var activeWs = Hyprland.focusedMonitor?.activeWorkspace?.id
                    return activeWs === workspaceId
                }

                NerdIconImage {
                    anchors.centerIn: parent
                    icon: {
                        if (parent.isActive) return ""  
                        return ""  
                    }
                    size: Config.options.bar.workspaces.iconSize
                    color: Appearance.m3colors.m3primaryText

                    Behavior on size {
                        NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                    }

                    Behavior on color {
                        ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Hyprland.dispatch("workspace " + parent.workspaceId)
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
            }
        }
    }
}
