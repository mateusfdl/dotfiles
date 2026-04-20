pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import QsUtils

FocusScope {
    id: root

    signal closeRequested

    property bool isOpen: false
    property int currentIndex: 0
    readonly property string fontFamily: "IosevkaSS04 Nerd Font Mono"
    readonly property int todoCount: ObsidianTodo.todos.length

    implicitHeight: outerColumn.implicitHeight + 64

    Item {
        id: focusAnchor
        focus: true
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: focusAnchor.forceActiveFocus()
    }

    function clampIndex() {
        if (root.todoCount === 0) {
            root.currentIndex = 0;
        } else if (root.currentIndex >= root.todoCount) {
            root.currentIndex = root.todoCount - 1;
        }
    }

    function setStatus(marker: string) {
        if (root.todoCount === 0) return;
        const idx = root.currentIndex;
        ObsidianTodo.setTodoStatus(idx, marker);
    }

    function iconForStatus(s: string): string {
        switch (s) {
            case "x": return "\uf14a";
            case "/": return "\uf017";
            case ">": return "\uf061";
            case "-": return "\uf057";
            case "?": return "\uf128";
            case "!": return "\uf12a";
            case " ":
            default:  return "\uf096";
        }
    }

    onTodoCountChanged: clampIndex()

    onIsOpenChanged: {
        if (isOpen) {
            root.currentIndex = 0;
            ObsidianTodo.fetchTodos();
            focusTimer.restart();
        } else {
            focusAnchor.focus = false;
            root.focus = false;
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_R || event.key === Qt.Key_F5) {
            ObsidianTodo.fetchTodos();
            event.accepted = true;
            return;
        }

        // vim navigation
        if (event.key === Qt.Key_J) {
            if (root.currentIndex < root.todoCount - 1)
                root.currentIndex++;
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_K) {
            if (root.currentIndex > 0)
                root.currentIndex--;
            event.accepted = true;
            return;
        }

        // status keybinds
        if (event.key === Qt.Key_D) {
            root.setStatus("x");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_P) {
            root.setStatus("/");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_N) {
            root.setStatus(">");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_U) {
            root.setStatus("-");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Question) {
            root.setStatus("?");
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Exclam) {
            root.setStatus("!");
            event.accepted = true;
            return;
        }
    }

    ColumnLayout {
        id: outerColumn
        anchors {
            fill: parent
            topMargin: 32
            bottomMargin: 28
            leftMargin: 36
            rightMargin: 36
        }
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 18
            spacing: 14

            Text {
                text: "\uf0ae"
                font.family: root.fontFamily
                font.pixelSize: 28
                color: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
                renderType: Text.NativeRendering
            }

            Text {
                text: "Daily TODOs"
                font.family: root.fontFamily
                font.pixelSize: 26
                font.weight: Font.DemiBold
                color: Appearance.m3colors?.m3primaryText ?? "#c0caf5"
                renderType: Text.NativeRendering
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: Qt.formatDate(new Date(), "ddd, dd/MM")
                font.family: root.fontFamily
                font.pixelSize: 14
                color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                renderType: Text.NativeRendering
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.mix(
                Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7",
                Appearance.m3colors?.m3borderSecondary ?? "#292e42",
                0.3
            )
            opacity: 0.5
        }

        // Todo list
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.fillHeight: false
            implicitHeight: Math.max(todoListColumn.implicitHeight, emptyState.visible ? 120 : 0)

            // Empty state
            ColumnLayout {
                id: emptyState
                anchors.centerIn: parent
                spacing: 12
                visible: ObsidianTodo.todos.length === 0

                Text {
                    text: "\uf058"
                    font.family: root.fontFamily
                    font.pixelSize: 40
                    color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                    opacity: 0.4
                    Layout.alignment: Qt.AlignHCenter
                    renderType: Text.NativeRendering
                }

                Text {
                    text: "No tasks for today"
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                    Layout.alignment: Qt.AlignHCenter
                    renderType: Text.NativeRendering
                }
            }

            // Todo items
            ColumnLayout {
                id: todoListColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 4
                visible: ObsidianTodo.todos.length > 0

                Repeater {
                    model: ObsidianTodo.todos

                    Rectangle {
                        id: todoItem

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === root.currentIndex

                        Layout.fillWidth: true
                        implicitHeight: todoRow.implicitHeight + 20
                        radius: 10
                        color: isSelected
                            ? Colors.transparentize(Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7", 0.82)
                            : todoMouseArea.containsMouse
                                ? Colors.transparentize(Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7", 0.92)
                                : "transparent"
                        border.width: isSelected ? 1 : 0
                        border.color: Colors.transparentize(Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7", 0.5)

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            id: todoRow
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 14
                                topMargin: 10
                                bottomMargin: 10
                            }
                            spacing: 14

                            // Checkbox icon
                            Text {
                                readonly property string status: todoItem.modelData.status || " "
                                text: root.iconForStatus(status)
                                font.family: root.fontFamily
                                font.pixelSize: 18
                                color: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
                                opacity: status !== " " ? 1.0 : 0.7
                                renderType: Text.NativeRendering
                                Layout.alignment: Qt.AlignTop
                            }

                            // Description + tags
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: todoItem.modelData.description || ""
                                    font.family: root.fontFamily
                                    font.pixelSize: 16
                                    color: Appearance.m3colors?.m3primaryText ?? "#c0caf5"
                                    wrapMode: Text.WordWrap
                                    renderType: Text.NativeRendering
                                }

                                // Tags row
                                Row {
                                    spacing: 6
                                    visible: todoItem.modelData.tags && todoItem.modelData.tags.length > 0

                                    Repeater {
                                        model: todoItem.modelData.tags || []

                                        Rectangle {
                                            required property var modelData

                                            width: tagText.implicitWidth + 16
                                            height: tagText.implicitHeight + 6
                                            radius: 4
                                            color: Colors.transparentize(
                                                Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7",
                                                0.85
                                            )

                                            Text {
                                                id: tagText
                                                anchors.centerIn: parent
                                                text: "#" + parent.modelData
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                color: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
                                                renderType: Text.NativeRendering
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: todoMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentIndex = todoItem.index;
                            }
                        }
                    }
                }
            }
        }

        // Footer hint
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 16

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "j/k navigate · d done · p pending · n next day · u won't do · r refresh · esc close"
                font.family: root.fontFamily
                font.pixelSize: 11
                color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                opacity: 0.6
                renderType: Text.NativeRendering
            }
        }
    }
}
