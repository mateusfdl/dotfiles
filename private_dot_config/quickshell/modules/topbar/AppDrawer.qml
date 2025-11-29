import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    NerdIconImage {
        id: icon

        anchors.centerIn: parent
        icon: "󰣇"
        size: 48

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                GlobalStates.launcherOpen = !GlobalStates.launcherOpen
            }
        }

    }

}
