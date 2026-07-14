pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QsUtils

Flow {
    id: root

    property string selected: ""
    readonly property var order: ["Developer Tools", "Productivity & Finance", "Utilities", "Entertainment", "Creativity", "Social", "Other"]
    readonly property var present: order.filter(c => AppSearch.applications.some(a => a.category === c))

    spacing: 8

    Repeater {
        model: root.present

        delegate: Rectangle {
            id: chip

            required property string modelData
            readonly property bool active: root.selected === modelData

            implicitWidth: label.implicitWidth + 28
            implicitHeight: label.implicitHeight + 14
            radius: Appearance.rounding.full
            color: chip.active ? Appearance.colors.colLayer2Active : (chipHover.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)

            Behavior on color {
                ColorAnimation {
                    duration: Style.animation.elementMoveFast.duration
                }
            }

            StyledText {
                id: label
                anchors.centerIn: parent
                text: chip.modelData
                color: Appearance.m3colors.m3primaryText
                font.family: Style.font.family.uiFont
                font.pixelSize: Style.font.pixelSize.textBase
                font.weight: chip.active ? Font.DemiBold : Font.Normal
            }

            HoverHandler {
                id: chipHover
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: root.selected = (root.selected === chip.modelData ? "" : chip.modelData)
            }
        }
    }
}
