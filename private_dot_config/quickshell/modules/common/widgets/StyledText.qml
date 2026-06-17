import "root:/modules/common"
import QtQuick
import QsUtils
import qs.modules.common

Text {
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    font {
        hintingPreference: Font.PreferFullHinting
        family: Style.font.family.uiFont
        pixelSize: Style.font.pixelSize.textBase
    }
    color: Appearance.m3colors.m3primaryText
}
