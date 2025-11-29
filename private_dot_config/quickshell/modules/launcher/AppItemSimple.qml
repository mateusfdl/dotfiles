pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

ItemDelegate {
    id: root

    required property var modelData

    implicitWidth: ListView.view.width
    implicitHeight: Config.options.launcher.sizes.itemHeight

    function launchAndClose() {
        AppSearch.launch(modelData);
        GlobalStates.launcherOpen = false;
    }

    onClicked: launchAndClose()
    Keys.onReturnPressed: launchAndClose()
    Keys.onEnterPressed: launchAndClose()

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Row {
        spacing: 18
        padding: 16
        leftPadding: 20
        rightPadding: 20

        IconImage {
            id: appIcon

            anchors.verticalCenter: parent.verticalCenter

            source: Quickshell.iconPath(root.modelData.icon, "image-missing")
            width: 56
            height: 56
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - appIcon.width - parent.spacing - parent.leftPadding - parent.rightPadding
            spacing: 6

            StyledText {
                text: root.modelData.name
                color: Appearance.m3colors.m3primaryText
                font.pixelSize: 19
                font.family: "-apple-system"
                font.weight: Font.Medium
                elide: Text.ElideRight
                width: parent.width
            }

            StyledText {
                text: root.modelData.comment ? root.modelData.comment : ""
                color: Appearance.m3colors.m3surfaceText
                font.pixelSize: 15
                font.family: "-apple-system"
                font.weight: Font.Normal
                elide: Text.ElideRight
                width: parent.width
                visible: text !== ""
            }
        }
    }
}
