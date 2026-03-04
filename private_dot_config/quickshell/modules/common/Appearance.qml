import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.functions

pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property var themeData: null
    property bool themeLoaded: false
    property string background_image: Directories.config + "/rofi/.current_wallpaper"

    property string currentThemeMode: "dark"

    Component.onCompleted: {
        currentThemeMode = Config.options.ui.theme
    }

    readonly property var currentThemeColors: themeData?.[currentThemeMode]

    function loadThemeFromText(text) {
        try {
            root.themeData = JSON.parse(text)
        } catch (e) {
            console.error("[Appearance] Failed to parse theme JSON:", e)
        }
    }

    FileView {
        id: themeFileView
        path: Directories.config + "/quickshell/config/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.themeLoaded = true
            root.loadThemeFromText(themeFileView.text())
        }
        onLoadFailed: error => {
            console.error("[Appearance] Failed to load theme.json:", error)
        }
    }

    readonly property var theme: themeData || {}

    // Helper property that explicitly depends on both themeData and currentThemeMode
    // This ensures QML tracks both dependencies for proper binding updates
    readonly property var _colors: {
        const mode = root.currentThemeMode  // explicit dependency
        const data = root.themeData         // explicit dependency
        return data?.[mode] ?? {}
    }

    readonly property QtObject m3colors: QtObject {
        readonly property bool darkmode: root.currentThemeMode === "dark"

        readonly property color m3windowBackground: root._colors?.windowBackground ?? "#1a1b26"
        readonly property color m3primaryText: root._colors?.primaryText ?? "#c0caf5"
        readonly property color m3layerBackground1: root._colors?.layerBackground1 ?? "#24283b"
        readonly property color m3layerBackground2: root._colors?.layerBackground2 ?? "#1f2335"
        readonly property color m3layerBackground3: root._colors?.layerBackground3 ?? "#2f3549"
        readonly property color m3surfaceText: root._colors?.surfaceText ?? "#a9b1d6"
        readonly property color m3secondaryText: root._colors?.secondaryText ?? "#9aa5ce"
        readonly property color m3borderPrimary: root._colors?.borderPrimary ?? "#7aa2f7"
        readonly property color m3shadowColor: root._colors?.shadowColor ?? "#000000"
        readonly property color m3accentPrimary: root._colors?.accentPrimary ?? "#7dcfff"
        readonly property color m3accentSecondary: root._colors?.accentSecondary ?? "#bb9af7"
        readonly property color m3selectionBackground: root._colors?.selectionBackground ?? "#33467c"
        readonly property color m3accentPrimaryText: root._colors?.accentPrimaryText ?? "#1a1b26"
        readonly property color m3selectionText: root._colors?.selectionText ?? "#c0caf5"
        readonly property color m3borderSecondary: root._colors?.borderSecondary ?? "#414868"

        readonly property color m3outline: ColorUtils.mix(m3borderPrimary, m3windowBackground, 0.5)
        readonly property color m3outlineVariant: ColorUtils.mix(m3borderSecondary, m3windowBackground, 0.6)
        readonly property color m3surface: m3windowBackground
        readonly property color m3onSurface: m3primaryText
        readonly property color m3onPrimary: m3accentPrimaryText
        readonly property color m3onSecondaryContainer: ColorUtils.mix(m3accentPrimary, m3windowBackground, 0.3)
        readonly property color m3primary: m3accentPrimary
        readonly property color m3surfaceContainerLow: ColorUtils.mix(m3layerBackground1, m3windowBackground, 0.6)
        readonly property color m3secondaryContainer: ColorUtils.transparentize(ColorUtils.mix(m3layerBackground2, m3accentSecondary, 0.7), 0.4)

        readonly property color colTooltip: darkmode ? "#1f2335" : "#F4F0D9"
        readonly property color colOnTooltip: darkmode ? "#c0caf5" : "#5C6A72"
    }

    readonly property QtObject colors: QtObject {
        readonly property color colSubtext: m3colors.m3borderPrimary
        readonly property color colBackground: m3colors.m3windowBackground
        readonly property real transparency: theme.transparency?.background || 0.5
        readonly property real contentTransparency: theme.transparency?.content || 0.1
        readonly property real workspaceTransparency: theme.transparency?.workspace || 0.8

        readonly property color colLayer0: ColorUtils.transparentize(m3colors.m3windowBackground, transparency)
        readonly property color colOnLayer0: m3colors.m3primaryText
        readonly property color colLayer1: ColorUtils.mix(m3colors.m3layerBackground1, m3colors.m3windowBackground, 1)
        readonly property color colOnLayer1: m3colors.m3secondaryText
        readonly property color colLayer2: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3layerBackground2, m3colors.m3layerBackground3, 0.55), contentTransparency)
        readonly property color colOnLayer2: m3colors.m3surfaceText
        readonly property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.92), contentTransparency)
        readonly property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, 0.85), contentTransparency)
        readonly property color colLayer2Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.90), contentTransparency)
        readonly property color colLayer2Active: ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, 0.80), contentTransparency)
        readonly property color colPrimary: m3colors.m3accentPrimary
        readonly property color colPrimaryHover: ColorUtils.mix(colors.colPrimary, colLayer1Hover, 0.87)
        readonly property color colPrimaryActive: ColorUtils.mix(colors.colPrimary, colLayer1Active, 0.7)
        readonly property color colShadow: ColorUtils.transparentize(m3colors.m3shadowColor, 0.7)

        readonly property color colSecondaryContainer: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3layerBackground2, m3colors.m3accentPrimary, 0.85), 0.5)
        readonly property color colSurfaceContainerHighest: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3layerBackground3, m3colors.m3windowBackground, 0.5), 0.3)
        readonly property color colPrimaryContainer: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3accentPrimary, m3colors.m3windowBackground, 0.7), 0.4)
        readonly property color colPrimaryContainerHover: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3accentPrimary, m3colors.m3windowBackground, 0.6), 0.3)
        readonly property color colPrimaryContainerActive: ColorUtils.transparentize(ColorUtils.mix(m3colors.m3accentPrimary, m3colors.m3windowBackground, 0.5), 0.2)
        readonly property color colOnPrimaryContainer: m3colors.m3accentPrimaryText
        readonly property color colOnSecondaryContainer: m3colors.m3primaryText
    }

    readonly property QtObject rounding: QtObject {
        readonly property int unsharpen: theme.rounding?.unsharpen ?? 2
        readonly property int unsharpenmore: theme.rounding?.unsharpenmore ?? 0
        readonly property int verysmall: theme.rounding?.verysmall ?? 8
        readonly property int small: theme.rounding?.small ?? 12
        readonly property int normal: theme.rounding?.normal ?? 17
        readonly property int medium: theme.rounding?.medium ?? 20
        readonly property int large: theme.rounding?.large ?? 23
        readonly property int verylarge: theme.rounding?.verylarge ?? 30
        readonly property int veryverylarge: theme.rounding?.veryverylarge ?? 60
        readonly property int full: theme.rounding?.full ?? 9999
        readonly property int screenRounding: getRoundingValue(theme.rounding?.screen) ?? veryverylarge
        readonly property int windowRounding: getRoundingValue(theme.rounding?.window) ?? veryverylarge

        function getRoundingValue(key) {
            if (!key) return null
            if (typeof key === 'number') return key
            if (theme.rounding && theme.rounding[key] !== undefined) {
                return theme.rounding[key]
            }
            return null
        }
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string uiFont: Config.options.font?.family?.uiFont || "Open Sans"
            readonly property string iconFont: Config.options.font?.family?.iconFont || "FiraConde Nerd Font"
            readonly property string iconMaterial: "Material Symbols Rounded"
            readonly property string codeFont: Config.options.font?.family?.codeFont || "JetBrains Mono NF"
            readonly property string monospace: codeFont
        }
        readonly property QtObject pixelSize: QtObject {
            readonly property int textSmall: Config.options.font?.pixelSize?.textSmall ?? 13
            readonly property int textBase: Config.options.font?.pixelSize?.textBase ?? 15
            readonly property int textMedium: Config.options.font?.pixelSize?.textMedium ?? 16
            readonly property int textLarge: Config.options.font?.pixelSize?.textLarge ?? 19
            readonly property int iconLarge: Config.options.font?.pixelSize?.iconLarge ?? 22
        }
    }

    function getCurve(name) {
        const curves = theme.animation?.curves
        if (curves && curves[name]) {
            return curves[name]
        }
        const defaults = {
            "expressiveFastSpatial": [0.42, 1.67, 0.21, 0.90, 1, 1],
            "expressiveDefaultSpatial": [0.38, 1.21, 0.22, 1.00, 1, 1],
            "expressiveSlowSpatial": [0.39, 1.29, 0.35, 0.98, 1, 1],
            "expressiveEffects": [0.34, 0.80, 0.34, 1.00, 1, 1],
            "emphasized": [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1],
            "emphasizedAccel": [0.3, 0, 0.8, 0.15, 1, 1],
            "emphasizedDecel": [0.05, 0.7, 0.1, 1, 1, 1],
            "standard": [0.2, 0, 0, 1, 1, 1],
            "standardAccel": [0.3, 0, 1, 1, 1, 1],
            "standardDecel": [0, 0, 0, 1, 1, 1]
        }
        return defaults[name] || [0.2, 0, 0, 1, 1, 1]
    }

    readonly property QtObject animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: getCurve("expressiveFastSpatial")
        readonly property list<real> expressiveDefaultSpatial: getCurve("expressiveDefaultSpatial")
        readonly property list<real> expressiveSlowSpatial: getCurve("expressiveSlowSpatial")
        readonly property list<real> expressiveEffects: getCurve("expressiveEffects")
        readonly property list<real> emphasized: getCurve("emphasized")
        readonly property list<real> emphasizedAccel: getCurve("emphasizedAccel")
        readonly property list<real> emphasizedDecel: getCurve("emphasizedDecel")
        readonly property list<real> standard: getCurve("standard")
        readonly property list<real> standardAccel: getCurve("standardAccel")
        readonly property list<real> standardDecel: getCurve("standardDecel")
    }

    readonly property QtObject animation: QtObject {
        property QtObject elementMove: QtObject {
            readonly property int duration: theme.animation?.elementMove?.duration ?? 500
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.elementMove?.curve || "expressiveDefaultSpatial"
            readonly property list<real> bezierCurve: getCurve(curveName)
            readonly property int velocity: theme.animation?.elementMove?.velocity ?? 650
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
            readonly property int duration: theme.animation?.elementMoveEnter?.duration ?? 400
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.elementMoveEnter?.curve || "emphasizedDecel"
            readonly property list<real> bezierCurve: getCurve(curveName)
            readonly property int velocity: theme.animation?.elementMoveEnter?.velocity ?? 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }
        property QtObject elementMoveExit: QtObject {
            readonly property int duration: theme.animation?.elementMoveExit?.duration ?? 200
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.elementMoveExit?.curve || "emphasizedAccel"
            readonly property list<real> bezierCurve: getCurve(curveName)
            readonly property int velocity: theme.animation?.elementMoveExit?.velocity ?? 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }
        property QtObject elementMoveFast: QtObject {
            readonly property int duration: theme.animation?.elementMoveFast?.duration ?? 200
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.elementMoveFast?.curve || "expressiveEffects"
            readonly property list<real> bezierCurve: getCurve(curveName)
            readonly property int velocity: theme.animation?.elementMoveFast?.velocity ?? 850
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }
        property QtObject clickBounce: QtObject {
            readonly property int duration: theme.animation?.clickBounce?.duration ?? 200
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.clickBounce?.curve || "expressiveFastSpatial"
            readonly property list<real> bezierCurve: getCurve(curveName)
            readonly property int velocity: theme.animation?.clickBounce?.velocity ?? 850
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.clickBounce.duration
                    easing.type: root.animation.clickBounce.type
                    easing.bezierCurve: root.animation.clickBounce.bezierCurve
                }
            }
        }
        property QtObject scroll: QtObject {
            readonly property int duration: theme.animation?.scroll?.duration ?? 400
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.scroll?.curve || "standardDecel"
            readonly property list<real> bezierCurve: getCurve(curveName)
            readonly property int velocity: 0
        }
        property QtObject menuDecel: QtObject {
            readonly property int duration: theme.animation?.menuDecel?.duration ?? 350
            readonly property string easing: theme.animation?.menuDecel?.easing ?? "OutExpo"
        }
    }

    readonly property QtObject sizes: QtObject {
        readonly property real barHeight: theme.sizes?.barHeight ?? 40
        readonly property real notificationPopupWidth: theme.sizes?.notificationPopupWidth ?? 410
        readonly property real searchWidthCollapsed: theme.sizes?.searchWidthCollapsed ?? 260
        readonly property real searchWidth: theme.sizes?.searchWidth ?? 450
        readonly property real hyprlandGapsOut: theme.sizes?.hyprlandGapsOut ?? 5
        readonly property real elevationMargin: theme.sizes?.elevationMargin ?? 10
        readonly property real fabShadowRadius: theme.sizes?.fabShadowRadius ?? 5
        readonly property real fabHoveredShadowRadius: theme.sizes?.fabHoveredShadowRadius ?? 7
    }

    readonly property QtObject color: QtObject {
        readonly property color surfaceContainer: colors.colLayer2
        readonly property color onSurface: colors.colOnLayer2
        readonly property color onSurfaceVariant: colors.colOnLayer1
        readonly property color surface: colors.colLayer0
        readonly property color primary: colors.colPrimary
        readonly property color onPrimary: m3colors.m3accentPrimaryText
    }
}
