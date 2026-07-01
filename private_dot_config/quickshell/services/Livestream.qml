pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell

Singleton {
    id: root

    readonly property bool active: root.monitor.length > 0
    property string monitor: ""

    function enable(monitorName) {
        root.monitor = monitorName;
    }

    function disable() {
        root.monitor = "";
    }

    function toggle(monitorName) {
        if (root.monitor === monitorName)
            root.disable();
        else
            root.enable(monitorName);
    }
}
