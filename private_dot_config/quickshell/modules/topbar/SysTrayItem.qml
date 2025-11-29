import "." as Topbar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.modules.common
import qs.modules.common.widgets

MouseArea {
    id: root

    required property SystemTrayItem item

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    implicitWidth: Config.options.bar.tray.itemSize
    implicitHeight: Config.options.bar.tray.itemSize
    onPressed: (event) => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu) {
                Topbar.PopupManager.closeSysTrayMenu();
                Topbar.PopupManager.closeAllExcept("systray");
                var pos = mapToItem(null, 0, 0);
                var iconRightX = pos.x + root.width;
                menu.openAt(iconRightX, 2);
            }
            break;
        case Qt.MiddleButton:
            item.secondaryActivate();
            break;
        }
        event.accepted = true;
    }
    onWheel: (wheel) => {
        item.scroll(wheel.angleDelta.y, "vertical");
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

    Image {
        id: trayIcon

        anchors.centerIn: parent
        width: Config.options.bar.tray.iconSize
        height: Config.options.bar.tray.iconSize
        source: root.item.icon || ""
        cache: false
        smooth: true
        mipmap: true

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
            }

        }

    }

    Loader {
        id: menu

        function openAt(iconRightX, popupY) {
            menu.active = true;
            if (menu.item)
                menu.item.openAt(iconRightX, popupY);

        }

        active: false

        sourceComponent: Topbar.SysTrayMenu {
            trayItemMenuHandle: root.item.menu
            trayItem: root
            onMenuClosed: {
                menu.active = false;
            }
        }

    }

}
