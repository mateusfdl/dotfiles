//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import "./modules/common/"
import "./modules/overview/"
import "./modules/topbar/"
import "./modules/windowswitcher/"
import "./services/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ShellRoot {
    // Enable/disable modules here. False = not loaded at all, so rest assured
    // no unnecessary stuff will take up memory if you decide to only use, say, the overview.
    property bool enableTopbar: true
    property bool enableOverview: true
    property bool enableWindowSwitcher: true

    // Force initialization of some singletons
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme();
        ConfigLoader.loadConfig();
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

}
