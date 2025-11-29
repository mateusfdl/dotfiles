import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.common
import qs.services

Scope {
    id: notificationPopup


    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData

            visible: Notifications.popupList.length > 0
            screen: modelData
            WlrLayershell.namespace: "quickshell:notificationPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0

            anchors {
                top: true
                right: true
                bottom: true
            }

            mask: Region {
                item: listview.contentItem
            }

            color: "transparent"
            width: Appearance.sizes.notificationPopupWidth
            implicitWidth: Appearance.sizes.notificationPopupWidth

            ListView {
                id: listview
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                    rightMargin: 8
                    topMargin: 8
                }
                width: parent.width - 16
                spacing: 8
                clip: true

                model: ScriptModel {
                    values: Notifications.popupAppNameList
                }

                delegate: NotificationGroup {
                    required property int index
                    required property var modelData
                    width: listview.width
                    notificationGroup: Notifications.popupGroupsByAppName[modelData]
                }
            }
        }
    }
}
