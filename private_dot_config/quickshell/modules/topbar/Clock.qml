import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string format: "ddd MMM dd  hh:mm"

    implicitWidth: clockText.implicitWidth + 8
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText

        anchors.centerIn: parent
        text: Qt.formatDateTime(new Date(), root.format)
        color: Qt.rgba(1, 1, 1, 0.9)
        font.pixelSize: 16
        font.weight: Font.Medium
        font.family: "-apple-system"
        verticalAlignment: Text.AlignVCenter

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                clockText.text = Qt.formatDateTime(new Date(), root.format);
            }
        }

    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        color: "transparent"
        radius: 4
        z: -1

        Behavior on color {
            ColorAnimation {
                duration: 200
            }

        }

    }

}
