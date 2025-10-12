import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: workspacesRow.implicitWidth
    implicitHeight: workspacesRow.implicitHeight

    property int workspaceCount: HyprlandData.workspaces.length

    RowLayout {
        id: workspacesRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.workspaceCount

            Rectangle {
                required property int index

                width: 24
                height: 24
                color: {
                    if (isActive) return Qt.rgba(1, 1, 1, 0.15)
                    if (mouseArea.containsMouse) return Qt.rgba(1, 1, 1, 0.15)
                    return "transparent"
                }
                radius: 4

                property int workspaceId: {
                  console.log("INDEX:", index)
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
                    size:  16 
                    color: Qt.rgba(1, 1, 1, 0.9)

                    Behavior on size {
                        NumberAnimation { duration: 200 }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 200 }
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
                    ColorAnimation { duration: 200 }
                }
            }
        }
    }
}
