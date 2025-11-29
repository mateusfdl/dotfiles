import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.modules.common.widgets
import qs.modules.common

Row {
    id: root

    property bool invertSide: false

    spacing: Config.options.bar.tray.spacing

    Repeater {
        model: SystemTray.items

        Topbar.SysTrayItem {
            required property var modelData

            item: modelData
        }
    }
}
