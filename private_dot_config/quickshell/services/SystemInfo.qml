import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    property int volume: 100
    property bool volumeMuted: false

    Component.onCompleted: {
        volumeLevelProcess.running = true;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            //console.log("Hyprland raw event:", event.name);
            updateAll()
        }
    }

    Process {
        id: volumeLevelProcess

        running: false
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}' | sed 's/%//'"]
        onExited: (exitCode, stdout, stderr) => {
            if (exitCode === 0 && stdout) {
                var vol = parseInt(stdout.trim());
                if (!isNaN(vol))
                    root.volume = vol;

            }
            volumeMuteProcess.running = true;
        }
    }

    Process {
        id: volumeMuteProcess

        running: false
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo '1' || echo '0'"]
        onExited: (exitCode, stdout, stderr) => {
            if (exitCode === 0 && stdout)
                root.volumeMuted = stdout.trim() === "1";

        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: volumeLevelProcess.running = true
    }

}
