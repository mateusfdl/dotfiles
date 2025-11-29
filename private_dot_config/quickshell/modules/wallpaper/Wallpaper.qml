pragma ComponentBehavior: Bound

import qs
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: wallpaperScope

    PanelWindow {
        id: wallpaperWindow

        visible: GlobalStates.wallpaperSelectorOpen

        WlrLayershell.namespace: "quickshell:wallpaper"
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"

        mask: Region {
            item: GlobalStates.wallpaperSelectorOpen ? previewContent : null
        }
        HyprlandWindow.visibleMask: Region {
            item: GlobalStates.wallpaperSelectorOpen ? previewContent : null
        }

        Component.onCompleted: {
            if (GlobalStates.wallpaperSelectorOpen) {
                delayedGrabTimer.start();
            }
        }

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        HyprlandFocusGrab {
            id: grab

            windows: [wallpaperWindow]
            active: false
            onCleared: () => {
                if (!active) GlobalStates.wallpaperSelectorOpen = false
            }
        }

        Connections {
            target: GlobalStates
            function onWallpaperSelectorOpenChanged() {
                if (GlobalStates.wallpaperSelectorOpen) {
                    delayedGrabTimer.start()
                }
            }
        }

        Timer {
            id: delayedGrabTimer

            interval: 100
            repeat: false
            onTriggered: {
                grab.active = GlobalStates.wallpaperSelectorOpen;
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: {
                GlobalStates.wallpaperSelectorOpen = false;
            }
        }

        Item {
            id: previewContent

            visible: GlobalStates.wallpaperSelectorOpen
            focus: GlobalStates.wallpaperSelectorOpen

            implicitWidth: wrapper.implicitWidth
            implicitHeight: wrapper.implicitHeight

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.wallpaperSelectorOpen = false;
                } else if (event.key === Qt.Key_Left) {
                    wrapper.item?.preview?.navigateLeft();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    wrapper.item?.preview?.navigateRight();
                    event.accepted = true;
                } else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
                    wrapper.item?.preview?.applyCurrentWallpaper();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    wrapper.item?.preview?.applyCurrentWallpaper();
                    event.accepted = true;
                }
            }

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 0
            }

            Loader {
                id: wrapper
                active: GlobalStates.wallpaperSelectorOpen
                sourceComponent: Item {
                    id: animationWrapper
                    property alias preview: wallpaperPreview
                    implicitWidth: wallpaperPreview.implicitWidth
                    implicitHeight: wallpaperPreview.implicitHeight

                    // Start from below and invisible
                    y: 200
                    opacity: 0

                    WallpaperPreview {
                        id: wallpaperPreview
                        anchors.centerIn: parent
                        Component.onCompleted: {
                            console.log("WallpaperPreview loaded with path:", wallpaperPath);
                            slideTimer.start();
                        }
                    }

                    Timer {
                        id: slideTimer
                        interval: 150
                        repeat: false
                        onTriggered: {
                            slideUpAnimation.start();
                            opacityAnimation.start();
                        }
                    }

                    NumberAnimation {
                        id: slideUpAnimation
                        target: animationWrapper
                        property: "y"
                        to: 0
                        duration: 500
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: opacityAnimation
                        target: animationWrapper
                        property: "opacity"
                        to: 1
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }
            }

        }

        // Instructions overlay
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 20
            width: instructionsText.implicitWidth + 20
            height: instructionsText.implicitHeight + 20
            color: Appearance.colors.colLayer2
            border.color: Appearance.m3colors.m3borderSecondary
            border.width: 1
            radius: 8
            z: 100

            Text {
                id: instructionsText

                anchors.centerIn: parent
                color: Appearance.m3colors.m3primaryText
                font.pixelSize: 12
            }

        }

    }

    IpcHandler {
        target: "wallpaper-selector"

        function toggle() {
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
        }
        function close() {
            GlobalStates.wallpaperSelectorOpen = false
        }
        function open() {
            GlobalStates.wallpaperSelectorOpen = true
        }
    }

    GlobalShortcut {
        name: "wallpaperToggle"
        description: qsTr("Toggles wallpaper selector on press")

        onPressed: {
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen
        }
    }

    GlobalShortcut {
        name: "wallpaperClose"
        description: qsTr("Closes wallpaper selector")

        onPressed: {
            GlobalStates.wallpaperSelectorOpen = false
        }
    }
}
