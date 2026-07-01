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

    visible: MediaPlayer.isPlaying

    implicitWidth: visible ? collapsedContent.implicitWidth : 0
    implicitHeight: collapsedContent.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Style.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.animationCurves.expressiveEffects
        }
    }

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

    Item {
        id: collapsedContent

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: frame.implicitWidth
        implicitHeight: frame.implicitHeight

        Rectangle {
            id: frame

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: contentRow.implicitWidth + 24
            implicitHeight: contentRow.implicitHeight + 8

            radius: 11
            color: hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Item {
                id: contentRow

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: albumThumb.width + 26 + barsRow.width + 26 + titleText.implicitWidth + (artistText.visible ? 8 + artistText.implicitWidth : 0)
                implicitHeight: Math.max(albumThumb.height, barsRow.height)

                Rectangle {
                    id: albumThumb

                    width: 32
                    height: 32
                    radius: 9
                    color: Style.withAlpha(Style.music.surfaceVariant, 0.6)

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: albumArt

                        anchors.fill: parent
                        source: MediaPlayer.artUrl
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: albumArt.width
                                height: albumArt.height
                                radius: 9
                            }
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "album"
                        iconSize: 20
                        fill: 1
                        color: Style.withAlpha(Appearance.m3colors.m3primaryText, 0.2)
                        visible: albumArt.status !== Image.Ready
                    }
                }

                SpectrumBars {
                    id: barsRow

                    visible: MediaPlayer.isPlaying
                    barCount: 8
                    barWidth: 4
                    barSpacing: 3
                    barRadius: 1.5
                    minBarHeight: 4
                    maxBarHeight: 24
                    barColor: Style.music.barColor
                    barColorActive: Style.music.barColorActive
                    active: MediaPlayer.isPlaying
                    values: AudioSpectrum.bars
                    animationDuration: 100

                    anchors.left: albumThumb.right
                    anchors.leftMargin: 26
                    anchors.bottom: parent.bottom
                    width: barCount * barWidth + (barCount - 1) * barSpacing
                    height: 24
                }

                StyledText {
                    id: titleText

                    text: MediaPlayer.title || ""
                    font.pixelSize: 16
                    color: Appearance.m3colors.m3primaryText

                    anchors.left: barsRow.right
                    anchors.leftMargin: 26
                    anchors.bottom: barsRow.bottom
                    anchors.bottomMargin: -4
                }

                StyledText {
                    id: artistText

                    text: "- " + MediaPlayer.artist
                    font.pixelSize: 16
                    color: Appearance.m3colors.m3primaryText
                    visible: MediaPlayer.artist.length > 0

                    anchors.left: titleText.right
                    anchors.leftMargin: 8
                    anchors.bottom: barsRow.bottom
                    anchors.bottomMargin: -4
                }
            }
        }

        MouseArea {
            id: hoverArea

            anchors.fill: frame
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                var pos = mapToItem(null, 0, 0);
                var centerX = pos.x + root.width / 2;
                var popupX = centerX - 200; // popup is 400px wide
                var popupY = 18;
                Topbar.MusicIslandPopup.togglePopup(popupX, popupY);
            }
        }
    }
}
