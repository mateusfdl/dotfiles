import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    required property var notificationObject

    function dismissNotification() {
        slideOutAnimation.start();
    }

    implicitHeight: contentColumn.implicitHeight + 24
    implicitWidth: Appearance.sizes.notificationPopupWidth - 16
    radius: Appearance.rounding.small
    color: {
        if (notificationObject.urgency === NotificationUrgency.Critical)
            return Qt.rgba(1, 0.3, 0.3, 0.15);
        else
            return Appearance.colors.colLayer1;
    }
    border.color: {
        if (notificationObject.urgency === NotificationUrgency.Critical)
            return Qt.rgba(1, 0.4, 0.4, 0.8);
        else
            return Appearance.m3colors.m3borderSecondary;
    }
    border.width: 1
    x: root.width
    Component.onCompleted: {
        slideInAnimation.start();
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
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
        id: contentColumn

        spacing: 12

        anchors {
            fill: parent
            margins: 12
        }

        Rectangle {
            id: iconContainer

            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            Layout.alignment: Qt.AlignTop
            radius: 24
            color: Appearance.colors.colLayer2
            visible: notificationObject.appIcon !== "" || notificationObject.image !== ""

            Image {
                anchors.centerIn: parent
                width: 32
                height: 32
                source: {
                    if (notificationObject.image !== "")
                        return notificationObject.image;
                    else if (notificationObject.appIcon !== "")
                        return "image://icon/" + notificationObject.appIcon;
                    return "";
                }
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    id: appNameText

                    Layout.fillWidth: true
                    text: notificationObject.appName || "Notification"
                    color: Appearance.m3colors.m3secondaryText
                    font.pixelSize: Appearance.font.pixelSize.textSmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: closeMouseArea.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: "×"
                        color: Appearance.m3colors.m3primaryText
                        font.pixelSize: 20
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
                id: summaryText

                Layout.fillWidth: true
                text: notificationObject.summary || ""
                color: Appearance.m3colors.m3primaryText
                font.pixelSize: Appearance.font.pixelSize.textBase
                font.weight: Font.Bold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            StyledText {
                id: bodyText

                Layout.fillWidth: true
                text: notificationObject.body || ""
                color: Appearance.m3colors.m3surfaceText
                font.pixelSize: Appearance.font.pixelSize.textSmall
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.StyledText
                visible: notificationObject.body !== ""
                onLinkActivated: (link) => {
                    Qt.openUrlExternally(link);
                    root.dismissNotification();
                }
            }

            Flow {
                Layout.fillWidth: true
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
                            font.pixelSize: Appearance.font.pixelSize.textSmall
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
        duration: Appearance.animation.elementMoveEnter.duration
        easing.type: Appearance.animation.elementMoveEnter.type
        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
    }

    NumberAnimation on x {
        id: slideOutAnimation

        to: root.width + 20
        duration: Appearance.animation.elementMoveExit.duration
        easing.type: Appearance.animation.elementMoveExit.type
        easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        running: false
        onFinished: {
            Notifications.discardNotification(notificationObject.notificationId);
        }
    }

}
