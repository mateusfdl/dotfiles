pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volume: 100
    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string uptime: ""
    property string username: "user"

    function formatUptime(seconds) {
        if (!seconds || seconds < 60)
            return "less than a minute";

        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const mins = Math.floor((seconds % 3600) / 60);

        const parts = [];
        if (days > 0)
            parts.push(days + "d");
        if (hours > 0)
            parts.push(hours + "h");
        if (mins > 0 || parts.length === 0)
            parts.push(mins + "m");

        return parts.join(" ");
    }

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false
        onTriggered: {
            getUsername.running = true;
            fileOsRelease.reload();
            fileProcUptime.reload();
            const textOsRelease = fileOsRelease.text();
            const prettyNameMatch = textOsRelease.match(/^PRETTY_NAME="(.+?)"/m);
            const nameMatch = textOsRelease.match(/^NAME="(.+?)"/m);
            parent.distroName = prettyNameMatch ? prettyNameMatch[1] : (nameMatch ? nameMatch[1].replace(/Linux/i, "").trim() : "Unknown");
            const idMatch = textOsRelease.match(/^ID="?(.+?)"?$/m);
            parent.distroId = idMatch ? idMatch[1] : "unknown";
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: fileProcUptime.reload()
    }

    Process {
        id: getUsername

        command: ["whoami"]

        stdout: SplitParser {
            onRead: data => {
                root.username = data.trim();
            }
        }
    }

    FileView {
        id: fileOsRelease

        path: "/etc/os-release"
    }

    FileView {
        id: fileProcUptime

        path: "/proc/uptime"
        onLoaded: {
            const text = fileProcUptime.text();
            const seconds = parseInt(text.split(" ")[0], 10);
            root.uptime = root.formatUptime(seconds);
        }
    }
}
