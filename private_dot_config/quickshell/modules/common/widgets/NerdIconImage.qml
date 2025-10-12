import qs.modules.common
import QtQuick

StyledText {
    id: root

    property string icon: ""
    property real size: Appearance?.font.pixelSize.textBase ?? 16
    property bool active: true

    text: icon
    color: active ? Appearance.m3colors.m3primaryText : Qt.rgba(Appearance.m3colors.m3primaryText.r, Appearance.m3colors.m3primaryText.g, Appearance.m3colors.m3primaryText.b, 0.4)
    font.pixelSize: size
    font.family: Appearance?.font.family.iconNerdFont ?? "FiraConde Nerd Font"
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation {
            duration: Appearance?.animation.elementMoveFast.duration ?? 200
            easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
            easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }
}
