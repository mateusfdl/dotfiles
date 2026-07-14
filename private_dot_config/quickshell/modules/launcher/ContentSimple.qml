pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QsUtils

Item {
    id: root

    required property real maxHeight

    readonly property int outerPadding: 16
    readonly property int searchHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight) + 40
    readonly property int bottomPadding: 16
    readonly property int cardWidth: Config.options.launcher.grid.cardWidth

    readonly property int chipsBlock: (appGrid.hasSearchText || chips.present.length === 0) ? 0 : chips.implicitHeight + 16
    readonly property int chipsReserve: chips.present.length > 0 ? chips.implicitHeight + 16 : 0
    readonly property int maxGridHeight: Config.options.launcher.grid.maxRows * Config.options.launcher.grid.tileHeight
    readonly property int gridAreaHeight: Math.min(appGrid.implicitHeight, maxGridHeight, root.maxHeight - searchHeight - bottomPadding - chipsBlock - 24)
    readonly property int browseGridHeight: Math.min(maxGridHeight, root.maxHeight - searchHeight - bottomPadding - chipsReserve - 24)
    readonly property int maxCardHeight: searchHeight + 1 + chipsReserve + browseGridHeight + 12 + bottomPadding
    readonly property int contentAreaHeight: appGrid.count === 0 ? 220 : (chipsBlock + gridAreaHeight + 12)

    implicitWidth: mainContainer.width
    implicitHeight: mainContainer.height

    Item {
        id: mainContainer

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        width: root.cardWidth
        height: searchHeight + horizontalSep.height + contentArea.height + root.bottomPadding

        transformOrigin: Item.Top
        opacity: GlobalStates.launcherOpen ? 1 : 0
        scale: GlobalStates.launcherOpen ? 1 : 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutBack
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: Qt.rgba(0.08, 0.08, 0.09, 0.78)
            radius: Appearance.rounding.large
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: parent.radius + 1
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.15)
                border.width: 1
                z: -1
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.08)
                border.width: 2
                z: -2
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -7
                radius: parent.radius + 7
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.04)
                border.width: 3
                z: -3
            }
        }

        Item {
            id: searchArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.searchHeight
            z: 1

            MaterialSymbol {
                id: searchIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
                text: "search"
                color: Qt.rgba(1, 1, 1, 0.4)
                iconSize: 28
            }

            TextField {
                id: search
                anchors.left: searchIcon.right
                anchors.right: clearIcon.left
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                placeholderText: qsTr("Search applications...")
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.35)
                background: Item {}
                color: Appearance.m3colors.m3primaryText
                font.family: Style.font.family.uiFont
                font.pixelSize: 20

                Keys.onReturnPressed: event => {
                    if (appGrid.currentItem)
                        appGrid.currentItem.launchAndClose();
                    event.accepted = true;
                }
                Keys.onEnterPressed: event => {
                    if (appGrid.currentItem)
                        appGrid.currentItem.launchAndClose();
                    event.accepted = true;
                }

                Keys.onUpPressed: appGrid.moveCurrentIndexUp()
                Keys.onDownPressed: appGrid.moveCurrentIndexDown()
                Keys.onLeftPressed: appGrid.moveCurrentIndexLeft()
                Keys.onRightPressed: appGrid.moveCurrentIndexRight()
                Keys.onEscapePressed: {
                    GlobalStates.launcherOpen = false;
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
                anchors.rightMargin: 20

                width: search.text ? 24 : 0
                visible: search.text

                text: "close"
                color: Qt.rgba(1, 1, 1, 0.4)
                iconSize: 24

                MouseArea {
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
            id: horizontalSep
            anchors.top: searchArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 1
            color: Qt.rgba(1, 1, 1, 0.06)
            z: 1
        }

        Item {
            id: contentArea
            anchors.top: horizontalSep.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.contentAreaHeight
            z: 1
            clip: true

            Item {
                anchors.fill: parent
                visible: appGrid.count === 0

                Row {
                    anchors.centerIn: parent
                    spacing: 20

                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "manage_search"
                        color: Appearance.m3colors.m3surfaceText
                        iconSize: 48
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        StyledText {
                            text: qsTr("No results")
                            color: Appearance.m3colors.m3primaryText
                            font.family: Style.font.family.uiFont
                            font.pixelSize: Style.font.pixelSize.textLarge
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: qsTr("Try searching for something else")
                            color: Appearance.m3colors.m3surfaceText
                            font.family: Style.font.family.uiFont
                            font.pixelSize: Style.font.pixelSize.textBase
                            font.weight: Font.Normal
                        }
                    }
                }
            }

            Column {
                anchors.fill: parent
                anchors.leftMargin: root.outerPadding
                anchors.rightMargin: root.outerPadding
                anchors.topMargin: 12
                spacing: 16
                visible: appGrid.count > 0

                CategoryChips {
                    id: chips
                    width: parent.width
                    visible: !appGrid.hasSearchText && present.length > 0
                }

                AppGrid {
                    id: appGrid
                    width: parent.width
                    height: root.gridAreaHeight
                    search: search
                    category: chips.selected
                }
            }
        }
    }
}
