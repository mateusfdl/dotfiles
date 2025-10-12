import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    implicitWidth: windowText.implicitWidth
    implicitHeight: windowText.implicitHeight
    Layout.fillWidth: false

    property var activeWindow: null

    Process {
        id: activeWindowProcess
        running: false
        command: ["hyprctl", "activewindow", "-j"]

        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    root.activeWindow = JSON.parse(collector.text)
                } catch (e) {
                    root.activeWindow = null
                }
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: activeWindowProcess.running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            activeWindowProcess.running = true
        }
    }

    Component.onCompleted: {
        activeWindowProcess.running = true
    }

    Text {
        id: windowText
        anchors.fill: parent

        text: {
            var className = root.activeWindow?.class ?? ""
            if (!className) return ""

            var rewrites = {
                "Mozilla Firefox": "Firefox",
                "Visual Studio Code": "VS Code",
                "brave-browser": "Brave"
            }

            if (rewrites[className]) {
                return rewrites[className]
            }

            var firstWord = className.split(/[\s-_]/)[0]
            if (!firstWord) return className
            return firstWord.charAt(0).toUpperCase() + firstWord.slice(1).toLowerCase()
        }

        color: "white"
        font.pixelSize: 22
        font.weight: Font.Black
        font.family: "-apple-system"
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }
}
