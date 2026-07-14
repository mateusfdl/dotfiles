pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import QtQuick.Controls
import QsUtils

GridView {
    id: root

    required property TextField search
    property string category: ""
    readonly property bool hasSearchText: search.text.length > 0
    readonly property int columns: Config.options.launcher.grid.columns

    model: hasSearchText ? AppSearch.search(search.text).slice(0, Config.options.launcher.grid.searchMaxShown) : (category.length > 0 ? AppSearch.applications.filter(a => a.category === category) : AppSearch.applications)

    cellWidth: Math.floor(width / columns)
    cellHeight: Config.options.launcher.grid.tileHeight

    readonly property int rows: Math.ceil(count / columns)
    implicitHeight: rows * cellHeight

    clip: true
    focus: true
    currentIndex: 0
    keyNavigationWraps: false
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds
    cacheBuffer: cellHeight * 4

    onModelChanged: currentIndex = count > 0 ? 0 : -1
    onCountChanged: {
        if (currentIndex >= count)
            currentIndex = count - 1;
    }

    highlightFollowsCurrentItem: true
    highlightMoveDuration: Style.animation.elementMoveFast.duration
    highlight: Rectangle {
        width: root.cellWidth
        height: root.cellHeight
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2Hover
        border.width: 1
        border.color: Style.withAlpha(Appearance.colors.colOnLayer2, 0.06)
    }

    populate: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 220
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "scale"
            from: 0.86
            to: 1.0
            duration: 260
            easing.type: Easing.OutBack
        }
    }

    delegate: AppTile {}
}
