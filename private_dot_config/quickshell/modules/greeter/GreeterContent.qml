pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property GreeterContext context
    property string wallpaperPath: ""

    anchors.fill: parent

    function resetToLogin() {
        progressAnimation.stop();
        progressFill.width = 0;
        demoResetTimer.stop();
        root.context.loginSucceeded = false;
        root.context.loginInProgress = false;
        root.context.currentText = "";
        passwordInput.text = "";
        passwordInput.forceActiveFocus();
    }

    // Read wallpaper path from swww cache files directly.
    // At boot, the swww daemon isn't running yet, so `swww query` fails.
    // However, swww persists the last wallpaper in ~/.cache/swww/<monitor>.
    // The cache files are null-delimited: \0<filter>\0<path>\0
    Process {
        id: wallpaperQuery
        command: ["sh", "-c", `for f in "$HOME/.cache/swww/"*; do [ -f "$f" ] && tr '\\0' '\\n' < "$f" | sed -n '3p' && break; done`]
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
        usernameInput.forceActiveFocus();
    }

    // ===== BACKGROUND =====
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

        // Fallback background when wallpaper isn't available
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
            blurMax: 64
            blur: 1.0
            saturation: 0.4
            brightness: -0.1
            contrast: 0.1
        }

        // Dark overlay
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.4
        }
    }

    // ===== MAIN CONTENT =====
    Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            // Date
            Text {
                id: dateText
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
                color: Qt.rgba(1, 1, 1, 0.7)
                font.pixelSize: 22
                font.family: Appearance.font.family.uiFont
                font.weight: Font.Normal
            }

            // Clock
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

            Item { Layout.preferredHeight: 30 }

            // Greeting
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome"
                color: Qt.rgba(1, 1, 1, 0.9)
                font.pixelSize: 24
                font.family: Appearance.font.family.uiFont
                font.weight: Font.DemiBold
            }

            Item { Layout.preferredHeight: 8 }

            // ===== USERNAME FIELD =====
            Rectangle {
                id: usernameContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 320
                Layout.preferredHeight: 48

                color: Qt.rgba(1, 1, 1, 0.12)
                border.color: usernameInput.activeFocus ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.35)
                border.width: 1
                radius: 24

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 8

                    MaterialSymbol {
                        text: "person"
                        font.pixelSize: 20
                        color: Qt.rgba(1, 1, 1, 0.7)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: usernameInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        color: "#ffffff"
                        font.pixelSize: 16
                        font.family: Appearance.font.family.uiFont
                        focus: true
                        clip: true
                        selectByMouse: true

                        text: root.context.username
                        onTextChanged: root.context.username = text

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Username"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: parent.font.family
                            font.pixelSize: parent.font.pixelSize
                            font.italic: true
                            visible: parent.text.length === 0 && !parent.activeFocus
                        }

                        Keys.onTabPressed: passwordInput.forceActiveFocus()
                        Keys.onReturnPressed: passwordInput.forceActiveFocus()
                        Keys.onEnterPressed: passwordInput.forceActiveFocus()
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

            // ===== PASSWORD FIELD / PROGRESS BAR =====
            // Same pill shape. When loginSucceeded, the password content is hidden
            // and a progress bar fills inside the pill instead.
            Rectangle {
                id: passwordContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 320
                Layout.preferredHeight: 48

                color: Qt.rgba(1, 1, 1, 0.12)
                border.color: root.context.showFailure ? "#ff5555" : (passwordInput.activeFocus ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.35))
                border.width: root.context.loginSucceeded ? 0 : 1
                radius: 24
                clip: true

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

                // --- Password input content (hidden when login succeeded) ---
                RowLayout {
                    id: passwordContent
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 8
                    visible: !root.context.loginSucceeded

                    MaterialSymbol {
                        id: lockIcon
                        text: root.context.loginInProgress ? "sync" : "lock"
                        font.pixelSize: 20
                        color: Qt.rgba(1, 1, 1, 0.7)
                        Layout.alignment: Qt.AlignVCenter

                        RotationAnimation on rotation {
                            running: root.context.loginInProgress
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
                        enabled: !root.context.loginInProgress
                        clip: true

                        text: root.context.currentText
                        onTextChanged: root.context.currentText = text

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Password"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: parent.font.family
                            font.pixelSize: parent.font.pixelSize
                            font.italic: true
                            visible: parent.text.length === 0 && !parent.activeFocus
                        }

                        Keys.onReturnPressed: root.context.tryLogin()
                        Keys.onEnterPressed: root.context.tryLogin()
                        Keys.onEscapePressed: root.context.clearPassword()
                        Keys.onBacktabPressed: usernameInput.forceActiveFocus()
                    }

                    // Submit button
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        radius: 16
                        color: submitMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                        visible: passwordInput.text.length > 0 && !root.context.loginInProgress

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
                            onClicked: root.context.tryLogin()
                        }
                    }
                }

                // --- Progress bar (shown when login succeeded) ---
                // Fills the same pill shape from left to right
                Rectangle {
                    id: progressFill
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: 0
                    radius: parent.radius
                    color: Qt.rgba(1, 1, 1, 0.25)
                    visible: root.context.loginSucceeded

                    NumberAnimation {
                        id: progressAnimation
                        target: progressFill
                        property: "width"
                        from: 0
                        to: passwordContainer.width
                        duration: 8000
                        easing.type: Easing.OutQuart
                    }
                }
            }

            // Error message
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.context.errorMessage || "Authentication failed"
                color: "#ff5555"
                font.pixelSize: 14
                font.family: Appearance.font.family.uiFont
                opacity: root.context.showFailure ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            Item { Layout.preferredHeight: 12 }

            // greetd availability warning
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.context.greetdAvailable ? "" : "greetd is not available"
                color: "#ffaa55"
                font.pixelSize: 12
                font.family: Appearance.font.family.uiFont
                visible: !root.context.greetdAvailable && !root.context.loginSucceeded
            }

            // Demo mode hint (only when progress bar is showing)
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Press Escape to close"
                color: Qt.rgba(1, 1, 1, 0.3)
                font.pixelSize: 12
                font.family: Appearance.font.family.uiFont
                visible: root.context.loginSucceeded && !root.context.greetdAvailable
            }
        }
    }

    // Demo mode: auto-reset after 5s as safety net
    Timer {
        id: demoResetTimer
        interval: 5000
        repeat: false
        onTriggered: root.resetToLogin()
    }

    // Handle failure and success
    Connections {
        target: root.context
        function onFailed() {
            shakeAnimation.start();
            passwordInput.forceActiveFocus();
        }

        function onAuthenticated() {
            // Start the progress bar filling inside the password pill
            progressAnimation.start();

            // Launch the session immediately — the greeter stays as-is
            // until greetd kills it when the new session is ready
            root.context.launchSession();

            // Demo mode: auto-reset after 5s
            if (!root.context.greetdAvailable) {
                demoResetTimer.start();
            }
        }
    }

    // Escape to reset in demo mode
    Keys.onEscapePressed: {
        if (root.context.loginSucceeded && !root.context.greetdAvailable) {
            root.resetToLogin();
        }
    }

    // Focus username input on visible
    onVisibleChanged: {
        if (visible) {
            usernameInput.forceActiveFocus();
        }
    }
}
