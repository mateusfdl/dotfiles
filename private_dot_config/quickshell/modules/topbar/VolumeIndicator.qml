import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules.common
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
        color: Config.options.bar.iconColor || Appearance.m3colors.m3primaryText

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
            var pos = mapToItem(null, 0, 0);
            var iconRightX = pos.x + root.width;
            var popupX = iconRightX - 240;
            var popupY = 2;
            Topbar.VolumePopup.togglePopup(popupX, popupY);
        }
    }

}
