pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.effects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import QsUtils

FocusScope {
    id: root

    signal closeRequested()

    property bool isOpen: false
    readonly property string fontFamily: "IosevkaSS04 Nerd Font Mono"

    implicitHeight: outerColumn.implicitHeight + 64

    property list<string> selectedTags: []
    property bool tagMode: false

    readonly property var preparedTags: {
        const tags = ObsidianTodo.tags;
        let result = [];
        for (let i = 0; i < tags.length; ++i) {
            result.push({
                name: FuzzySort.prepare(tags[i]),
                tag: tags[i]
            });
        }
        return result;
    }

    function addTag(tag: string) {
        if (tag.length === 0) return;
        if (root.selectedTags.indexOf(tag) !== -1) return;
        root.selectedTags = root.selectedTags.concat([tag]);
        tagInput.text = "";
    }

    function removeLastTag() {
        if (root.selectedTags.length === 0) return;
        root.selectedTags = root.selectedTags.slice(0, root.selectedTags.length - 1);
    }

    function resolveAndAddTag() {
        const query = tagInput.text.trim();
        if (query.length === 0) return;
        const fuzzy = FuzzySort.go(query, root.preparedTags, {
            key: "name",
            limit: 1
        });
        if (fuzzy.length > 0)
            root.addTag(fuzzy[0].obj.tag);
        else
            root.addTag(query);
    }

    function save() {
        const desc = descriptionInput.text.trim();
        if (desc.length === 0) {
            root.closeRequested();
            return;
        }
        ObsidianTodo.saveTodo(desc, root.selectedTags);
    }

    function resetState() {
        descriptionInput.text = "";
        tagInput.text = "";
        root.selectedTags = [];
        root.tagMode = false;
        focusTimer.restart();
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: descriptionInput.forceActiveFocus()
    }

    onIsOpenChanged: {
        if (isOpen) {
            resetState();
        } else {
            descriptionInput.focus = false;
            tagInput.focus = false;
            root.focus = false;
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Tab) {
            if (!root.tagMode) {
                root.tagMode = true;
                tagInput.forceActiveFocus();
            } else if (tagInput.text.trim().length > 0) {
                root.resolveAndAddTag();
            } else {
                root.tagMode = false;
                descriptionInput.forceActiveFocus();
            }
            event.accepted = true;
            return;
        }

        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            root.save();
            event.accepted = true;
            return;
        }

        if (root.tagMode && event.key === Qt.Key_Backspace && tagInput.text.length === 0) {
            root.removeLastTag();
            event.accepted = true;
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

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 18
            spacing: 14

            Text {
                text: "\uf0c8"
                font.family: root.fontFamily
                font.pixelSize: 28
                color: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
                renderType: Text.NativeRendering
            }

            Text {
                text: "New TODO"
                font.family: root.fontFamily
                font.pixelSize: 26
                font.weight: Font.DemiBold
                color: Appearance.m3colors?.m3primaryText ?? "#c0caf5"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }
        }

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

        TextInput {
            id: descriptionInput
            Layout.fillWidth: true
            Layout.topMargin: 20
            Layout.minimumHeight: 52

            font.family: root.fontFamily
            font.pixelSize: 20
            color: Appearance.m3colors?.m3primaryText ?? "#c0caf5"
            selectionColor: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
            selectedTextColor: Appearance.m3colors?.m3windowBackground ?? "#1a1b26"
            renderType: Text.NativeRendering
            clip: true

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: "What needs to be done?"
                font: descriptionInput.font
                color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                visible: descriptionInput.text.length === 0 && !descriptionInput.activeFocus
                renderType: Text.NativeRendering
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 16
            height: 1
            color: Appearance.m3colors?.m3borderSecondary ?? "#292e42"
            opacity: 0.4
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 18
            spacing: 10

            Text {
                text: "Tags:"
                font.family: root.fontFamily
                font.pixelSize: 16
                color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                renderType: Text.NativeRendering
                Layout.alignment: Qt.AlignVCenter
            }

            Row {
                id: tagRow
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: root.selectedTags

                    Rectangle {
                        id: tagChip
                        required property string modelData
                        required property int index

                        width: chipText.implicitWidth + 28
                        height: 34
                        radius: 17
                        color: Colors.transparentize(
                            Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7", 0.8
                        )

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: "#" + tagChip.modelData
                            font.family: root.fontFamily
                            font.pixelSize: 16
                            color: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedTags = root.selectedTags.filter(
                                    (t, i) => i !== tagChip.index
                                );
                            }
                        }
                    }
                }

                TextInput {
                    id: tagInput
                    width: Math.max(80, tagRow.parent.width - tagChipsWidth())
                    height: 34
                    verticalAlignment: TextInput.AlignVCenter

                    font.family: root.fontFamily
                    font.pixelSize: 16
                    color: Appearance.m3colors?.m3primaryText ?? "#c0caf5"
                    renderType: Text.NativeRendering

                    function tagChipsWidth() {
                        let w = 0;
                        for (let i = 0; i < tagRow.children.length - 1; ++i) {
                            const child = tagRow.children[i];
                            if (child && child.width)
                                w += child.width + tagRow.spacing;
                        }
                        return w;
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        verticalAlignment: Text.AlignVCenter
                        text: "Add tag..."
                        font: tagInput.font
                        color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                        visible: tagInput.text.length === 0 && !tagInput.activeFocus
                        renderType: Text.NativeRendering
                    }
                }
            }
        }


    }
}
