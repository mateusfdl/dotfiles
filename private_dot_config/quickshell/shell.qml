//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.overview
import qs.modules.theme
import qs.modules.topbar
import qs.modules.wallpaper
import qs.modules.windowswitcher
import qs.services

ShellRoot {
    property bool enableTopbar: true
    property bool enableOverview: true
    property bool enableWindowSwitcher: true
    property bool enableLauncher: true
    property bool enableWallpaper: true
    property bool enableNotifications: true

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
    }

    ThemeIpc {
    }

    Loader {
        active: enableTopbar

        sourceComponent: Topbar {
        }

    }

    Loader {
        active: enableOverview

        sourceComponent: Overview {
        }

    }

    Loader {
        active: enableWindowSwitcher

        sourceComponent: WindowSwitcher {
        }

    }

    Loader {
        active: enableLauncher

        sourceComponent: Launcher {
        }

    }

    Loader {
        active: enableWallpaper

        sourceComponent: Wallpaper {
        }

    }

    Loader {
        active: enableNotifications

        sourceComponent: NotificationPopup {
        }

    }

}
