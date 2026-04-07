pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

ItemDelegate {
    id: root

    required property var modelData

    implicitWidth: ListView.view.width
    implicitHeight: Config.options.launcher.sizes.itemHeight

    focus: true
    activeFocusOnTab: true

    function launchAndClose() {
        if (typeof modelData.launch === "function") {
            modelData.launch();
        } else {
            AppSearch.launch(modelData);
        }
        GlobalStates.launcherOpen = false;
    }

    onClicked: launchAndClose()
    Keys.onReturnPressed: launchAndClose()
    Keys.onEnterPressed: launchAndClose()

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Row {
        spacing: 10
        leftPadding: 12
        rightPadding: 12

        IconImage {
            id: appIcon
            anchors.verticalCenter: parent.verticalCenter
            source: Quickshell.iconPath(root.modelData.icon, "image-missing")
            width: 22
            height: 22
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - appIcon.width - parent.spacing - parent.leftPadding - parent.rightPadding
            text: root.modelData.name
            color: Appearance.m3colors.m3primaryText
            font.family: Appearance.font.family.uiFont
            font.pixelSize: Appearance.font.pixelSize.textBase
            font.weight: Font.Normal
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
