import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: sysTrayMenuScope

    required property QsMenuHandle trayItemMenuHandle
    required property var trayItem
    property bool menuVisible: false
    property real menuX: 0
    property real menuY: 0
    property real iconRightX: 0

    signal menuClosed()
    signal menuOpened(var qsWindow)

    function openAt(iconRightX, popupY) {
        sysTrayMenuScope.iconRightX = iconRightX;
        menuY = popupY;
        menuVisible = true;
        sysTrayMenuScope.menuOpened(sysTrayMenuScope);
        Topbar.PopupManager.activeSysTrayMenu = sysTrayMenuScope;
    }

    function close() {
        menuVisible = false;
        while (stackView.depth > 1)stackView.pop()
        sysTrayMenuScope.menuClosed();
        if (Topbar.PopupManager.activeSysTrayMenu === sysTrayMenuScope)
            Topbar.PopupManager.activeSysTrayMenu = null;

    }

    PanelWindow {
        id: popup

        screen: trayItem.QsWindow.window.screen
        visible: sysTrayMenuScope.menuVisible
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        MouseArea {
            anchors.fill: parent
            z: 0
            enabled: sysTrayMenuScope.menuVisible
            onClicked: {
                sysTrayMenuScope.close();
            }
        }

        Rectangle {
            id: popupBackground

            x: sysTrayMenuScope.iconRightX - width
            y: sysTrayMenuScope.menuVisible ? sysTrayMenuScope.menuY : -1000
            width: stackView.implicitWidth + 16
            height: stackView.implicitHeight + 16
            radius: 16
            color: Appearance.colors.colLayer1
            border.color: Appearance.m3colors.m3borderSecondary
            border.width: 1
            z: 10
            layer.enabled: true
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.BackButton | Qt.RightButton
                onPressed: (event) => {
                    if ((event.button === Qt.BackButton || event.button === Qt.RightButton) && stackView.depth > 1)
                        stackView.pop();
                    else
                        event.accepted = true;
                }
                z: -1
            }

            StackView {
                id: stackView

                implicitWidth: currentItem ? currentItem.implicitWidth : 250
                implicitHeight: currentItem ? currentItem.implicitHeight : 100

                anchors {
                    fill: parent
                    margins: 8
                }

                pushEnter: NoAnim {
                }

                pushExit: NoAnim {
                }

                popEnter: NoAnim {
                }

                popExit: NoAnim {
                }

                initialItem: SubMenu {
                    handle: sysTrayMenuScope.trayItemMenuHandle
                }

            }

            Behavior on y {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }

            }

            layer.effect: DropShadow {
                radius: 32
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.7)
                verticalOffset: 8
                horizontalOffset: 0
            }

        }

    }

    Component {
        id: subMenuComponent

        SubMenu {
        }

    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }

    }

    component SubMenu: ColumnLayout {
        id: submenu

        required property QsMenuHandle handle
        property bool isSubMenu: false
        property bool shown: false

        opacity: shown ? 1 : 0
        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()
        spacing: 0

        QsMenuOpener {
            id: menuOpener

            menu: submenu.handle
        }

        Loader {
            Layout.fillWidth: true
            visible: submenu.isSubMenu
            active: visible

            sourceComponent: RippleButton {
                id: backButton

                buttonRadius: 12
                horizontalPadding: 12
                implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
                implicitHeight: 36
                releaseAction: () => {
                    return stackView.pop();
                }

                contentItem: RowLayout {
                    spacing: 8

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: backButton.horizontalPadding
                        rightMargin: backButton.horizontalPadding
                    }

                    MaterialSymbol {
                        iconSize: 20
                        text: "chevron_left"
                        color: Appearance.m3colors.m3primaryText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Back"
                        font.pixelSize: Appearance.font.pixelSize.textSmall
                        color: Appearance.m3colors.m3primaryText
                    }

                }

            }

        }

        Repeater {
            id: menuEntriesRepeater

            property bool iconColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].icon.length > 0)
                        return true;

                }
                return false;
            }
            property bool specialInteractionColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].buttonType !== QsMenuButtonType.None)
                        return true;

                }
                return false;
            }

            model: menuOpener.children

            delegate: Topbar.SysTrayMenuEntry {
                required property QsMenuEntry modelData

                forceIconColumn: menuEntriesRepeater.iconColumnNeeded
                forceSpecialInteractionColumn: menuEntriesRepeater.specialInteractionColumnNeeded
                menuEntry: modelData
                buttonRadius: 12
                onDismiss: sysTrayMenuScope.close()
                onOpenSubmenu: (handle) => {
                    stackView.push(subMenuComponent.createObject(null, {
                        "handle": handle,
                        "isSubMenu": true
                    }));
                }
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.OutCubic
            }

        }

    }

}
