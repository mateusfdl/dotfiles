pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import QsUtils

Scope {
    id: overlayScope

    readonly property bool shouldShow: ScreenRecorder.isRecording && ScreenRecorder.hasRegion && ScreenRecorder.regionWidth > 0 && ScreenRecorder.regionHeight > 0
    readonly property real dimOpacity: 0.6

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlayWindow

            required property var modelData

            readonly property int holeLeft: Math.max(0, Math.min(ScreenRecorder.regionX - modelData.x, width))
            readonly property int holeTop: Math.max(0, Math.min(ScreenRecorder.regionY - modelData.y, height))
            readonly property int holeRight: Math.max(holeLeft, Math.min(ScreenRecorder.regionX + ScreenRecorder.regionWidth - modelData.x, width))
            readonly property int holeBottom: Math.max(holeTop, Math.min(ScreenRecorder.regionY + ScreenRecorder.regionHeight - modelData.y, height))

            screen: modelData
            visible: overlayScope.shouldShow
            color: "transparent"

            WlrLayershell.namespace: "quickshell:recording-overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            mask: Region {}

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Rectangle {
                color: "#000000"
                opacity: overlayScope.dimOpacity
                x: 0
                y: 0
                width: parent.width
                height: overlayWindow.holeTop
            }

            Rectangle {
                color: "#000000"
                opacity: overlayScope.dimOpacity
                x: 0
                y: overlayWindow.holeBottom
                width: parent.width
                height: parent.height - overlayWindow.holeBottom
            }

            Rectangle {
                color: "#000000"
                opacity: overlayScope.dimOpacity
                x: 0
                y: overlayWindow.holeTop
                width: overlayWindow.holeLeft
                height: overlayWindow.holeBottom - overlayWindow.holeTop
            }

            Rectangle {
                color: "#000000"
                opacity: overlayScope.dimOpacity
                x: overlayWindow.holeRight
                y: overlayWindow.holeTop
                width: parent.width - overlayWindow.holeRight
                height: overlayWindow.holeBottom - overlayWindow.holeTop
            }
        }
    }
}
