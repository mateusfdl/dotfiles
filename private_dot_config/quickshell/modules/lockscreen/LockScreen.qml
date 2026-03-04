pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: lockScope

    LockContext {
        id: lockContext

        onUnlocked: {
            if (sessionLockLoader.item) {
                sessionLockLoader.item.locked = false;
            }
        }

        onFailed: {
            GlobalStates.screenUnlockFailed = true;
        }
    }

    Loader {
        id: sessionLockLoader
        active: GlobalStates.screenLocked

        sourceComponent: WlSessionLock {
            id: sessionLock

            locked: true

            WlSessionLockSurface {
                LockContent {
                    anchors.fill: parent
                    context: lockContext
                }
            }

            onLockedChanged: {
                if (!locked) {
                    GlobalStates.screenLocked = false;
                }
            }
        }
    }

    // ===== IPC HANDLERS =====
    IpcHandler {
        target: "lockscreen"

        function toggle() {
            GlobalStates.screenLocked = !GlobalStates.screenLocked;
        }

        function lock() {
            GlobalStates.screenLocked = true;
        }

        function unlock() {
            // Only allow unlock via password, not IPC
            console.log("Unlock via IPC not allowed - use password");
        }
    }

    // ===== KEYBOARD SHORTCUTS =====
    GlobalShortcut {
        name: "lockscreenLock"
        description: qsTr("Locks the screen")

        onPressed: {
            GlobalStates.screenLocked = true;
        }
    }

    // Reset failure state when unlocking
    Connections {
        target: GlobalStates

        function onScreenLockedChanged() {
            if (!GlobalStates.screenLocked) {
                GlobalStates.screenUnlockFailed = false;
                lockContext.clearPassword();
            }
        }
    }
}
