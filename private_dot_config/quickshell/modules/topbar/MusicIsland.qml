import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import QsUtils
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    // Only show when something is actively playing
    visible: MediaPlayer.isPlaying

    implicitWidth: visible ? collapsedContent.implicitWidth : 0
    implicitHeight: contentRow.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
    }

    // Bind the AudioSpectrum singleton to media player state
    Connections {
        target: MediaPlayer
        function onIsPlayingChanged() {
            AudioSpectrum.active = MediaPlayer.isPlaying;
        }
    }

    Component.onCompleted: {
        AudioSpectrum.barCount = 32;
        AudioSpectrum.fps = 30;
        AudioSpectrum.smoothing = 0.65;
        AudioSpectrum.sensitivity = 1.5;
        AudioSpectrum.active = MediaPlayer.isPlaying;
    }

    // --- Collapsed inline content (spectrum bars + track name in topbar) ---
    Item {
        id: collapsedContent

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        Item {
            id: contentRow

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: barsRow.width + 10 + titleText.implicitWidth
            implicitHeight: barsRow.height

            SpectrumBars {
                id: barsRow

                visible: MediaPlayer.isPlaying
                barCount: 6
                barWidth: 3
                barSpacing: 2
                barRadius: 1.5
                minBarHeight: 3
                maxBarHeight: 18
                barColor: Qt.rgba(1, 1, 1, 0.25)
                barColorActive: Qt.rgba(1, 0.6, 0.8, 0.85)
                active: MediaPlayer.isPlaying
                values: AudioSpectrum.bars
                animationDuration: 100

                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: 6 * 3 + 5 * 2  // barCount * barWidth + (barCount-1) * barSpacing
                height: 18
            }

            StyledText {
                id: titleText

                text: MediaPlayer.title || ""
                font.pixelSize: 13
                color: Config.options.bar.iconColor || Appearance.m3colors.m3primaryText

                anchors.left: barsRow.right
                anchors.leftMargin: 10
                anchors.bottom: parent.bottom
            }
        }

        // Hover background
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            color: hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            radius: 6
            z: -1

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            id: hoverArea

            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                var pos = mapToItem(null, 0, 0);
                var centerX = pos.x + root.width / 2;
                var popupX = centerX - 200; // popup is 400px wide
                var popupY = 2;
                Topbar.MusicIslandPopup.togglePopup(popupX, popupY);
            }
        }
    }
}
