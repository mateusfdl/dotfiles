pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import QsUtils

Item {
    id: root

    required property var modelData
    required property int index

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    function launchAndClose(): void {
        AppSearch.launch(root.modelData);
        GlobalStates.launcherOpen = false;
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered)
                root.GridView.view.currentIndex = root.index;
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.launchAndClose()
    }

    Column {
        anchors.centerIn: parent
        spacing: 8
        width: parent.width

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Config.options.launcher.grid.iconSize
            height: width

            scale: hover.hovered ? 1.06 : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: Style.animation.elementMoveFast.duration
                    easing.type: Easing.OutBack
                }
            }

            IconImage {
                id: icon
                anchors.fill: parent
                source: Quickshell.iconPath(root.modelData.icon, "image-missing")
                asynchronous: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: icon.width
                        height: icon.height
                        radius: icon.width * 0.2237
                    }
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 12
            horizontalAlignment: Text.AlignHCenter
            text: root.modelData.name
            color: Appearance.m3colors.m3primaryText
            font.family: Style.font.family.uiFont
            font.pixelSize: Style.font.pixelSize.textSmall
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
