import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.modules.common.widgets

Row {
    id: root

    property bool invertSide: false

    spacing: 14

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem

            required property var modelData

            implicitWidth: 24
            implicitHeight: 24

            Image {
                id: trayIcon

                anchors.centerIn: parent
                width: 20
                height: 20
                source: modelData.icon || ""
                cache: false
                smooth: true
                mipmap: true

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
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
                anchors.margins: -4
                hoverEnabled: false
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton)
                        modelData.activate();
                    else if (mouse.button === Qt.RightButton)
                        modelData.contextMenu();
                    else if (mouse.button === Qt.MiddleButton)
                        modelData.secondaryActivate();
                }
                onWheel: (wheel) => {
                    modelData.scroll(wheel.angleDelta.y, "vertical");
                }
            }

            StyledToolTip {
                visible: mouseArea.containsMouse
                text: modelData.tooltipTitle || modelData.title || ""
                delay: 500
            }

        }

    }

}
