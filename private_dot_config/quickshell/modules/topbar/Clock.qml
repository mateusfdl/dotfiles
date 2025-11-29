import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    property string format: Config.options.time.format

    implicitWidth: clockText.implicitWidth + 8
    implicitHeight: clockText.implicitHeight

    Text {
        id: clockText

        anchors.centerIn: parent
        text: Qt.formatDateTime(new Date(), root.format)
        color: Appearance.m3colors.m3primaryText
        font.pixelSize: Appearance.font.pixelSize.textMedium
        font.weight: Font.Medium
        font.family: Appearance.font.family.uiFont
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
        radius: Appearance.rounding.unsharpen
        z: -1

        Behavior on color {
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
            }

        }

    }

}
