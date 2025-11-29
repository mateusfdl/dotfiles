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

    required property var content
    required property real maxHeight
    required property TextField search
    required property int padding
    required property int rounding

    readonly property Item currentList: appList.item

    anchors.horizontalCenter: parent.horizontalCenter

    clip: true

    implicitWidth: parent.width
    implicitHeight: appList.item ? appList.item.implicitHeight : 0

    Loader {
        id: appList

        active: root.search.text.length > 0
        visible: root.search.text.length > 0
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 0

        sourceComponent: AppListSimple {
            search: root.search
        }
    }

    Row {
        id: empty

        visible: root.currentList?.count === 0

        spacing: 20
        padding: 32

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialSymbol {
            text: "manage_search"
            color: Appearance.m3colors.m3surfaceText
            iconSize: 56

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            StyledText {
                text: qsTr("No results")
                color: Appearance.m3colors.m3primaryText
                font.pixelSize: 20
                font.family: "-apple-system"
                font.weight: Font.Medium
            }

            StyledText {
                text: qsTr("Try searching for something else")
                color: Appearance.m3colors.m3surfaceText
                font.pixelSize: 16
                font.family: "-apple-system"
                font.weight: Font.Normal
            }
        }
    }
}
