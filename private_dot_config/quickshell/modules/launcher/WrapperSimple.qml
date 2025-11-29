pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root

    required property ShellScreen screen

    readonly property real maxHeight: screen.height * 0.8
    property int contentHeight: 0

    visible: height > 0
    implicitHeight: GlobalStates.launcherOpen ? contentHeight : 0
    implicitWidth: content.implicitWidth

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: GlobalStates.launcherOpen
        visible: GlobalStates.launcherOpen

        sourceComponent: ContentSimple {
            maxHeight: root.maxHeight
            onImplicitHeightChanged: root.contentHeight = implicitHeight
        }
    }
}
