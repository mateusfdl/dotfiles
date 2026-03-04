import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: icon.implicitWidth + 12
    implicitHeight: icon.implicitHeight

    MaterialSymbol {
        id: icon
        anchors.centerIn: parent
        text: "auto_awesome"
        iconSize: 20
        fill: GlobalStates.aiChatOpen ? 1 : 0
        color: GlobalStates.aiChatOpen ? Appearance.colors.colPrimary : Qt.rgba(Appearance.m3colors.m3primaryText.r, Appearance.m3colors.m3primaryText.g, Appearance.m3colors.m3primaryText.b, 0.7)

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        color: mouseArea.containsMouse ? Qt.rgba(Appearance.m3colors.m3primaryText.r, Appearance.m3colors.m3primaryText.g, Appearance.m3colors.m3primaryText.b, 0.1) : "transparent"
        radius: 4
        z: -1

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            GlobalStates.aiChatOpen = !GlobalStates.aiChatOpen
        }
    }
}
