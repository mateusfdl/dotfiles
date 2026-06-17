import QtQuick
import QtQuick.Effects
import "root:/modules/common"
import qs.modules.common

MultiEffect {
    property color sourceColor: "black"

    colorization: 1
    brightness: 1 - sourceColor.hslLightness

    Behavior on colorizationColor {
        ColorAnimation {
            duration: Style.animation.elementMove.duration
            easing.type: Style.animation.elementMove.type
            easing.bezierCurve: Style.animation.elementMove.bezierCurve
        }
    }
}
