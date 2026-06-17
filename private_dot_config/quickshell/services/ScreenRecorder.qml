pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property string recordScript: Directories.home + "/scripts/record_current_monitor"
    property string regionFile: "/tmp/screen_recording.geometry"
    property bool isRecording: false
    property bool hasRegion: false
    property int regionX: 0
    property int regionY: 0
    property int regionWidth: 0
    property int regionHeight: 0

    function toggle() {
        toggleProcess.running = true;
    }

    function checkStatus() {
        pidCheckProcess.running = true;
    }

    function parseRegion(text) {
        const match = text.trim().match(/^(-?\d+),(-?\d+)\s+(\d+)x(\d+)$/);
        if (!match) {
            root.hasRegion = false;
            return;
        }
        root.regionX = parseInt(match[1], 10);
        root.regionY = parseInt(match[2], 10);
        root.regionWidth = parseInt(match[3], 10);
        root.regionHeight = parseInt(match[4], 10);
        root.hasRegion = true;
    }

    onIsRecordingChanged: {
        if (isRecording) {
            regionView.reload();
        } else {
            root.hasRegion = false;
        }
    }

    Component.onCompleted: {
        checkStatus();
    }

    FileView {
        id: regionView

        path: root.regionFile
        watchChanges: true
        printErrors: false
        onLoaded: root.parseRegion(regionView.text())
        onFileChanged: reload()
        onLoadFailed: root.hasRegion = false
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
