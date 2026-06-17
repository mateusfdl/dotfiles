import "root:/modules/common"
import QtQuick
import qs.modules.common

StyledText {
    id: root
    property real iconSize: Style.font.pixelSize.textSmall
    property real fill: 0
    property real truncatedFill: Math.round(fill * 100) / 100 // Reduce memory consumption spikes from constant font remapping
    renderType: fill !== 0 ? Text.CurveRendering : Text.NativeRendering
    font {
        hintingPreference: Font.PreferFullHinting
        family: Style.font.family.iconMaterial
        pixelSize: iconSize
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * fill
        variableAxes: {
            "FILL": truncatedFill,
            // "wght": font.weight,
            // "GRAD": 0,
            "opsz": iconSize
        }
    }

    // Note: fill animation removed due to memory leak
}
