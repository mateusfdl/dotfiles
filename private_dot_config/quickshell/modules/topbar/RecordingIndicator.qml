import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    implicitWidth: recordingRect.implicitWidth
    implicitHeight: recordingRect.implicitHeight

    // Pulsing animation for the recording indicator
    SequentialAnimation {
        running: ScreenRecorder.isRecording
        loops: Animation.Infinite

        NumberAnimation {
            target: recordingCircle
            property: "opacity"
            from: 1.0
            to: 0.3
            duration: 800
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: recordingCircle
            property: "opacity"
            from: 0.3
            to: 1.0
            duration: 800
            easing.type: Easing.InOutSine
        }
    }

    Rectangle {
        id: recordingRect

        implicitWidth: ScreenRecorder.isRecording ? 28 : 0
        implicitHeight: 28
        radius: 14
        color: Qt.rgba(0, 0, 0, 0.2)
        visible: ScreenRecorder.isRecording
        opacity: ScreenRecorder.isRecording ? 1 : 0

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: recordingCircle

            anchors.centerIn: parent
            width: 12
            height: 12
            radius: 6
            color: Qt.rgba(1, 0.2, 0.2, 1)  // Red color
        }
    }
}
