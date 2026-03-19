import QtQuick
import QtQuick.Layouts
import qs.modules.common

Item {
    id: root

    property var values: []
    property int barCount: 6
    property real barWidth: 3
    property real barSpacing: 2
    property real barRadius: 1.5
    property real minBarHeight: 2
    property real maxBarHeight: height
    property color barColor: Appearance.m3colors.m3primary
    property color barColorActive: Qt.rgba(1, 0.6, 0.8, 0.95)
    property bool active: true
    property int animationDuration: 120

    implicitWidth: barCount * barWidth + (barCount - 1) * barSpacing
    implicitHeight: 20

    Row {
        id: barRow

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar

                required property int index

                readonly property real barValue: {
                    if (!root.active || root.values.length === 0)
                        return 0.0;
                    // Map barCount indices into the values array
                    var valIdx = Math.floor(index * root.values.length / root.barCount);
                    valIdx = Math.min(valIdx, root.values.length - 1);
                    return root.values[valIdx] || 0.0;
                }

                width: root.barWidth
                height: Math.max(root.minBarHeight, barValue * root.maxBarHeight)
                radius: root.barRadius
                color: root.active && barValue > 0.05 ? root.barColorActive : root.barColor
                anchors.bottom: parent.bottom

                Behavior on height {
                    NumberAnimation {
                        duration: root.animationDuration
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: root.animationDuration
                    }
                }
            }
        }
    }
}
