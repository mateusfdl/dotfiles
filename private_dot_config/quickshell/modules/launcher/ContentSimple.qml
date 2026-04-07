pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    required property real maxHeight

    readonly property int outerPadding: 16
    readonly property int searchHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight) + 28
    readonly property int actionBarHeight: 44
    readonly property int contentAreaHeight: Math.min(root.maxHeight - searchHeight - actionBarHeight, 380)
    readonly property int leftPanelWidth: 320

    implicitWidth: mainContainer.width
    implicitHeight: mainContainer.height

    Item {
        id: mainContainer

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        width: 780
        height: searchHeight + horizontalSep.height + contentArea.height + actionBar.height

        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        // Card background — semi-transparent for compositor blur
        Rectangle {
            id: background
            anchors.fill: parent
            color: Qt.rgba(0.08, 0.08, 0.09, 0.78)
            radius: Appearance.rounding.large
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            // Subtle outer glow
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

        // ============================================================
        // 1. SEARCH BAR
        // ============================================================
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
                font.family: Appearance.font.family.uiFont
                font.pixelSize: 18

                // Enter launches selected app
                Keys.onReturnPressed: event => {
                    if (!list.currentList)
                        return;
                    const listView = list.currentList;
                    if (listView.count === 0)
                        return;
                    const currentItem = listView.currentItem;
                    if (currentItem) {
                        if (typeof currentItem.launchAndClose === "function")
                            currentItem.launchAndClose();
                        else if (currentItem.modelData)
                            currentItem.clicked();
                    }
                    event.accepted = true;
                }

                // Delegate Up/Down to list navigation
                Keys.onUpPressed: {
                    if (list.currentList)
                        list.currentList.decrementCurrentIndex();
                }
                Keys.onDownPressed: {
                    if (list.currentList)
                        list.currentList.incrementCurrentIndex();
                }
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
                    NumberAnimation { duration: 200 }
                }
            }
        }

        // ============================================================
        // 2. HORIZONTAL SEPARATOR
        // ============================================================
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

        // ============================================================
        // 3. CONTENT AREA (two-panel or empty state)
        // ============================================================
        Item {
            id: contentArea
            anchors.top: horizontalSep.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.contentAreaHeight
            z: 1
            clip: true

            // Empty state — spans full width when no results
            Item {
                id: emptyState
                anchors.fill: parent
                visible: list.currentList !== null && list.currentList.count === 0
                z: 2

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
                            font.family: Appearance.font.family.uiFont
                            font.pixelSize: Appearance.font.pixelSize.textLarge
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: qsTr("Try searching for something else")
                            color: Appearance.m3colors.m3surfaceText
                            font.family: Appearance.font.family.uiFont
                            font.pixelSize: Appearance.font.pixelSize.textBase
                            font.weight: Font.Normal
                        }
                    }
                }
            }

            // Two-panel layout
            Row {
                anchors.fill: parent
                visible: !emptyState.visible

                // Left panel: section header + app list
                Item {
                    id: leftPanel
                    width: root.leftPanelWidth
                    height: parent.height

                    Column {
                        anchors.fill: parent
                        anchors.topMargin: 12
                        spacing: 4

                        // Section header
                        StyledText {
                            text: list.hasSearchText ? qsTr("Applications") : qsTr("Suggestions")
                            color: Appearance.m3colors.m3secondaryText
                            font.family: Appearance.font.family.uiFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            leftPadding: 16
                            bottomPadding: 4
                        }

                        // App list
                        ContentListSimple {
                            id: list
                            width: parent.width
                            maxHeight: leftPanel.height - 40
                            search: search
                            padding: root.outerPadding
                        }
                    }
                }

                // Vertical separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: Qt.rgba(1, 1, 1, 0.06)
                }

                // Right panel: app preview
                AppPreview {
                    width: parent.width - root.leftPanelWidth - 1
                    height: parent.height
                    selectedApp: list.selectedApp
                }
            }
        }

        // ============================================================
        // 4. ACTION BAR
        // ============================================================
        ActionBar {
            id: actionBar
            anchors.top: contentArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            z: 1
        }
    }
}
