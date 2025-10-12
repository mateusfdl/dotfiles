import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common.widgets

Item {
    id: root

    implicitWidth: icon.implicitWidth + 12
    implicitHeight: icon.implicitHeight

    MaterialSymbol {
        id: icon

        anchors.centerIn: parent
        text: "search"
        iconSize: 22
        fill: 0
        color: Qt.rgba(1, 1, 1, 0.85)

        Behavior on color {
            ColorAnimation {
                duration: 200
            }

        }

    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
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
        hoverEnabled: false
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["sh", "-c", "rofi -show drun || wofi --show drun"]);
        }
    }

}
