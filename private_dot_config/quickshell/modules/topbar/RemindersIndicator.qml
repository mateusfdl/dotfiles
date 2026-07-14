pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QsUtils
import "." as Topbar
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    implicitWidth: contentRow.implicitWidth + 12
    implicitHeight: contentRow.implicitHeight

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: 5

        MaterialSymbol {
            text: "notifications_active"
            iconSize: 20
            fill: Reminders.activeReminders.length > 0 ? 1 : 0
            color: Config.options.bar.iconColor || Appearance.m3colors.m3primaryText
        }

        Text {
            text: Reminders.reminders.length.toString()
            color: Config.options.bar.iconColor || Appearance.m3colors.m3primaryText
            font.pixelSize: 12
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
            visible: Reminders.reminders.length > 0
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
            const pos = mapToItem(null, 0, 0);
            const popupX = pos.x + root.width - 360;
            Topbar.RemindersPopup.togglePopup(popupX, 2);
        }
    }
}
