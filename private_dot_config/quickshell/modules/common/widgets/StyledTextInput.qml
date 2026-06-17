import qs.modules.common
import QtQuick
import QtQuick.Controls
import QsUtils

/**
 * Does not include visual layout, but includes the easily neglected colors.
 */
TextInput {
    color: Appearance.colors.colOnLayer1
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    font {
        family: Style.font.family.uiFont
        pixelSize: Style.font.pixelSize.textSmall
        hintingPreference: Font.PreferFullHinting
    }
}
