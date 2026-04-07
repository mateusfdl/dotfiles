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

    property var selectedApp: null

    model: AppSearch.quickshellApps

    spacing: 2
    orientation: Qt.Vertical
    implicitHeight: Math.min(maxHeight, (Config.options.launcher.sizes.itemHeight + spacing) * count - (count > 0 ? spacing : 0))

    clip: true
    currentIndex: 0
    interactive: contentHeight > height
    focus: true
    keyNavigationWraps: false

    onCurrentItemChanged: {
        if (currentItem && currentItem.modelData)
            selectedApp = currentItem.modelData;
    }

    Component.onCompleted: {
        if (count > 0 && currentItem && currentItem.modelData)
            selectedApp = currentItem.modelData;
    }

    Keys.onReturnPressed: {
        if (currentItem && typeof currentItem.launchAndClose === "function")
            currentItem.launchAndClose();
    }
    Keys.onEnterPressed: {
        if (currentItem && typeof currentItem.launchAndClose === "function")
            currentItem.launchAndClose();
    }

    highlightFollowsCurrentItem: false
    highlight: Rectangle {
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.08)

        y: root.currentItem ? root.currentItem.y : 0
        x: 4
        implicitWidth: root.width - 8
        implicitHeight: root.currentItem ? root.currentItem.implicitHeight : 0

        Behavior on y {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    delegate: AppItemSimple {}
}
