import QtQuick
import QtQuick.Effects
import "root:/modules/common"

MultiEffect {
    property color sourceColor: "black"

    colorization: 1
    brightness: 1 - sourceColor.hslLightness

    Behavior on colorizationColor {
        ColorAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
