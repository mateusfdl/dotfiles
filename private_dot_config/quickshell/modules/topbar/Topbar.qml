import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.modules.common

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            visible: !GlobalStates.screenLocked
            implicitHeight: Appearance.sizes.barHeight
            color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"

            WlrLayershell.namespace: "quickshell:topbar"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                top: true
                left: true
                right: true
            }

            margins.top: Appearance.sizes.barTopMargin

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: Config.options.bar.margins
                anchors.bottomMargin: Config.options.bar.margins
                spacing: 0

                // Left section
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        id: leftContent

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: 8

                        Item {
                            implicitWidth: 12
                            implicitHeight: 1
                        }

                        Topbar.AppDrawer {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Topbar.ActiveWindow {
                            Layout.leftMargin: 12
                            Layout.alignment: Qt.AlignVCenter
                            Layout.maximumWidth: 400
                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Topbar.Workspaces {
                        anchors.centerIn: parent
                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        id: rightContent

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        spacing: 10

                        Item {
                            implicitWidth: 1
                            implicitHeight: 1
                        }

                        Topbar.SysTray {
                            visible: true
                            Layout.fillWidth: false
                            Layout.fillHeight: true
                            invertSide: false
                        }

                        Topbar.RecordingIndicator {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Topbar.VolumeIndicator {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Topbar.PomodoroIndicator {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Topbar.AiChatIndicator {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Topbar.ControlCenter {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Topbar.Clock {
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            implicitWidth: 20
                            implicitHeight: 1
                        }

                    }

                }

            }

        }

    }

}
