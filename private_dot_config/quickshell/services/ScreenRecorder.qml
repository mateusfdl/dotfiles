pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property string recordScript: Directories.home + "/scripts/record_current_monitor.sh"
    property bool isRecording: false

    function toggle() {
        toggleProcess.running = true;
    }

    function checkStatus() {
        pidCheckProcess.running = true;
    }

    Component.onCompleted: {
        checkStatus();
    }

    Process {
        id: toggleProcess

        running: false
        command: [root.recordScript, "toggle"]
        onExited: {
            checkStatus();
        }
    }

    Process {
        id: statusProcess

        running: false
        command: [root.recordScript, "status"]
        onExited: {
            pidCheckProcess.running = true;
        }
    }

    Process {
        id: pidCheckProcess

        running: false
        command: ["sh", "-c", "test -f /tmp/screen_recording.pid && kill -0 $(cat /tmp/screen_recording.pid) 2>/dev/null && echo recording || echo stopped"]

        stdout: SplitParser {
            onRead: data => {
                const output = data.trim();
                root.isRecording = (output === "recording");
            }
        }
    }

    Timer {
        id: statusTimer

        interval: 500
        repeat: true
        running: true
        onTriggered: {
            checkStatus();
        }
    }
}
