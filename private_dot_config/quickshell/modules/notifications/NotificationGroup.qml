import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
pragma ComponentBehavior: Bound

Item {
    id: root
    required property var notificationGroup

    implicitHeight: column.implicitHeight
    implicitWidth: 400

    Column {
        id: column
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: ScriptModel {
                values: root.notificationGroup?.notifications ?? []
            }

            delegate: NotificationItem {
                required property var modelData
                width: root.width
                notificationObject: modelData
            }
        }
    }
}
