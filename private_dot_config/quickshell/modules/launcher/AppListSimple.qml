pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell

ListView {
    id: root

    required property TextField search

    model: AppSearch.search(search.text).slice(0, 6)

    spacing: 6
    orientation: Qt.Vertical
    implicitHeight: Math.max(0, (Config.options.launcher.sizes.itemHeight + spacing) * Math.min(6, count) - (count > 0 ? spacing : 0))

    clip: true
    currentIndex: 0
    interactive: false

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

    delegate: AppItemSimple {
        visible: true
    }

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
