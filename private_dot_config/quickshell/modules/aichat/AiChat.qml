pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: aiChatScope

    PanelWindow {
        id: aiChatWindow

        visible: GlobalStates.aiChatOpen

        WlrLayershell.namespace: "quickshell:aichat"
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        HyprlandFocusGrab {
            id: grab
            windows: [ aiChatWindow ]
            active: false
            onCleared: () => {
                if (!active) GlobalStates.aiChatOpen = false
            }
        }

        Connections {
            target: GlobalStates
            function onAiChatOpenChanged() {
                if (GlobalStates.aiChatOpen) {
                    delayedGrabTimer.start()
                }
            }
        }

        Timer {
            id: delayedGrabTimer
            interval: 50
            repeat: false
            onTriggered: {
                grab.active = GlobalStates.aiChatOpen
            }
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            z: 0
            enabled: GlobalStates.aiChatOpen
            onClicked: {
                GlobalStates.aiChatOpen = false;
            }
        }

        Item {
            id: chatContent
            z: 1

            visible: GlobalStates.aiChatOpen
            focus: GlobalStates.aiChatOpen

            width: wrapper.implicitWidth
            height: wrapper.implicitHeight

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.aiChatOpen = false;
                }
            }

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 0
            }

            Loader {
                id: wrapper
                active: GlobalStates.aiChatOpen
                sourceComponent: MouseArea {
                    id: animationWrapper
                    implicitWidth: aiChatPanel.implicitWidth
                    implicitHeight: aiChatPanel.implicitHeight

                    x: -300
                    opacity: 0

                    AiChatContent {
                        id: aiChatPanel
                        implicitWidth: aiChatWindow.width * 0.30
                        implicitHeight: aiChatWindow.height - Appearance.sizes.barHeight - 64

                        Component.onCompleted: {
                            slideTimer.start();
                        }

                        onCloseRequested: {
                            GlobalStates.aiChatOpen = false
                        }
                    }

                    Timer {
                        id: slideTimer
                        interval: 50
                        repeat: false
                        onTriggered: {
                            slideInAnimation.start();
                            opacityAnimation.start();
                        }
                    }

                    NumberAnimation {
                        id: slideInAnimation
                        target: animationWrapper
                        property: "x"
                        to: 0
                        duration: 400
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: opacityAnimation
                        target: animationWrapper
                        property: "opacity"
                        to: 1
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "aichat"

        function toggle() {
            GlobalStates.aiChatOpen = !GlobalStates.aiChatOpen
        }
        function close() {
            GlobalStates.aiChatOpen = false
        }
        function open() {
            GlobalStates.aiChatOpen = true
        }
    }

    GlobalShortcut {
        name: "aiChatToggle"
        description: qsTr("Toggles AI chat on press")

        onPressed: {
            GlobalStates.aiChatOpen = !GlobalStates.aiChatOpen
        }
    }

    GlobalShortcut {
        name: "aiChatClose"
        description: qsTr("Closes AI chat")

        onPressed: {
            GlobalStates.aiChatOpen = false
        }
    }
}
