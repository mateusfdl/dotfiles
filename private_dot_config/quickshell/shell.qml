//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.overview
import qs.modules.theme
import qs.modules.topbar
import qs.modules.wallpaper
import qs.modules.windowswitcher
import qs.modules.aichat
import qs.modules.cheatsheet
import qs.modules.lockscreen
import qs.services

ShellRoot {
    property bool enableTopbar: Config.options.modules.topbar
    property bool enableOverview: Config.options.modules.overview
    property bool enableWindowSwitcher: Config.options.modules.windowSwitcher
    property bool enableLauncher: Config.options.modules.launcher
    property bool enableWallpaper: Config.options.modules.wallpaper
    property bool enableNotifications: Config.options.modules.notifications
    property bool enableAiChat: Config.options.modules.aiChat
    property bool enableCheatsheet: Config.options.modules.cheatsheet
    property bool enableLockScreen: Config.options.modules.lockScreen

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

    Loader {
        active: enableAiChat

        sourceComponent: AiChat {
        }

    }

    Loader {
        active: enableCheatsheet

        sourceComponent: Cheatsheet {
        }

    }

    Loader {
        active: enableLockScreen

        sourceComponent: LockScreen {
        }

    }

    Loader {
        active: enableTopbar

        sourceComponent: PomodoroBreakOverlay {
        }

    }

}
