import qs.modules.common
import QtQuick
import QsUtils

StyledText {
    id: root

    property string icon: ""
    property real size: Style.font.pixelSize.textBase
    property bool active: true

    text: icon
    color: active ? Appearance.m3colors.m3primaryText : Qt.rgba(Appearance.m3colors.m3primaryText.r, Appearance.m3colors.m3primaryText.g, Appearance.m3colors.m3primaryText.b, 0.4)
    font.pixelSize: size
    font.family: Style.font.family.iconFont
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation {
            duration: Style.animation.elementMoveFast.duration
            easing.type: Style.animation.elementMoveFast.type
            easing.bezierCurve: Style.animation.elementMoveFast.bezierCurve
        }
    }
}
