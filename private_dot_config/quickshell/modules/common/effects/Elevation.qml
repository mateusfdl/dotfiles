import QtQuick
import QtQuick.Effects
import "root:/modules/common"

RectangularShadow {
    property int level
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Appearance.colors.colShadow
    blur: (dp * 5) ** 0.7
    spread: -dp * 0.3 + (dp * 0.1) ** 2
    offset.y: dp / 2

    Behavior on dp {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
