import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QsUtils
import qs.modules.common

ToolTip {
    id: root
    property string content
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false
    property bool internalVisibleCondition: {
        const ans = (extraVisibleCondition && (parent.hovered === undefined || parent?.hovered)) || alternativeVisibleCondition;
        return ans;
    }
    verticalPadding: 5
    horizontalPadding: 10
    opacity: internalVisibleCondition ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    background: null

    contentItem: Item {
        id: contentItemBackground
        implicitWidth: tooltipTextObject.width + 2 * root.horizontalPadding
        implicitHeight: tooltipTextObject.height + 2 * root.verticalPadding

        Rectangle {
            id: backgroundRectangle
            anchors.bottom: contentItemBackground.bottom
            anchors.horizontalCenter: contentItemBackground.horizontalCenter
            color: Appearance.m3colors.colTooltip
            radius: Appearance.rounding.verysmall
            width: internalVisibleCondition ? (tooltipTextObject.width + 2 * padding) : 0
            height: internalVisibleCondition ? (tooltipTextObject.height + 2 * padding) : 0
            clip: true

            Behavior on width {
                animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on height {
                animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            StyledText {
                id: tooltipTextObject
                anchors.centerIn: parent
                text: content
                font.pixelSize: Style.font.pixelSize.textSmall
                font.hintingPreference: Font.PreferNoHinting // Prevent shaky text
                color: Appearance.m3colors.colOnTooltip
                wrapMode: Text.Wrap
            }
        }
    }
}
