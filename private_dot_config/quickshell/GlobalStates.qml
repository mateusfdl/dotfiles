import qs.modules.common
import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool overviewOpen: false
    property bool launcherOpen: false
    property bool wallpaperSelectorOpen: false
    property bool screenLocked: false
    property bool screenUnlockFailed: false
    property bool sessionOpen: false
    property bool superReleaseMightTrigger: true
    property bool windowSwitcherOpen: false
    property bool cheatsheetOpen: false
    property bool obsidianTodoOpen: false
    property bool dailyTodosOpen: false

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.options.lock.launchOnStartup && Config.ready && Persistent.ready && Persistent.isNewHyprlandInstance) {
                GlobalStates.screenLocked = true;
            }
        }
    }
    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Config.options.lock.launchOnStartup && Config.ready && Persistent.ready && Persistent.isNewHyprlandInstance) {
                GlobalStates.screenLocked = true;
            }
        }
    }

}