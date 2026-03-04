import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions

Item {
    id: root

    enum State {
        Collapsed,
        Compact,
        Expanded,
        Large
    }

    property int currentState: DynamicIsland.State.Collapsed
    property real collapsedWidth: 120
    property real collapsedHeight: 36
    property real compactWidth: 200
    property real compactHeight: 40
    property real expandedWidth: 340
    property real expandedHeight: 84
    property real largeWidth: 380
    property real largeHeight: 180
    property real collapsedMargin: 10
    property real compactMargin: 10
    property real expandedMargin: 14
    property real largeMargin: 18
    property real collapsedRadius: -1
    property real compactRadius: -1
    property real expandedRadius: 32
    property real largeRadius: 36
    property int animationDuration: Appearance.animation.elementMove.duration
    property var animationCurve: Appearance.animationCurves.expressiveDefaultSpatial
    property color backgroundColor: Appearance.m3colors.m3windowBackground
    property color borderColor: Appearance.colors.colLayer1Active
    property real borderWidth: 1
    property real shadowRadius: 16
    property color shadowColor: Appearance.colors.colShadow
    property Item blurSource: null
    property real blurRadius: 64
    property real blurSaturation: 0.3
    property real blurBrightness: -0.15
    property real overlayOpacity: 0.5
    property alias collapsedContent: collapsedLoader.sourceComponent
    property alias compactContent: compactLoader.sourceComponent
    property alias expandedContent: expandedLoader.sourceComponent
    property alias largeContent: largeLoader.sourceComponent
    property bool interactive: true
    readonly property var _sizes: [{
        "w": collapsedWidth,
        "h": collapsedHeight,
        "m": collapsedMargin,
        "r": collapsedRadius
    }, {
        "w": compactWidth,
        "h": compactHeight,
        "m": compactMargin,
        "r": compactRadius
    }, {
        "w": expandedWidth,
        "h": expandedHeight,
        "m": expandedMargin,
        "r": expandedRadius
    }, {
        "w": largeWidth,
        "h": largeHeight,
        "m": largeMargin,
        "r": largeRadius
    }]
    readonly property var _current: _sizes[currentState] || _sizes[0]
    readonly property real targetWidth: _current.w
    readonly property real targetHeight: _current.h
    readonly property real targetMargin: _current.m
    readonly property real targetRadius: _current.r < 0 ? targetHeight / 2 : _current.r

    signal clicked()
    signal longPressed()
    signal stateChanged(int newState)

    function collapse() {
        currentState = DynamicIsland.State.Collapsed;
    }

    function expand(state = DynamicIsland.State.Expanded) {
        currentState = state;
    }

    function toggle() {
        currentState = currentState === DynamicIsland.State.Collapsed ? DynamicIsland.State.Expanded : DynamicIsland.State.Collapsed;
    }

    function cycleStates() {
        currentState = (currentState + 1) % 4;
    }

    implicitWidth: container.width + shadowRadius * 2
    implicitHeight: container.height + shadowRadius * 2
    onCurrentStateChanged: stateChanged(currentState)

    RectangularGlow {
        anchors.fill: container
        glowRadius: root.shadowRadius
        spread: 0.1
        color: root.shadowColor
        cornerRadius: container.radius + glowRadius
    }

    Item {
        id: container

        property real radius: root.targetRadius

        anchors.centerIn: parent
        width: root.targetWidth
        height: root.targetHeight

        Item {
            anchors.fill: parent
            layer.enabled: true

            Item {
                anchors.fill: parent
                visible: root.blurSource !== null

                ShaderEffectSource {
                    id: blurCapture

                    anchors.fill: parent
                    sourceItem: root.blurSource
                    sourceRect: Qt.rect(root.x + container.x - (root.implicitWidth - container.width) / 2, root.y + container.y - (root.implicitHeight - container.height) / 2, container.width, container.height)
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: blurCapture
                    blurEnabled: true
                    blurMax: root.blurRadius
                    blur: 1
                    saturation: root.blurSaturation
                    brightness: root.blurBrightness
                }

            }

            Rectangle {
                anchors.fill: parent
                radius: container.radius
                color: root.backgroundColor
                visible: root.blurSource === null
            }

            Rectangle {
                anchors.fill: parent
                radius: container.radius
                color: "#000000"
                opacity: root.overlayOpacity
                visible: root.blurSource !== null
            }

            ContentLoader {
                id: collapsedLoader

                targetState: DynamicIsland.State.Collapsed
            }

            ContentLoader {
                id: compactLoader

                targetState: DynamicIsland.State.Compact
            }

            ContentLoader {
                id: expandedLoader

                targetState: DynamicIsland.State.Expanded
            }

            ContentLoader {
                id: largeLoader

                targetState: DynamicIsland.State.Large
            }

            layer.effect: OpacityMask {

                maskSource: Rectangle {
                    width: container.width
                    height: container.height
                    radius: container.radius
                }

            }

        }

        Rectangle {
            anchors.fill: parent
            radius: container.radius
            color: "transparent"
            border.color: root.borderColor
            border.width: root.borderWidth
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
            onPressAndHold: root.longPressed()
        }

        Behavior on width {
            IslandAnimation {
            }

        }

        Behavior on height {
            IslandAnimation {
            }

        }

        Behavior on radius {
            IslandAnimation {
            }

        }

    }

    component IslandAnimation: NumberAnimation {
        duration: root.animationDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.animationCurve
    }

    component ContentLoader: Loader {
        id: loader

        required property int targetState

        anchors.fill: parent
        anchors.margins: root.targetMargin
        active: root.currentState === targetState
        opacity: active ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.animationDuration / 2
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.standardDecel
            }

        }

    }

}
