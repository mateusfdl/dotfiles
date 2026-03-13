pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "root:/modules/common"

Rectangle {
    id: root

    property alias innerRadius: maskInner.radius
    property alias thickness: maskInner.anchors.margins
    property alias leftThickness: maskInner.anchors.leftMargin
    property alias topThickness: maskInner.anchors.topMargin
    property alias rightThickness: maskInner.anchors.rightMargin
    property alias bottomThickness: maskInner.anchors.bottomMargin

    anchors.fill: parent
    color: Appearance.m3colors.m3surfaceContainer

    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        maskSource: mask
        maskEnabled: true
        maskInverted: true
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            id: maskInner

            anchors.fill: parent
            anchors.margins: Appearance.rounding.verysmall
            radius: Appearance.rounding.small
        }
    }
}
