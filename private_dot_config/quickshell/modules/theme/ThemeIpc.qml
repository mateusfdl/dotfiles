import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Scope {
    id: themeIpcScope

    IpcHandler {
        target: "theme"

        property string mode: Appearance.currentThemeMode

        function toggle() {
            const newMode = Appearance.currentThemeMode === "dark" ? "light" : "dark"
            Appearance.currentThemeMode = newMode
            console.log("[IPC] Theme mode toggled to:", newMode)
        }

        function setDark() {
            Appearance.currentThemeMode = "dark"
            console.log("[IPC] Theme mode set to: dark")
        }

        function setLight() {
            Appearance.currentThemeMode = "light"
            console.log("[IPC] Theme mode set to: light")
        }
    }
}
