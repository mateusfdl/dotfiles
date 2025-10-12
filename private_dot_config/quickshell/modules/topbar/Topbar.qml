import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData

            screen: modelData
            implicitHeight: 50
            color: Qt.rgba(0, 0, 0, 0.15)

            anchors {
                top: true
                left: true
                right: true
            }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 15
                anchors.bottomMargin: 15
                spacing: 0

                // Left section
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: leftContent.width

                    RowLayout {
                        id: leftContent

                        anchors.verticalCenter: parent.verticalCenter
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
                    Layout.fillHeight: true
                    Layout.preferredWidth: rightContent.width

                    RowLayout {
                        id: rightContent

                        anchors.verticalCenter: parent.verticalCenter
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

                        Topbar.VolumeIndicator {
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
