pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property var selectedApp: null

    activeFocusOnTab: false
    focus: false

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: 24
        visible: root.selectedApp !== null

        opacity: root.selectedApp !== null ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Top section: icon + name
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 140

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    // Icon with circular background
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 88
                        height: 88
                        radius: 44
                        color: Qt.rgba(1, 1, 1, 0.06)

                        IconImage {
                            anchors.centerIn: parent
                            width: 64
                            height: 64
                            source: root.selectedApp ? Quickshell.iconPath(root.selectedApp.icon, "image-missing") : ""
                        }
                    }

                    // App name
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.selectedApp?.name ?? ""
                        color: Appearance.m3colors.m3primaryText
                        font.family: Appearance.font.family.uiFont
                        font.pixelSize: Appearance.font.pixelSize.textLarge
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        width: Math.min(implicitWidth, content.width - 16)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // Metadata section
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 16

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 0

                    // Section header
                    StyledText {
                        text: qsTr("Metadata")
                        color: Appearance.m3colors.m3secondaryText
                        font.family: Appearance.font.family.uiFont
                        font.pixelSize: Appearance.font.pixelSize.textSmall
                        font.weight: Font.DemiBold
                        bottomPadding: 12
                    }

                    // Name row
                    MetadataRow {
                        label: qsTr("Name")
                        value: root.selectedApp?.name ?? ""
                        width: parent.width
                    }

                    // Description row
                    MetadataRow {
                        label: qsTr("Description")
                        value: root.selectedApp?.comment ?? ""
                        width: parent.width
                        visible: value !== ""
                    }

                    // Executable row
                    MetadataRow {
                        label: qsTr("Executable")
                        value: root.selectedApp?.exec ?? ""
                        width: parent.width
                        visible: value !== ""
                    }
                }
            }
        }
    }

    // Empty state
    Item {
        anchors.fill: parent
        visible: root.selectedApp === null

        MaterialSymbol {
            anchors.centerIn: parent
            text: "apps"
            color: Appearance.m3colors.m3secondaryText
            iconSize: 48
            opacity: 0.4
        }
    }

    // Inline metadata row component
    component MetadataRow: Item {
        id: metaRow

        required property string label
        required property string value

        height: 32

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            StyledText {
                width: 100
                text: metaRow.label
                color: Appearance.m3colors.m3secondaryText
                font.family: Appearance.font.family.uiFont
                font.pixelSize: Appearance.font.pixelSize.textSmall
                font.weight: Font.Normal
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            StyledText {
                width: metaRow.width - 100
                text: metaRow.value
                color: Appearance.m3colors.m3primaryText
                font.family: Appearance.font.family.uiFont
                font.pixelSize: Appearance.font.pixelSize.textSmall
                font.weight: Font.Normal
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
