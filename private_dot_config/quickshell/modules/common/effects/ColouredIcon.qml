pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

IconImage {
    id: root

    required property color colour
    property color sourceColor: Qt.hsla(0, 0, 0.5, 1.0)

    asynchronous: true

    layer.enabled: true
    layer.effect: Colouriser {
        sourceColor: root.sourceColor
        colorizationColor: root.colour
    }
}
