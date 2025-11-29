pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root

    required property real maxHeight

    readonly property int padding: 24
    readonly property int rounding: 20
    readonly property int searchHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight) + 32

    implicitWidth: mainContainer.width
    implicitHeight: mainContainer.height

    Item {
        id: mainContainer

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        width: 720
        height: searchHeight + (list.height > 0 ? separator.height + list.height + root.padding * 2 : 0)

        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: Appearance.colors.colLayer1
            radius: 28
            border.color: Appearance.m3colors.m3borderSecondary
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: parent.radius + 1
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.03)
                border.width: 1
                z: -1
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: parent.radius + 2
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.03)
                border.width: 1
                z: -2
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.03)
                border.width: 1
                z: -3
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: parent.radius + 4
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.04)
                border.width: 1
                z: -4
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                radius: parent.radius + 6
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.04)
                border.width: 2
                z: -5
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -9
                radius: parent.radius + 9
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.04)
                border.width: 3
                z: -6
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -13
                radius: parent.radius + 13
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.03)
                border.width: 4
                z: -7
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -18
                anchors.topMargin: -14
                radius: parent.radius + 18
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.02)
                border.width: 5
                z: -8
            }
        }

        Item {
            id: searchArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: searchHeight
            z: 1

            MaterialSymbol {
                id: searchIcon

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24

                text: "search"
                color: Appearance.m3colors.m3surfaceText
                iconSize: 32
            }

            TextField {
                id: search

                anchors.left: searchIcon.right
                anchors.right: clearIcon.left
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                placeholderText: qsTr("Search applications...")
                placeholderTextColor: Appearance.m3colors.m3surfaceText
                background: Item {}
                color: Appearance.m3colors.m3primaryText
                font.pixelSize: 22

                Keys.onReturnPressed: (event) => {
                    if (!list.currentList) return;

                    const listView = list.currentList;
                    if (listView.count === 0) return;

                    const currentItem = listView.currentItem;
                    if (currentItem && currentItem.modelData) {
                        currentItem.clicked();
                    }
                    event.accepted = true;
                }

                Keys.onUpPressed: {
                    if (list.currentList) list.currentList.decrementCurrentIndex()
                }
                Keys.onDownPressed: {
                    if (list.currentList) list.currentList.incrementCurrentIndex()
                }
                Keys.onEscapePressed: {
                    GlobalStates.launcherOpen = false
                }

                Component.onCompleted: forceActiveFocus()

                Connections {
                    target: GlobalStates

                    function onLauncherOpenChanged(): void {
                        if (!GlobalStates.launcherOpen)
                            search.text = "";
                        else
                            search.forceActiveFocus();
                    }
                }
            }

            MaterialSymbol {
                id: clearIcon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24

                width: search.text ? 28 : 0
                visible: search.text

                text: "close"
                color: Appearance.m3colors.m3surfaceText
                iconSize: 28

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: search.text ? Qt.PointingHandCursor : undefined

                    onClicked: search.text = ""
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }

        Rectangle {
            id: separator
            anchors.top: searchArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: list.height > 0 ? 1 : 0
            color: Appearance.m3colors.m3borderSecondary
            z: 1
        }

        ContentListSimple {
            id: list

            anchors.top: separator.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: list.height > 0 ? root.padding : 0
            anchors.bottomMargin: list.height > 0 ? root.padding : 0
            z: 1

            content: root
            maxHeight: root.maxHeight - searchHeight - root.padding * 2
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }
}
