pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: greeterScope

    GreeterContext {
        id: greeterContext
    }

    // Display the greeter on every connected screen.
    // Uses PanelWindow with WlrLayershell attached properties for fullscreen overlay.
    // Unlike the lock screen which uses WlSessionLock (requires an active session),
    // the greeter runs before any session exists, so we use layer shell overlays.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: greeterWindow

            required property var modelData
            screen: modelData

            visible: true
            color: "transparent"

            WlrLayershell.namespace: "quickshell:greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            exclusiveZone: 0

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            GreeterContent {
                anchors.fill: parent
                context: greeterContext
            }
        }
    }
}
