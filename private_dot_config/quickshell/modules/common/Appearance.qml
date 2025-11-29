import QtQuick
import Quickshell
import qs.modules.common.functions
pragma Singleton
pragma ComponentBehavior: Bound


Singleton {
    id: root
    property QtObject animation
    property QtObject animationCurves
    property QtObject rounding
    property QtObject font
    property QtObject sizes

    property real transparency: 0.5
    property real contentTransparency: 0.1
    property real workpaceTransparency: 0.8
    property string background_image: Directories.config + "/rofi/.current_wallpaper"

    // Theme loading
    property bool themeLoaded: false
    property var themeData: null
    property string currentThemeMode: "dark" // Default to dark mode

    // Helper to get current theme colors based on mode
    readonly property var currentThemeColors: {
        if (!themeData || !themeData.dark || !themeData.light) {
            return null
        }
        const colors = currentThemeMode === "dark" ? themeData.dark : themeData.light
        console.log("[Appearance] Theme colors updated:", currentThemeMode)
        return colors
    }

    Component.onCompleted: {
        loadTheme()
    }

    function loadTheme() {
        try {
            const themeJson = Qt.include(Directories.config + "/quickshell/config/theme.json")
            if (themeJson.status === Qt.include.OK) {
                console.error("[Appearance] Cannot use Qt.include for JSON, loading via file read")
            }
        } catch (e) {
            console.error("[Appearance] Error in loadTheme:", e)
        }

        // For now, manually parse the theme
        const darkColors = {
            "windowBackground": "#1a1b26",
            "primaryText": "#c0caf5",
            "layerBackground1": "#24283b",
            "layerBackground2": "#1f2335",
            "layerBackground3": "#2e3248",
            "surfaceText": "#c0caf5",
            "secondaryText": "#565f89",
            "borderPrimary": "#3b4261",
            "shadowColor": "#000000",
            "accentPrimary": "#7aa2f7",
            "accentSecondary": "#bb9af7",
            "selectionBackground": "#33467c",
            "accentPrimaryText": "#1a1b26",
            "selectionText": "#c0caf5",
            "borderSecondary": "#292e42"
        }

        const lightColors = {
            "windowBackground": "#f4f8f5",
            "primaryText": "#2e3d32",
            "layerBackground1": "#e6f0ea",
            "layerBackground2": "#dce9e2",
            "layerBackground3": "#c9dbcf",
            "surfaceText": "#33493d",
            "secondaryText": "#6b7f73",
            "borderPrimary": "#b0c7b8",
            "borderSecondary": "#d0e0d5",
            "shadowColor": "#00000020",
            "accentPrimary": "#3b8c59",
            "accentSecondary": "#62a87c",
            "selectionBackground": "#b2d6be",
            "accentPrimaryText": "#ffffff",
            "selectionText": "#1e2a21"
        }

        root.themeData = {
            "dark": darkColors,
            "light": lightColors
        }

        // Apply font config from Config.options
        if (typeof Config !== 'undefined' && Config.options.font) {
            if (Config.options.font.family && root.font.family) {
                root.font.family.uiFont = Config.options.font.family.uiFont || "Open Sans"
                root.font.family.iconFont = Config.options.font.family.iconFont || "FiraConde Nerd Font"
                root.font.family.codeFont = Config.options.font.family.codeFont || "JetBrains Mono NF"
            }
            if (Config.options.font.pixelSize && root.font.pixelSize) {
                root.font.pixelSize.textSmall = Config.options.font.pixelSize.textSmall || 13
                root.font.pixelSize.textBase = Config.options.font.pixelSize.textBase || 15
                root.font.pixelSize.textMedium = Config.options.font.pixelSize.textMedium || 16
                root.font.pixelSize.textLarge = Config.options.font.pixelSize.textLarge || 19
                root.font.pixelSize.iconLarge = Config.options.font.pixelSize.iconLarge || 22
            }
        }

        root.themeLoaded = true
        console.log("[Appearance] Theme loaded:", root.currentThemeMode)
    }

readonly property QtObject m3colors: QtObject {
    readonly property bool darkmode: root.currentThemeMode === "dark"
    readonly property bool transparent: true

    readonly property color m3windowBackground: (root.currentThemeColors && root.currentThemeColors.windowBackground) || "#1a1b26"
    readonly property color m3primaryText: (root.currentThemeColors && root.currentThemeColors.primaryText) || "#c0caf5"
    readonly property color m3layerBackground1: (root.currentThemeColors && root.currentThemeColors.layerBackground1) || "#24283b"
    readonly property color m3layerBackground2: (root.currentThemeColors && root.currentThemeColors.layerBackground2) || "#1f2335"
    readonly property color m3layerBackground3: (root.currentThemeColors && root.currentThemeColors.layerBackground3) || "#2f3549"
    readonly property color m3surfaceText: (root.currentThemeColors && root.currentThemeColors.surfaceText) || "#a9b1d6"
    readonly property color m3secondaryText: (root.currentThemeColors && root.currentThemeColors.secondaryText) || "#9aa5ce"
    readonly property color m3borderPrimary: (root.currentThemeColors && root.currentThemeColors.borderPrimary) || "#7aa2f7"
    readonly property color m3shadowColor: (root.currentThemeColors && root.currentThemeColors.shadowColor) || "#000000"
    readonly property color m3accentPrimary: (root.currentThemeColors && root.currentThemeColors.accentPrimary) || "#7dcfff"
    readonly property color m3accentSecondary: (root.currentThemeColors && root.currentThemeColors.accentSecondary) || "#bb9af7"
    readonly property color m3selectionBackground: (root.currentThemeColors && root.currentThemeColors.selectionBackground) || "#33467c"
    readonly property color m3accentPrimaryText: (root.currentThemeColors && root.currentThemeColors.accentPrimaryText) || "#1a1b26"
    readonly property color m3selectionText: (root.currentThemeColors && root.currentThemeColors.selectionText) || "#c0caf5"
    readonly property color m3borderSecondary: (root.currentThemeColors && root.currentThemeColors.borderSecondary) || "#414868"

    readonly property color colTooltip: darkmode ? "#1f2335" : "#e6f0ea"
    readonly property color colOnTooltip: darkmode ? "#c0caf5" : "#2e3d32"
}

    readonly property QtObject colors: QtObject {
        readonly property color colSubtext: m3colors.m3borderPrimary
        readonly property color colLayer0: ColorUtils.transparentize(m3colors.m3windowBackground, root.transparency)
        readonly property color colLayer1: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3layerBackground1, m3colors.m3windowBackground, 0.7), root.contentTransparency)
        readonly property color colOnLayer1: m3colors.m3secondaryText
        readonly property color colLayer2: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3layerBackground2, m3colors.m3layerBackground3, 0.55), root.contentTransparency)
        readonly property color colOnLayer2: m3colors.m3surfaceText
        readonly property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.92), root.contentTransparency)
        readonly property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.85), root.contentTransparency)
        readonly property color colLayer2Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.90), root.contentTransparency)
        readonly property color colLayer2Active: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.80), root.contentTransparency)
        readonly property color colPrimary: m3colors.m3accentPrimary
        readonly property color colPrimaryHover: ColorUtils.mix(colors.colPrimary, colLayer1Hover, 0.87)
        readonly property color colPrimaryActive: ColorUtils.mix(colors.colPrimary, colLayer1Active, 0.7)
        readonly property color colShadow: ColorUtils.transparentize(m3colors.m3shadowColor, 0.7)
    }

    rounding: QtObject {
        property int unsharpen: 2
        property int verysmall: 8
        property int small: 12
        property int normal: 17
        property int large: 23
        property int verylarge: 30
        property int veryverylarge: 60
        property int full: 9999
        property int screenRounding: veryverylarge
        property int windowRounding: veryverylarge
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string uiFont: "Open Sans"
            property string iconFont: "FiraConde Nerd Font"
            property string iconMaterial: "Material Symbols Rounded"
            property string codeFont: "JetBrains Mono NF"
        }
        property QtObject pixelSize: QtObject {
            property int textSmall: 13
            property int textBase: 15
            property int textMedium: 16
            property int textLarge: 19
            property int iconLarge: 22
        }
    }

    animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // Default, 350ms
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // Default, 500ms
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // Default, 650ms
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // Default, 200ms
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: 500
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }
        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }
        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }
        property QtObject elementMoveFast: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property int velocity: 850
            property Component colorAnimation: Component { ColorAnimation {
                duration: root.animation.elementMoveFast.duration
                easing.type: root.animation.elementMoveFast.type
                easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
            property Component numberAnimation: Component { NumberAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
        }

        property QtObject clickBounce: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveFastSpatial
            property int velocity: 850
            property Component numberAnimation: Component { NumberAnimation {
                    duration: root.animation.clickBounce.duration
                    easing.type: root.animation.clickBounce.type
                    easing.bezierCurve: root.animation.clickBounce.bezierCurve
            }}
        }
        property QtObject scroll: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.standardDecel
        }
        property QtObject menuDecel: QtObject {
            property int duration: 350
            property int type: Easing.OutExpo
        }
    }

    sizes: QtObject {
        property real barHeight: 40
        property real notificationPopupWidth: 410
        property real searchWidthCollapsed: 260
        property real searchWidth: 450
        property real hyprlandGapsOut: 5
        property real elevationMargin: 10
        property real fabShadowRadius: 5
        property real fabHoveredShadowRadius: 7
    }

    // Material 3 style color aliases for launcher compatibility
    readonly property QtObject color: QtObject {
        property color surfaceContainer: colors.colLayer2
        property color onSurface: colors.colOnLayer2
        property color onSurfaceVariant: colors.colOnLayer1
        property color surface: colors.colLayer0
        property color primary: colors.colPrimary
        property color onPrimary: m3colors.m3accentPrimaryText
    }
}
