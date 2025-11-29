import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    property int volume: 100
    property bool volumeMuted: false
    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string uptime: "0:00"
    property string username: "user"

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false
        onTriggered: {
            getUsername.running = true;
            getUptime.running = true;
            fileOsRelease.reload();
            const textOsRelease = fileOsRelease.text();
            const prettyNameMatch = textOsRelease.match(/^PRETTY_NAME="(.+?)"/m);
            const nameMatch = textOsRelease.match(/^NAME="(.+?)"/m);
            parent.distroName = prettyNameMatch ? prettyNameMatch[1] : (nameMatch ? nameMatch[1].replace(/Linux/i, "").trim() : "Unknown");
            const idMatch = textOsRelease.match(/^ID="?(.+?)"?$/m);
            parent.distroId = idMatch ? idMatch[1] : "unknown";
        }
    }

    Connections {
        function onRawEvent(event) {
            updateAll();
        }

        target: Hyprland
    }

    Process {
        id: getUsername

        command: ["whoami"]

        stdout: SplitParser {
            onRead: (data) => {
                root.username = data.trim();
            }
        }

    }

    FileView {
        id: fileOsRelease

        path: "/etc/os-release"
    }

    Process {
        id: getUptime

        command: ["uptime", "-p"]

        stdout: SplitParser {
            onRead: (data) => {
                root.uptime = data.replace(/up/, "").trim();
            }
        }

    }

}
