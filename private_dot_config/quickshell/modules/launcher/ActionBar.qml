pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitHeight: 44
    activeFocusOnTab: false
    focus: false

    // Top separator
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 1

        // Left side: context label
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "apps"
                color: Appearance.m3colors.m3secondaryText
                iconSize: 16
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Applications")
                color: Appearance.m3colors.m3secondaryText
                font.family: Appearance.font.family.uiFont
                font.pixelSize: Appearance.font.pixelSize.textSmall
                font.weight: Font.Normal
            }
        }

        Item { Layout.fillWidth: true }

        // Right side: shortcut badges
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 12

            // Open action
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Open")
                    color: Appearance.m3colors.m3secondaryText
                    font.family: Appearance.font.family.uiFont
                    font.pixelSize: Appearance.font.pixelSize.textSmall
                    font.weight: Font.Normal
                }

                ShortcutBadge {
                    text: "↵"
                }
            }
        }
    }

    // Inline shortcut badge component
    component ShortcutBadge: Rectangle {
        id: badge

        required property string text

        width: Math.max(badgeText.implicitWidth + 10, 24)
        height: 22
        radius: 5
        color: Qt.rgba(1, 1, 1, 0.06)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        StyledText {
            id: badgeText
            anchors.centerIn: parent
            text: badge.text
            color: Appearance.m3colors.m3secondaryText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }
}
