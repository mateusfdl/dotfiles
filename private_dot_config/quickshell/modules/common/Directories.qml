pragma Singleton
pragma ComponentBehavior: Bound

import QsUtils
import Qt.labs.platform
import QtQuick
import Quickshell

Singleton {
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]

    property string shellConfig: Files.trimFileProtocol(`${Directories.config}/quickshell`)
    property string shellConfigPath: `${Directories.shellConfig}/config.json`
    property string currentWallpaperScriptPath: `${home}/scripts/current_wallpaper`

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
    }
}
