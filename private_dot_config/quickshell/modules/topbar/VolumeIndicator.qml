import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    implicitWidth: icon.implicitWidth + 12
    implicitHeight: icon.implicitHeight

    MaterialSymbol {
        id: icon

        anchors.centerIn: parent
        text: {
            if (Audio.sink?.audio?.muted ?? false)
                return "volume_off";

            const volume = (Audio.sink?.audio?.volume ?? 0) * 100;
            if (volume >= 70)
                return "volume_up";

            if (volume >= 30)
                return "volume_down";

            if (volume > 0)
                return "volume_mute";

            return "volume_off";
        }
        iconSize: 22
        fill: 0
        color: (Audio.sink?.audio?.muted ?? false) ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.85)

        Behavior on color {
            ColorAnimation {
                duration: 200
            }

        }

    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        color: "transparent"
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
            var pos = mapToItem(null, 0, 0);
            var iconRightX = pos.x + root.width;
            var popupX = iconRightX - 280;
            var popupY = 2;
            Topbar.VolumePopup.togglePopup(popupX, popupY);
        }
    }

}
