import "root:/modules/common"
import QtQuick

StyledText {
    id: root
    property real iconSize: Appearance?.font.pixelSize.textSmall ?? 16
    property real fill: 0
    property real truncatedFill: Math.round(fill * 100) / 100 // Reduce memory consumption spikes from constant font remapping
    renderType: fill !== 0 ? Text.CurveRendering : Text.NativeRendering
    font {
        hintingPreference: Font.PreferFullHinting
        family: Appearance?.font.family.iconMaterial ?? "Material Symbols Rounded"
        pixelSize: iconSize
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * fill
        variableAxes: { 
            "FILL": truncatedFill,
            // "wght": font.weight,
            // "GRAD": 0,
            "opsz": iconSize,
        }
    }

    // Note: fill animation removed due to memory leak
}
