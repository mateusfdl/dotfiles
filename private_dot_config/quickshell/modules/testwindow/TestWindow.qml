import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.topbar

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: testWindow

            required property var modelData

            screen: modelData
            visible: true
            color: Qt.rgba(0, 0, 0, 0.5)

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            // Center container
            Rectangle {
                id: testContainer

                anchors.centerIn: parent
                width: 600
                height: 400
                color: Appearance.m3colors.m3windowBackground
                radius: 12
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.15)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    spacing: 20

                    Text {
                        text: "Widget Test Window"
                        color: "black"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Test MaterialSymbol
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15

                        MaterialSymbol {
                            text: "home"
                            iconSize: 32
                            fill: 0
                            color: "black"
                        }

                        MaterialSymbol {
                            text: "favorite"
                            iconSize: 32
                            fill: 1
                            color: "black"
                        }

                        MaterialSymbol {
                            text: "settings"
                            iconSize: 32
                            fill: 0
                            color: "black"
                        }

                    }

                    // Test DialogButton
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15

                        DialogButton {
                            buttonText: "Primary Button"
                            onClicked: {
                                console.log("Primary button clicked!");
                            }
                        }

                        DialogButton {
                            buttonText: "Secondary Button"
                            onClicked: {
                                console.log("Secondary button clicked!");
                            }
                        }

                    }

                    // Test RippleButton
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15

                        RippleButton {
                            width: 150
                            height: 50
                            onClicked: {
                                console.log("Ripple button 1 clicked!");
                            }

                            background: Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0.4, 0.6, 1, 0.8)
                                radius: 8
                            }

                            contentItem: Text {
                                anchors.centerIn: parent
                                text: "Ripple 1"
                                color: "white"
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                        }

                        RippleButton {
                            width: 150
                            height: 50
                            onClicked: {
                                console.log("Ripple button 2 clicked!");
                            }

                            background: Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(1, 0.4, 0.6, 0.8)
                                radius: 8
                            }

                            contentItem: Text {
                                anchors.centerIn: parent
                                text: "Ripple 2"
                                color: "white"
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                        }

                    }

                    // Close button
                    DialogButton {
                        buttonText: "Close Test Window"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                        onClicked: {
                            Qt.quit();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Workspaces {
                            anchors.centerIn: parent
                        }

                    }

                    Item {
                        Layout.fillHeight: true
                    }

                }

            }

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: {
                    Qt.quit();
                }
            }

        }

    }

}
