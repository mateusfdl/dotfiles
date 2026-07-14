pragma Singleton
pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QsUtils
import "." as Topbar
import qs.modules.common
import qs.modules.common.effects
import qs.modules.common.widgets
import qs.services

Scope {
    id: remindersPopupScope

    property bool popupVisible: false
    property real popupX: 0
    property real popupY: 0

    function showPopup(x, y) {
        popupX = x;
        popupY = y;
        popupVisible = true;
        Reminders.refresh();
        Tasks.fetchTodos();
    }

    function hidePopup() {
        popupVisible = false;
    }

    function togglePopup(x, y) {
        if (popupVisible) {
            hidePopup();
        } else {
            Topbar.PopupManager.closeAllExcept("reminders");
            showPopup(x, y);
        }
    }

    Variants {
        model: Quickshell.screens

        FocusedMonitorPanel {
            id: popup

            requestVisible: remindersPopupScope.popupVisible

            WlrLayershell.namespace: "quickshell:reminders"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: popup.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            HyprlandWindow.visibleMask: Region {
                item: popup.isActive ? popupBackground : null
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: popup.isActive
                onClicked: remindersPopupScope.hidePopup()
            }

            Rectangle {
                id: popupBackground

                x: remindersPopupScope.popupX
                y: remindersPopupScope.popupY
                width: 360
                height: Math.max(contentColumn.implicitHeight + 36, 210)
                radius: 16
                color: Appearance.colors.colLayer0
                border.color: Appearance.m3colors.m3borderSecondary
                border.width: 1
                z: 10

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => {
                        mouse.accepted = true;
                    }
                    z: -1
                }

                ColumnLayout {
                    id: contentColumn

                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialSymbol {
                            text: "notifications_active"
                            iconSize: 28
                            fill: 1
                            color: Appearance.m3colors.m3accentPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: "Reminders"
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                color: Appearance.m3colors.m3primaryText
                            }

                            StyledText {
                                text: Reminders.reminders.length + " pending"
                                font.pixelSize: 11
                                color: Appearance.m3colors.m3secondaryText
                            }
                        }

                        RippleButton {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            buttonRadius: 15
                            onClicked: {
                                Reminders.refresh();
                                Tasks.fetchTodos();
                            }

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "refresh"
                                iconSize: 17
                                color: Appearance.m3colors.m3secondaryText
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(Math.min(remindersList.contentHeight + 8, 260), 96)
                        radius: 10
                        color: Appearance.colors.colLayer2
                        border.color: Appearance.m3colors.m3borderSecondary
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

                            ListView {
                                id: remindersList

                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(contentHeight, 252)
                                model: Reminders.reminders
                                spacing: 2

                                delegate: Rectangle {
                                    id: reminderDelegate

                                    required property var modelData

                                    width: remindersList.width
                                    height: reminderRow.implicitHeight + 12
                                    radius: 8
                                    color: reminderMouseArea.containsMouse ? Style.withAlpha(Appearance.m3colors.m3primaryText, 0.06) : "transparent"

                                    RowLayout {
                                        id: reminderRow

                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 8

                                        StyledSwitch {
                                            Layout.preferredWidth: 34
                                            Layout.preferredHeight: 20
                                            scale: 0.65
                                            checked: reminderDelegate.modelData.isActive
                                            onClicked: Reminders.toggle(reminderDelegate.modelData.uuid)
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: reminderDelegate.modelData.description || ""
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                color: reminderDelegate.modelData.isActive ? Appearance.m3colors.m3primaryText : Appearance.m3colors.m3secondaryText
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }

                                            Row {
                                                spacing: 4
                                                visible: reminderDelegate.modelData.tags && reminderDelegate.modelData.tags.length > 0

                                                Repeater {
                                                    model: reminderDelegate.modelData.tags || []

                                                    Rectangle {
                                                        required property var modelData

                                                        width: tagLabel.implicitWidth + 8
                                                        height: tagLabel.implicitHeight + 4
                                                        radius: 3
                                                        color: Style.withAlpha(Appearance.m3colors.m3primaryText, 0.06)

                                                        StyledText {
                                                            id: tagLabel

                                                            anchors.centerIn: parent
                                                            text: "#" + parent.modelData
                                                            font.pixelSize: 9
                                                            color: Appearance.m3colors.m3secondaryText
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: reminderMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignCenter
                                spacing: 10
                                visible: remindersList.count === 0

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No pending TODOs"
                                    font.pixelSize: 12
                                    color: Appearance.m3colors.m3secondaryText
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialSymbol {
                            text: "rotate_right"
                            iconSize: 18
                            color: Appearance.m3colors.m3secondaryText
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: "Rotate delay"
                            font.pixelSize: 12
                            color: Appearance.m3colors.m3surfaceText
                        }

                        StyledSpinBox {
                            from: 1
                            to: 10000
                            stepSize: 1
                            value: Config.options.reminders.rotateDelay / 1000
                            onValueModified: Config.options.reminders.rotateDelay = value * 1000
                        }

                        StyledText {
                            text: "sec"
                            font.pixelSize: 11
                            color: Appearance.m3colors.m3secondaryText
                        }
                    }
                }
            }

            Elevation {
                anchors.fill: popupBackground
                radius: popupBackground.radius
                level: popup.isActive ? 4 : 0
            }
        }
    }
}
