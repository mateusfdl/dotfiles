pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property string vaultPath: Quickshell.env("VAULT_PATH")
    property alias options: configOptionsJsonAdapter
    property bool ready: false

    FileView {
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter
            property JsonObject ui: JsonObject {
                property string theme: "dark"
            }

            property JsonObject font: JsonObject {
                property JsonObject family: JsonObject {
                    property string uiFont: "Open Sans"
                    property string iconFont: "FiraConde Nerd Font"
                    property string codeFont: "JetBrains Mono NF"
                }
                property JsonObject pixelSize: JsonObject {
                    property int textSmall: 13
                    property int textBase: 15
                    property int textMedium: 16
                    property int textLarge: 19
                    property int iconLarge: 22
                }
            }

            property JsonObject audio: JsonObject {
                property JsonObject protection: JsonObject {
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            property JsonObject bar: JsonObject {
                property bool showBackground: true
                property string iconColor: ""
                property int margins: 15
                property JsonObject tray: JsonObject {
                    property int itemSize: 24
                    property int iconSize: 20
                    property int spacing: 14
                }
                property JsonObject workspaces: JsonObject {
                    property int spacing: 4
                    property int size: 24
                    property int activeSize: 8
                    property int inactiveSize: 8
                }
            }

            property JsonObject lock: JsonObject {
                property bool launchOnStartup: false
                property JsonObject blur: JsonObject {
                    property real radius: 100
                }
                property bool showLockedText: true
            }

            property JsonObject modules: JsonObject {
                property bool topbar: true
                property bool overview: true
                property bool windowSwitcher: true
                property bool launcher: true
                property bool wallpaper: true
                property bool notifications: true
                property bool lockScreen: true
                property bool cheatsheet: true
                property bool obsidianTodo: true
                property bool dailyTodos: true
            }

            property JsonObject overview: JsonObject {
                property real scale: 0.18
                property real windowPadding: 6
                property real workspaceNumberSize: 120
            }

            property JsonObject launcher: JsonObject {
                property int maxShown: 7
                property JsonObject sizes: JsonObject {
                    property int itemHeight: 57
                }
            }

            property JsonObject time: JsonObject {
                property string format: "hh:mm"
                property JsonObject pomodoro: JsonObject {
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20
            }
        }
    }
}
