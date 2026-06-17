pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var themeData: null
    readonly property var theme: themeData || {}

    function loadThemeFromText(text) {
        try {
            root.themeData = JSON.parse(text);
        } catch (e) {
            console.error("[Style] Failed to parse theme JSON:", e);
        }
    }

    FileView {
        id: themeFileView
        path: Directories.config + "/quickshell/config/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.loadThemeFromText(themeFileView.text());
        }
        onLoadFailed: error => {
            console.error("[Style] Failed to load theme.json:", error);
        }
    }

    function getCurve(name) {
        const curves = theme.animation?.curves;
        if (curves && curves[name]) {
            return curves[name];
        }
        const defaults = {
            "expressiveDefaultSpatial": [0.38, 1.21, 0.22, 1.00, 1, 1],
            "expressiveEffects": [0.34, 0.80, 0.34, 1.00, 1, 1],
            "emphasizedAccel": [0.3, 0, 0.8, 0.15, 1, 1],
            "emphasizedDecel": [0.05, 0.7, 0.1, 1, 1, 1],
            "standardDecel": [0, 0, 0, 1, 1, 1]
        };
        return defaults[name] || [0.2, 0, 0, 1, 1, 1];
    }

    readonly property QtObject animationCurves: QtObject {
        readonly property list<real> expressiveDefaultSpatial: getCurve("expressiveDefaultSpatial")
        readonly property list<real> expressiveEffects: getCurve("expressiveEffects")
        readonly property list<real> standardDecel: getCurve("standardDecel")
    }

    readonly property QtObject animation: QtObject {
        property QtObject elementMove: QtObject {
            readonly property int duration: theme.animation?.elementMove?.duration ?? 500
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.elementMove?.curve || "expressiveDefaultSpatial"
            readonly property list<real> bezierCurve: getCurve(curveName)
            property Component numberAnimation: Component {
                NumberAnimation {
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
        }
        property QtObject elementMoveExit: QtObject {
            readonly property int duration: theme.animation?.elementMoveExit?.duration ?? 200
            readonly property int type: Easing.BezierSpline
            readonly property var curveName: theme.animation?.elementMoveExit?.curve || "emphasizedAccel"
            readonly property list<real> bezierCurve: getCurve(curveName)
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
            readonly property int textLarge: Config.options.font?.pixelSize?.textLarge ?? 19
        }
    }
}
