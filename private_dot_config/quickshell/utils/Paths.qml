import Caelestia
import Quickshell
import qs.config
pragma Singleton

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`
    readonly property string videos: Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`
    readonly property string data: Quickshell.env("XDG_DATA_HOME")
    readonly property string state: Quickshell.env("XDG_STATE_HOME")
    readonly property string cache: Quickshell.env("XDG_CACHE_HOME")
    readonly property string config: Quickshell.env("XDG_CONFIG_HOME")
    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string wallsdir: absolutePath(Config.paths.wallpaperDir)
    readonly property string recsdir: `${videos}/Recordings`

    function toLocalFile(path: url) : string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string) : string {
        return toLocalFile(path.replace("~", home));
    }

    function shortenHome(path: string) : string {
        return path.replace(home, "~");
    }

}
