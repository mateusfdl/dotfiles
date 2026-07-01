import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import QsUtils

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            readonly property bool isLive: Livestream.active && Livestream.monitor === modelData.name

            screen: modelData
            visible: panel.isLive && !GlobalStates.screenLocked
            implicitHeight: Appearance.sizes.barHeight
            color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"

            WlrLayershell.namespace: "quickshell:livetopbar"
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

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Topbar.MusicIsland {
                        anchors.centerIn: parent
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        spacing: 10

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
