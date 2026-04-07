pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root

    required property real maxHeight
    required property TextField search
    required property int padding

    readonly property bool hasSearchText: search.text.length > 0
    readonly property Item currentList: hasSearchText ? appList.item : defaultList.item

    // Stabilized selectedApp with fallback caching
    property var _lastSelectedApp: null
    readonly property var selectedApp: {
        const app = hasSearchText ? appList.item?.selectedApp : defaultList.item?.selectedApp;
        if (app) {
            _lastSelectedApp = app;
            return app;
        }
        return _lastSelectedApp;
    }

    anchors.horizontalCenter: parent.horizontalCenter
    clip: true
    implicitWidth: parent.width
    implicitHeight: hasSearchText ? (appList.item?.implicitHeight ?? 0) : (defaultList.item?.implicitHeight ?? 0)

    Loader {
        id: appList
        active: root.hasSearchText
        visible: active
        anchors.fill: parent
        sourceComponent: AppListSimple {
            search: root.search
        }
    }

    Loader {
        id: defaultList
        active: !root.hasSearchText
        visible: active
        anchors.fill: parent
        sourceComponent: DefaultAppList {
            maxHeight: root.maxHeight
            padding: root.padding
        }
    }
}
