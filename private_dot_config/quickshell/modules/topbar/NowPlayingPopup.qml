import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.services
pragma Singleton

Scope {
    id: nowPlayingPopupScope

    property bool popupVisible: false
    property real popupX: 0
    property real popupY: 0

    function showPopup(x, y) {
        popupX = x
        popupY = y
        popupVisible = true
    }

    function hidePopup() {
        popupVisible = false
    }

    function togglePopup(x, y) {
        if (popupVisible)
            hidePopup()
        else
            showPopup(x, y)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popup

            required property var modelData

            screen: modelData
            visible: nowPlayingPopupScope.popupVisible
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // Background overlay
            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: nowPlayingPopupScope.popupVisible
                onClicked: {
                    nowPlayingPopupScope.hidePopup()
                }
            }

            // Popup window with elevator effect
            Rectangle {
                id: popupBackground

                x: nowPlayingPopupScope.popupX
                y: nowPlayingPopupScope.popupVisible ? nowPlayingPopupScope.popupY : -height - 100
                width: 420
                height: contentColumn.height + 48
                radius: 16
                color: Qt.rgba(0.12, 0.12, 0.12, 0.95)
                border.color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                z: 10
                layer.enabled: true

                // Prevent clicks from passing through
                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        mouse.accepted = true
                    }
                    z: -1
                }

                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        MaterialSymbol {
                            text: "music_note"
                            iconSize: 32
                            fill: 1
                            color: Qt.rgba(1, 0.6, 0.8, 1)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: "Now Playing"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                color: Qt.rgba(1, 1, 1, 0.95)
                            }

                            StyledText {
                                text: MediaPlayer.identity || "No player"
                                font.pixelSize: 12
                                color: Qt.rgba(1, 1, 1, 0.6)
                            }
                        }
                    }

                    // Album art and track info
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        // Album art
                        Rectangle {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 120
                            radius: 12
                            color: Qt.rgba(0.2, 0.2, 0.25, 0.5)

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
                                        radius: 12
                                    }
                                }
                            }

                            // Fallback icon
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "album"
                                iconSize: 56
                                fill: 1
                                color: Qt.rgba(1, 1, 1, 0.3)
                                visible: albumArt.status !== Image.Ready
                            }
                        }

                        // Track info
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 8

                            StyledText {
                                Layout.fillWidth: true
                                text: MediaPlayer.title || "No track playing"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                color: Qt.rgba(1, 1, 1, 0.95)
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: MediaPlayer.artist || "Unknown Artist"
                                font.pixelSize: 14
                                color: Qt.rgba(1, 1, 1, 0.7)
                                wrapMode: Text.Wrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: MediaPlayer.album || ""
                                font.pixelSize: 12
                                color: Qt.rgba(1, 1, 1, 0.5)
                                wrapMode: Text.Wrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                visible: MediaPlayer.album !== ""
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // Progress bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            radius: 2
                            color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                width: parent.width * MediaPlayer.progress
                                height: parent.height
                                radius: parent.radius
                                color: Qt.rgba(1, 0.6, 0.8, 0.9)

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
                                font.family: "monospace"
                                color: Qt.rgba(1, 1, 1, 0.5)
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: MediaPlayer.lengthText
                                font.pixelSize: 10
                                font.family: "monospace"
                                color: Qt.rgba(1, 1, 1, 0.5)
                            }
                        }
                    }

                    // Control buttons
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        spacing: 12

                        Item {
                            Layout.fillWidth: true
                        }

                        // Previous
                        RippleButton {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            buttonRadius: 28
                            enabled: MediaPlayer.canGoPrevious

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                iconSize: 28
                                fill: 1
                                color: MediaPlayer.canGoPrevious ?
                                    Qt.rgba(1, 1, 1, 0.95) :
                                    Qt.rgba(1, 1, 1, 0.3)
                            }

                            onClicked: MediaPlayer.previous()
                        }

                        // Play/Pause
                        RippleButton {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            buttonRadius: 32

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: MediaPlayer.isPlaying ? "pause" : "play_arrow"
                                iconSize: 36
                                fill: 1
                                color: Qt.rgba(1, 0.6, 0.8, 1)
                            }

                            onClicked: MediaPlayer.playPause()
                        }

                        // Next
                        RippleButton {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            buttonRadius: 28
                            enabled: MediaPlayer.canGoNext

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "skip_next"
                                iconSize: 28
                                fill: 1
                                color: MediaPlayer.canGoNext ?
                                    Qt.rgba(1, 1, 1, 0.95) :
                                    Qt.rgba(1, 1, 1, 0.3)
                            }

                            onClicked: MediaPlayer.next()
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Elevator animation from top (macOS dock style)
                Behavior on y {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

                layer.effect: DropShadow {
                    radius: 32
                    samples: 65
                    color: Qt.rgba(0, 0, 0, 0.7)
                    verticalOffset: 8
                    horizontalOffset: 0
                }
            }
        }
    }
}
