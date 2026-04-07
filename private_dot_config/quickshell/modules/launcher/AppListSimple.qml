pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell

ListView {
    id: root

    required property TextField search

    readonly property int maxShown: Config.options.launcher.maxShown ?? 7
    property var selectedApp: null

    model: AppSearch.search(search.text).slice(0, maxShown)

    spacing: 2
    orientation: Qt.Vertical
    implicitHeight: Math.max(0, (Config.options.launcher.sizes.itemHeight + spacing) * Math.min(maxShown, count) - (count > 0 ? spacing : 0))

    clip: true
    currentIndex: 0
    interactive: false
    focus: true
    keyNavigationWraps: false

    onCurrentItemChanged: {
        if (currentItem && currentItem.modelData)
            selectedApp = currentItem.modelData;
    }

    onCountChanged: {
        if (count > 0 && currentIndex >= 0 && currentItem && currentItem.modelData)
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
