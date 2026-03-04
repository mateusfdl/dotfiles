pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    required property LockContext context
    property string wallpaperPath: ""
    property string username: ""

    anchors.fill: parent

    Process {
        id: wallpaperQuery
        command: [Directories.currentWallpaperScriptPath]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const path = data.trim();
                if (path.length > 0) {
                    root.wallpaperPath = path;
                }
            }
        }
    }

    Component.onCompleted: {
        username = Quickshell.env("USER") || "User";
        passwordInput.forceActiveFocus();
    }

    Item {
        id: backgroundContainer
        anchors.fill: parent

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.wallpaperPath ? "file:" + root.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.m3colors.m3windowBackground
            visible: wallpaperImage.status !== Image.Ready
        }

        MultiEffect {
            id: blurEffect
            source: wallpaperImage
            anchors.fill: wallpaperImage
            visible: wallpaperImage.status === Image.Ready
            blurEnabled: true
            blurMax: Config.options.lock?.blur?.radius ?? 64
            blur: 1.0
            saturation: 0.4
            brightness: -0.1
            contrast: 0.1
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.4
        }
    }

    Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Text {
                id: dateText
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
                color: Qt.rgba(1, 1, 1, 0.7)
                font.pixelSize: 22
                font.family: Appearance.font.family.uiFont
                font.weight: Font.Normal
            }

            Text {
                id: timeDisplay
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(new Date(), "HH:mm")
                color: "#ffffff"
                font.pixelSize: 120
                font.family: Appearance.font.family.uiFont
                font.weight: Font.Light

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        timeDisplay.text = Qt.formatDateTime(new Date(), "HH:mm");
                        dateText.text = Qt.formatDateTime(new Date(), "dddd, d MMMM");
                    }
                }
            }

            Item { Layout.preferredHeight: 50 }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.username
                color: Qt.rgba(1, 1, 1, 0.8)
                font.pixelSize: 20
                font.family: Appearance.font.family.uiFont
                font.weight: Font.Normal
            }

            Item { Layout.preferredHeight: 8 }

            Rectangle {
                id: passwordContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 320
                Layout.preferredHeight: 48

                color: Qt.rgba(1, 1, 1, 0.12)
                border.color: root.context.showFailure ? "#ff5555" : Qt.rgba(1, 1, 1, 0.35)
                border.width: 1
                radius: 24

                transform: Translate { id: shakeTransform; x: 0 }

                SequentialAnimation {
                    id: shakeAnimation
                    loops: 2
                    NumberAnimation {
                        target: shakeTransform
                        property: "x"
                        to: 10
                        duration: 50
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: shakeTransform
                        property: "x"
                        to: -10
                        duration: 100
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: shakeTransform
                        property: "x"
                        to: 0
                        duration: 50
                        easing.type: Easing.OutQuad
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 8

                    MaterialSymbol {
                        id: lockIcon
                        text: root.context.unlockInProgress ? "sync" : "lock"
                        font.pixelSize: 20
                        color: Qt.rgba(1, 1, 1, 0.7)
                        Layout.alignment: Qt.AlignVCenter

                        RotationAnimation on rotation {
                            running: root.context.unlockInProgress
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    TextInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        color: "#ffffff"
                        echoMode: TextInput.Password
                        font.pixelSize: 16
                        font.family: Appearance.font.family.uiFont
                        passwordCharacter: "\u2022"
                        focus: true
                        enabled: !root.context.unlockInProgress
                        clip: true

                        text: root.context.currentText
                        onTextChanged: root.context.currentText = text

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Enter Password"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: parent.font.family
                            font.pixelSize: parent.font.pixelSize
                            font.italic: true
                            visible: parent.text.length === 0 && !parent.activeFocus
                        }

                        Keys.onReturnPressed: root.context.tryUnlock()
                        Keys.onEnterPressed: root.context.tryUnlock()
                        Keys.onEscapePressed: root.context.clearPassword()
                    }

                    // Submit button
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        radius: 16
                        color: submitMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                        visible: passwordInput.text.length > 0 && !root.context.unlockInProgress

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            font.pixelSize: 18
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: submitMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.context.tryUnlock()
                        }
                    }
                }
            }

            // Error message
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Authentication failed"
                color: "#ff5555"
                font.pixelSize: 14
                font.family: Appearance.font.family.uiFont
                opacity: root.context.showFailure ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            Item { Layout.preferredHeight: 20 }

            // Hint text
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Config.options.lock?.showLockedText ? "Screen Locked" : ""
                color: Qt.rgba(1, 1, 1, 0.5)
                font.pixelSize: 12
                font.family: Appearance.font.family.uiFont
                visible: text.length > 0
            }
        }
    }

    // Handle failure animation
    Connections {
        target: root.context
        function onFailed() {
            shakeAnimation.start();
            passwordInput.forceActiveFocus();
        }
    }

    // Focus password input on visible
    onVisibleChanged: {
        if (visible) {
            passwordInput.forceActiveFocus();
        }
    }
}
