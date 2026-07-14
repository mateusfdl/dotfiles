pragma ComponentBehavior: Bound

import QtQuick
import QsUtils
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property int currentIndex: 0
    property string currentLabel: ""
    property string incomingLabel: ""
    readonly property int activeCount: Reminders.activeReminders.length
    readonly property real labelWidth: Math.ceil(Math.max(currentLabelMetrics.advanceWidth, incomingLabelMetrics.advanceWidth))

    visible: root.activeCount > 0
    implicitWidth: visible ? frame.implicitWidth : 0
    implicitHeight: frame.implicitHeight

    function labelAt(index) {
        if (root.activeCount === 0)
            return "";
        return Reminders.activeReminders[index].description;
    }

    function resetLabel() {
        if (root.activeCount === 0) {
            root.currentIndex = 0;
            root.currentLabel = "";
            root.incomingLabel = "";
            return;
        }

        if (root.currentIndex >= root.activeCount)
            root.currentIndex = 0;

        root.currentLabel = root.labelAt(root.currentIndex);
        root.incomingLabel = "";
        currentLabelText.y = 0;
        incomingLabelText.y = -labelViewport.height;
    }

    function rotate() {
        if (root.activeCount === 0) {
            root.resetLabel();
            return;
        }

        if (root.activeCount === 1) {
            root.currentIndex = 0;
            root.currentLabel = root.labelAt(0);
            return;
        }

        const nextIndex = (root.currentIndex + 1) % root.activeCount;
        root.currentIndex = nextIndex;
        root.incomingLabel = root.labelAt(nextIndex);
        if (Config.options.reminders.notify)
            Notifications.notify("Reminder", root.labelAt(nextIndex), {
                "urgency": "low",
                "timeout": 5000,
                "replaceId": 9931
            });
        rotateAnimation.restart();
    }

    TextMetrics {
        id: currentLabelMetrics

        font: currentLabelText.font
        text: root.currentLabel
    }

    TextMetrics {
        id: incomingLabelMetrics

        font: incomingLabelText.font
        text: root.incomingLabel
    }

    Connections {
        target: Reminders
        function onActiveRemindersChanged() {
            root.resetLabel();
        }
    }

    Timer {
        interval: Config.options.reminders.rotateDelay
        running: root.activeCount > 1
        repeat: true
        onTriggered: root.rotate()
    }

    SequentialAnimation {
        id: rotateAnimation

        PropertyAction {
            target: currentLabelText
            property: "y"
            value: 0
        }

        PropertyAction {
            target: incomingLabelText
            property: "y"
            value: -labelViewport.height
        }

        ParallelAnimation {
            NumberAnimation {
                target: currentLabelText
                property: "y"
                to: labelViewport.height
                duration: 260
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: incomingLabelText
                property: "y"
                to: 0
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                root.currentLabel = root.incomingLabel;
                root.incomingLabel = "";
                currentLabelText.y = 0;
                incomingLabelText.y = -labelViewport.height;
            }
        }
    }

    Rectangle {
        id: frame

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: root.labelWidth + 20
        implicitHeight: labelViewport.height + 8
        color: "transparent"

        Item {
            id: labelViewport

            anchors.centerIn: parent
            width: root.labelWidth
            height: Math.max(currentLabelText.implicitHeight, incomingLabelText.implicitHeight)
            clip: true

            StyledText {
                id: currentLabelText

                x: 0
                y: 0
                width: parent.width
                height: parent.height
                text: root.currentLabel
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Appearance.m3colors.m3primaryText
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }

            StyledText {
                id: incomingLabelText

                x: 0
                y: -labelViewport.height
                width: parent.width
                height: parent.height
                text: root.incomingLabel
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Appearance.m3colors.m3primaryText
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Component.onCompleted: {
        Tasks.fetchTodos();
        root.resetLabel();
    }
}
