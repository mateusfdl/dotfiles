import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    // Only show when there's an active player
    visible: MediaPlayer.hasActivePlayer

    implicitWidth: visible ? (icon.implicitWidth + 12) : 0
    implicitHeight: icon.implicitHeight

    MaterialSymbol {
        id: icon

        anchors.centerIn: parent
        text: "music_note"  // macOS-style music note icon
        iconSize: 22
        fill: MediaPlayer.isPlaying ? 1 : 0
        color: MediaPlayer.isPlaying ?
            Qt.rgba(1, 0.6, 0.8, 0.9) :  // Pink/red when playing
            Qt.rgba(1, 1, 1, 0.7)         // White when paused

        Behavior on fill {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
        radius: 4
        z: -1

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var pos = mapToItem(null, 0, 0)
            var iconRightX = pos.x + root.width
            var popupX = iconRightX - 400  // Popup width is ~400
            var popupY = 60  // Below the bar
            Topbar.NowPlayingPopup.togglePopup(popupX, popupY)
        }
    }
}
