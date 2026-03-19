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
    property color indicatorColor: Config.options.bar.iconColor || Appearance.m3colors.m3primaryText

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
                    return index + 1;
                }
                property bool isActive: {
                    var activeWs = Hyprland.focusedMonitor?.activeWorkspace?.id;
                    return activeWs === workspaceId;
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.isActive ? Config.options.bar.workspaces.activeSize : Config.options.bar.workspaces.inactiveSize
                    height: width
                    radius: width / 2
                    color: parent.isActive ? root.indicatorColor : "transparent"
                    border.width: parent.isActive ? 0 : 1.5
                    border.color: root.indicatorColor

                    Behavior on width {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Hyprland.dispatch("workspace " + parent.workspaceId);
                    }
                }
            }
        }
    }
}
