pragma Singleton
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

Scope {
    id: popupScope

    property bool popupVisible: false
    property real popupX: 0
    property real popupY: 0

    function showPopup(x, y) {
        popupX = x;
        popupY = y;
        popupVisible = true;
    }

    function hidePopup() {
        popupVisible = false;
    }

    function togglePopup(x, y) {
        if (popupVisible)
            hidePopup();
        else
            showPopup(x, y);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popup

            required property var modelData

            screen: modelData
            visible: popupScope.popupVisible
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // Background overlay — click to dismiss
            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: popupScope.popupVisible
                onClicked: popupScope.hidePopup()
            }

            // The "island" card
            Rectangle {
                id: islandCard

                x: popupScope.popupX
                y: popupScope.popupVisible ? popupScope.popupY : -height - 60
                width: 400
                height: cardContent.height + 40
                radius: 24
                color: Qt.rgba(0.08, 0.08, 0.10, 0.96)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                z: 10
                layer.enabled: true

                // Prevent clicks from passing through
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                    z: -1
                }

                ColumnLayout {
                    id: cardContent

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 20
                    }
                    spacing: 16

                    // --- Album art + Track info row ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        // Album art
                        Rectangle {
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 96
                            radius: 14
                            color: Qt.rgba(0.15, 0.15, 0.18, 0.6)

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
                                        radius: 14
                                    }
                                }
                            }

                            // Fallback
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "album"
                                iconSize: 44
                                fill: 1
                                color: Qt.rgba(1, 1, 1, 0.2)
                                visible: albumArt.status !== Image.Ready
                            }
                        }

                        // Track info
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            StyledText {
                                Layout.fillWidth: true
                                text: MediaPlayer.title || "No track playing"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Qt.rgba(1, 1, 1, 0.95)
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: MediaPlayer.artist || "Unknown Artist"
                                font.pixelSize: 13
                                color: Qt.rgba(1, 1, 1, 0.6)
                                wrapMode: Text.Wrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: MediaPlayer.album || ""
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.4)
                                wrapMode: Text.Wrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                visible: (MediaPlayer.album || "") !== ""
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // --- Spectrum visualizer (decorative) ---
                    SpectrumBars {
                        id: popupBars

                        readonly property int availableWidth: islandCard.width - 40  // card width minus margins
                        readonly property int computedBarCount: Math.max(8, Math.floor((availableWidth + 2) / (3 + 2)))  // (width + spacing) / (barWidth + barSpacing)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        Layout.topMargin: 20
                        barCount: computedBarCount
                        barWidth: 3
                        barSpacing: 2
                        barRadius: 1.5
                        minBarHeight: 2
                        maxBarHeight: 28
                        barColor: Qt.rgba(1, 0.6, 0.8, 0.15)
                        barColorActive: Qt.rgba(1, 0.6, 0.8, 0.5)
                        active: MediaPlayer.isPlaying
                        values: AudioSpectrum.bars
                        animationDuration: 100
                    }

                    // --- Progress bar ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 3
                            radius: 1.5
                            color: Qt.rgba(1, 1, 1, 0.08)

                            Rectangle {
                                width: parent.width * MediaPlayer.progress
                                height: parent.height
                                radius: parent.radius
                                color: Qt.rgba(1, 0.6, 0.8, 0.8)

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: MediaPlayer.positionText
                                font.pixelSize: 10
                                font.family: Appearance.font.family.monospace
                                color: Qt.rgba(1, 1, 1, 0.4)
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: MediaPlayer.lengthText
                                font.pixelSize: 10
                                font.family: Appearance.font.family.monospace
                                color: Qt.rgba(1, 1, 1, 0.4)
                            }
                        }
                    }

                    // --- Transport controls ---
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                        }

                        // Previous
                        RippleButton {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            buttonRadius: 24
                            enabled: MediaPlayer.canGoPrevious

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                iconSize: 26
                                fill: 1
                                color: MediaPlayer.canGoPrevious ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.25)
                            }

                            onClicked: MediaPlayer.previous()
                        }

                        // Play / Pause
                        RippleButton {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            buttonRadius: 28

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: MediaPlayer.isPlaying ? "pause" : "play_arrow"
                                iconSize: 32
                                fill: 1
                                color: Qt.rgba(1, 0.6, 0.8, 1)
                            }

                            onClicked: MediaPlayer.playPause()
                        }

                        // Next
                        RippleButton {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            buttonRadius: 24
                            enabled: MediaPlayer.canGoNext

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_next"
                                iconSize: 26
                                fill: 1
                                color: MediaPlayer.canGoNext ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.25)
                            }

                            onClicked: MediaPlayer.next()
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Slide-down animation
                Behavior on y {
                    NumberAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }

                // Drop shadow
                layer.effect: DropShadow {
                    radius: 28
                    samples: 57
                    color: Qt.rgba(0, 0, 0, 0.65)
                    verticalOffset: 6
                    horizontalOffset: 0
                }
            }
        }
    }
}
