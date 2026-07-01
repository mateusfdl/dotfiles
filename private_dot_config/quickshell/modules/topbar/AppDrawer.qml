import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets
import QsUtils

Item {
    id: root

    implicitWidth: icon.size
    implicitHeight: icon.size

    NerdIconImage {
        id: icon

        anchors.centerIn: parent
        icon: "󱄅"
        size: 28
        color: Config.options.bar.iconColor || Appearance.m3colors.m3primaryText

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                GlobalStates.launcherOpen = !GlobalStates.launcherOpen;
            }
        }
    }
}
