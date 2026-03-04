pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell

ListView {
    id: root

    required property real maxHeight
    required property int padding

    model: AppSearch.quickshellApps

    spacing: 6
    orientation: Qt.Vertical
    implicitHeight: Math.min(maxHeight, (Config.options.launcher.sizes.itemHeight + spacing) * count - (count > 0 ? spacing : 0))

    clip: true
    currentIndex: 0
    interactive: height < maxHeight
    focus: true
    keyNavigationWraps: false

    Keys.onReturnPressed: {
        if (currentItem && typeof currentItem.launchAndClose === "function") {
            currentItem.launchAndClose();
        }
    }
    Keys.onEnterPressed: {
        if (currentItem && typeof currentItem.launchAndClose === "function") {
            currentItem.launchAndClose();
        }
    }

    highlightFollowsCurrentItem: false
    highlight: Rectangle {
        radius: 14
        color: Appearance.m3colors.m3secondaryText

        y: root.currentItem ? root.currentItem.y : 0
        x: 8
        implicitWidth: root.width - 16
        implicitHeight: root.currentItem ? root.currentItem.implicitHeight : 0

        Behavior on y {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    delegate: AppItemSimple {}

    add: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "y"
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    displaced: Transition {
        NumberAnimation {
            property: "y"
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
}
