import QtQuick

Text {
    id: root

    property string icon: ""
    property real size: 16
    property bool active: true

    text: icon
    color: active ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.4)
    font.pixelSize: size
    font.family: "FiraConde Nerd Font"
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering

    Behavior on color {
        ColorAnimation {
            duration: 200
        }

    }

}
