//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import QtQuick.Controls
import Quickshell
import qs
import qs.modules.common
import qs.modules.testwindow
import qs.services

ShellRoot {
    Component.onCompleted: {
        console.log("Config ready:", Config.ready);
        console.log("Persistent ready:", Persistent.ready);
        console.log("Launcher test starting...");
    }

    TestWindow {
    }

}
