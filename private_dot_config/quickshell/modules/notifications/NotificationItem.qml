import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QsUtils

Rectangle {
    id: root

    required property var notificationObject

    readonly property bool isCritical: notificationObject.urgency === NotificationUrgency.Critical
    readonly property bool hasImage: notificationObject.appIcon !== "" || notificationObject.image !== ""
    readonly property string initial: {
        const name = (notificationObject.appName || notificationObject.summary || "?").trim();
        return name.length > 0 ? name.charAt(0).toUpperCase() : "?";
    }
    readonly property string timeText: {
        if (!notificationObject.time)
            return "";
        return new Date(notificationObject.time).toLocaleTimeString(Qt.locale(), "hh:mm");
    }

    function dismissNotification() {
        slideOutAnimation.start();
    }

    implicitHeight: contentRow.implicitHeight + 32
    implicitWidth: Appearance.sizes.notificationPopupWidth - 16
    radius: Appearance.rounding.normal
    clip: true
    color: isCritical ? Qt.rgba(1, 0.3, 0.3, 0.16) : Appearance.m3colors.m3selectionBackground
    border.color: isCritical ? Qt.rgba(1, 0.4, 0.4, 0.8) : Appearance.m3colors.m3borderSecondary
    border.width: 1
    x: root.width
    Component.onCompleted: {
        slideInAnimation.start();
    }

    // Subtle top highlight so the card reads as lifted, not a flat block
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 1
        color: Qt.rgba(1, 1, 1, 0.07)
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.dismissNotification();
        }
        onEntered: {
            if (notificationObject.timer)
                notificationObject.timer.stop();
        }
        onExited: {
            if (notificationObject.timer)
                notificationObject.timer.start();
        }
    }

    RowLayout {
        id: contentRow

        spacing: 12

        anchors {
            fill: parent
            margins: 16
        }

        // App icon (literal icon for real apps; initial-letter avatar as fallback)
        Rectangle {
            id: iconContainer

            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignTop
            radius: 11
            color: root.hasImage ? "transparent" : Appearance.colors.colLayer2

            Image {
                anchors.fill: parent
                visible: root.hasImage
                source: {
                    if (notificationObject.image !== "")
                        return notificationObject.image;
                    else if (notificationObject.appIcon !== "")
                        return "image://icon/" + notificationObject.appIcon;
                    return "";
                }
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            StyledText {
                anchors.centerIn: parent
                visible: !root.hasImage
                text: root.initial
                color: Appearance.m3colors.m3primaryText
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    id: summaryText

                    Layout.fillWidth: true
                    text: notificationObject.summary || notificationObject.appName || "Notification"
                    color: Appearance.m3colors.m3primaryText
                    font.pixelSize: Style.font.pixelSize.textBase
                    font.weight: Font.Bold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                StyledText {
                    id: timeStamp

                    Layout.alignment: Qt.AlignTop
                    text: root.timeText
                    color: Appearance.m3colors.m3secondaryText
                    font.pixelSize: Style.font.pixelSize.textSmall
                    visible: root.timeText !== "" && !mouseArea.containsMouse
                }

                // macOS-style close, revealed on hover in place of the timestamp
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 11
                    visible: mouseArea.containsMouse || closeMouseArea.containsMouse
                    color: closeMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                    StyledText {
                        anchors.centerIn: parent
                        text: "×"
                        color: Appearance.m3colors.m3primaryText
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        id: closeMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissNotification()
                    }
                }
            }

            StyledText {
                id: bodyText

                Layout.fillWidth: true
                text: notificationObject.body || ""
                color: Appearance.m3colors.m3surfaceText
                font.pixelSize: Style.font.pixelSize.textSmall
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.StyledText
                visible: notificationObject.body !== ""
                onLinkActivated: link => {
                    Qt.openUrlExternally(link);
                    root.dismissNotification();
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 6
                visible: notificationObject.actions.length > 0

                Repeater {
                    model: notificationObject.actions

                    delegate: Rectangle {
                        required property var modelData

                        width: actionText.implicitWidth + 16
                        height: 32
                        radius: Appearance.rounding.verysmall
                        color: actionMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                        border.color: Appearance.m3colors.m3borderSecondary
                        border.width: 1

                        StyledText {
                            id: actionText

                            anchors.centerIn: parent
                            text: modelData.text
                            color: Appearance.m3colors.m3primaryText
                            font.pixelSize: Style.font.pixelSize.textSmall
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: actionMouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Notifications.attemptInvokeAction(notificationObject.notificationId, modelData.identifier);
                            }
                        }
                    }
                }
            }
        }
    }

    NumberAnimation on x {
        id: slideInAnimation

        from: root.width
        to: 0
        duration: Style.animation.elementMoveEnter.duration
        easing.type: Style.animation.elementMoveEnter.type
        easing.bezierCurve: Style.animation.elementMoveEnter.bezierCurve
    }

    NumberAnimation on x {
        id: slideOutAnimation

        to: root.width + 20
        duration: Style.animation.elementMoveExit.duration
        easing.type: Style.animation.elementMoveExit.type
        easing.bezierCurve: Style.animation.elementMoveExit.bezierCurve
        running: false
        onFinished: {
            Notifications.discardNotification(notificationObject.notificationId);
        }
    }
}
