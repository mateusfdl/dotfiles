pragma Singleton
pragma ComponentBehavior: Bound
import "." as Topbar
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QsUtils

Scope {
    id: volumePopupScope

    property bool popupVisible: false
    property real popupX: 0
    property real popupY: 0
    property bool devicePickerExpanded: false

    function showPopup(x, y) {
        popupX = x;
        popupY = y;
        popupVisible = true;
    }

    function hidePopup() {
        popupVisible = false;
        devicePickerExpanded = false;
    }

    function togglePopup(x, y) {
        if (popupVisible) {
            hidePopup();
        } else {
            Topbar.PopupManager.closeAllExcept("volume");
            showPopup(x, y);
        }
    }

    property bool protectionTriggered: false
    property string protectionReason: ""

    Connections {
        target: Audio
        function onSinkProtectionTriggered(reason) {
            volumePopupScope.protectionTriggered = true;
            volumePopupScope.protectionReason = reason;
            protectionResetTimer.restart();
        }
        function onSinksChanged() {
            if (Audio.sinks.length === 0)
                volumePopupScope.devicePickerExpanded = false;
        }
    }

    Timer {
        id: protectionResetTimer
        interval: 2000
        onTriggered: {
            volumePopupScope.protectionTriggered = false;
        }
    }

    Variants {
        model: Quickshell.screens

        FocusedMonitorPanel {
            id: popup

            requestVisible: volumePopupScope.popupVisible

            WlrLayershell.namespace: "quickshell:volume"
            WlrLayershell.layer: WlrLayer.Overlay

            HyprlandWindow.visibleMask: Region {
                item: popup.isActive ? popupBackground : null
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                enabled: popup.isActive
                onClicked: {
                    volumePopupScope.hidePopup();
                }
            }

            Rectangle {
                id: popupBackground

                x: volumePopupScope.popupX
                y: volumePopupScope.popupY
                width: 280
                height: 112 + (volumePopupScope.protectionTriggered ? 36 : 0) + (volumePopupScope.devicePickerExpanded ? Math.min(deviceListView.contentHeight + 4, 180) + 12 : 0)
                radius: 12
                color: Qt.rgba(0.08, 0.08, 0.09, 0.78)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                z: 10
                layer.enabled: true

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        mouse.accepted = true;
                    }
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Protection warning (only shown when triggered)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 6
                        color: Qt.rgba(1, 0.6, 0, 0.15)
                        border.color: Qt.rgba(1, 0.6, 0, 0.4)
                        border.width: 1
                        visible: volumePopupScope.protectionTriggered

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "warning"
                                iconSize: 14
                                fill: 1
                                color: Qt.rgba(1, 0.7, 0, 1)
                            }

                            StyledText {
                                text: "Volume protection active"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Qt.rgba(1, 0.8, 0.4, 1)
                            }
                        }
                    }

                    // Main content
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Volume slider row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                RippleButton {
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                    buttonRadius: 8
                                    onClicked: {
                                        if (Audio.sink?.audio) {
                                            Audio.sink.audio.muted = !Audio.sink.audio.muted;
                                        }
                                    }

                                    contentItem: MaterialSymbol {
                                        id: volumeIcon

                                        text: {
                                            if (Audio.sink?.audio?.muted ?? false)
                                                return "volume_off";

                                            const volume = (Audio.sink?.audio?.volume ?? 0) * 100;
                                            if (volume >= 70)
                                                return "volume_up";

                                            if (volume >= 30)
                                                return "volume_down";

                                            if (volume > 0)
                                                return "volume_mute";

                                            return "volume_off";
                                        }
                                        iconSize: 24
                                        fill: 1
                                        color: Audio.sink?.audio?.muted ? Appearance.m3colors.m3secondaryText : Appearance.m3colors.m3primaryText
                                    }
                                }

                                StyledSlider {
                                    id: volumeSlider

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    from: 0
                                    to: 1
                                    value: Audio.sink?.audio?.volume ?? 0
                                    onMoved: {
                                        if (Audio.sink?.audio) {
                                            Audio.sink.audio.volume = value;
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.preferredWidth: 36
                                    text: Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Appearance.m3colors.m3primaryText
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            // Output device picker
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 8
                                color: devicePickerMouseArea.containsMouse ? Style.withAlpha(Appearance.m3colors.m3primaryText, 0.08) : Style.withAlpha(Appearance.m3colors.m3primaryText, 0.04)
                                opacity: Audio.sinks.length > 0 ? 1 : 0.6

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    MaterialSymbol {
                                        text: "speaker"
                                        iconSize: 16
                                        fill: 1
                                        color: Appearance.m3colors.m3secondaryText
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Audio.sinkName
                                        font.family: Style.font.family.uiFont
                                        font.pixelSize: Style.font.pixelSize.textSmall
                                        font.weight: Font.Medium
                                        color: Appearance.m3colors.m3primaryText
                                        elide: Text.ElideRight
                                    }

                                    MaterialSymbol {
                                        text: volumePopupScope.devicePickerExpanded ? "expand_less" : "expand_more"
                                        iconSize: 16
                                        color: Appearance.m3colors.m3secondaryText
                                    }
                                }

                                MouseArea {
                                    id: devicePickerMouseArea

                                    anchors.fill: parent
                                    enabled: Audio.sinks.length > 0
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        volumePopupScope.devicePickerExpanded = !volumePopupScope.devicePickerExpanded;
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(deviceListView.contentHeight + 4, 180)
                                radius: 8
                                color: Appearance.colors.colLayer2
                                border.color: Appearance.m3colors.m3borderSecondary
                                border.width: 1
                                visible: volumePopupScope.devicePickerExpanded
                                clip: true

                                ListView {
                                    id: deviceListView

                                    anchors.fill: parent
                                    anchors.margins: 2
                                    spacing: 1
                                    model: ScriptModel {
                                        values: [...Audio.sinks]
                                    }

                                    delegate: Rectangle {
                                        id: deviceOption

                                        required property var modelData
                                        readonly property bool selected: deviceOption.modelData === Audio.sink

                                        width: deviceListView.width
                                        height: Style.font.pixelSize.textSmall + 20
                                        radius: Appearance.rounding.small
                                        color: {
                                            if (deviceOption.selected)
                                                return Appearance.m3colors.m3selectionBackground;

                                            if (deviceOptionMouseArea.containsMouse)
                                                return Style.withAlpha(Appearance.m3colors.m3primaryText, 0.06);

                                            return "transparent";
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            MaterialSymbol {
                                                Layout.preferredWidth: Style.font.pixelSize.textSmall
                                                text: "check"
                                                iconSize: Style.font.pixelSize.textSmall
                                                fill: 1
                                                color: deviceOption.selected ? Appearance.m3colors.m3selectionText : "transparent"
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: Audio.displayName(deviceOption.modelData)
                                                font.family: Style.font.family.uiFont
                                                font.pixelSize: Style.font.pixelSize.textSmall
                                                font.weight: Font.Medium
                                                color: deviceOption.selected ? Appearance.m3colors.m3selectionText : Appearance.m3colors.m3primaryText
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                                wrapMode: Text.NoWrap
                                            }
                                        }

                                        MouseArea {
                                            id: deviceOptionMouseArea

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Audio.setDefaultSink(deviceOption.modelData);
                                                volumePopupScope.devicePickerExpanded = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                layer.effect: DropShadow {
                    radius: 24
                    samples: 49
                    color: Qt.rgba(0, 0, 0, 0.6)
                    verticalOffset: 6
                    horizontalOffset: 0
                }
            }
        }
    }
}
