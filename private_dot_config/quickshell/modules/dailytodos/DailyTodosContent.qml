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
    property bool noteMode: false
    property var expandedAnnotationIds: ({})
    property int currentIndex: 0
    property string currentTagFilter: ""
    readonly property string fontFamily: "IosevkaSS04 Nerd Font Mono"
    readonly property var availableTags: root.resolveAvailableTags()
    readonly property var filteredTodos: root.resolveFilteredTodos()
    readonly property var currentTodo: root.todoCount > 0 ? root.filteredTodos[root.currentIndex] : ({})
    readonly property int todoCount: root.filteredTodos.length

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

    Timer {
        id: noteFocusTimer
        interval: 50
        repeat: false
        onTriggered: noteInput.forceActiveFocus()
    }

    function openNoteMode() {
        if (root.todoCount === 0)
            return;
        noteInput.text = "";
        root.noteMode = true;
        noteFocusTimer.restart();
    }

    function closeNoteMode() {
        root.noteMode = false;
        noteInput.text = "";
        focusAnchor.forceActiveFocus();
    }

    function submitNote() {
        const text = noteInput.text.trim();
        if (text.length === 0) {
            root.closeNoteMode();
            return;
        }
        Tasks.annotateTodo(root.currentTodo.sourceIndex, text);
        root.closeNoteMode();
    }

    function clampIndex() {
        if (root.todoCount === 0) {
            root.currentIndex = 0;
        } else if (root.currentIndex >= root.todoCount) {
            root.currentIndex = root.todoCount - 1;
        }
    }

    function setStatus(marker: string) {
        if (root.todoCount === 0)
            return;
        Tasks.setTodoStatus(root.currentTodo.sourceIndex, marker);
    }

    function resolveAvailableTags() {
        const tags = [];
        for (let i = 0; i < Tasks.todos.length; ++i) {
            const todoTags = Tasks.todos[i].tags || [];
            for (let j = 0; j < todoTags.length; ++j) {
                const tag = todoTags[j];
                if (tags.indexOf(tag) === -1)
                    tags.push(tag);
            }
        }
        tags.sort();
        return tags;
    }

    function resolveFilteredTodos() {
        if (root.currentTagFilter.length === 0)
            return Tasks.todos;
        const result = [];
        for (let i = 0; i < Tasks.todos.length; ++i) {
            const todo = Tasks.todos[i];
            const tags = todo.tags || [];
            if (tags.indexOf(root.currentTagFilter) !== -1)
                result.push(todo);
        }
        return result;
    }

    function rotateTagFilter() {
        if (root.availableTags.length === 0) {
            root.currentTagFilter = "";
            root.currentIndex = 0;
            return;
        }

        if (root.currentTagFilter.length === 0) {
            root.currentTagFilter = root.availableTags[0];
            root.currentIndex = 0;
            return;
        }

        const currentTagIndex = root.availableTags.indexOf(root.currentTagFilter);
        if (currentTagIndex < 0 || currentTagIndex === root.availableTags.length - 1) {
            root.currentTagFilter = "";
            root.currentIndex = 0;
            return;
        }

        root.currentTagFilter = root.availableTags[currentTagIndex + 1];
        root.currentIndex = 0;
    }

    function currentTodoId() {
        if (root.todoCount === 0)
            return "";
        return root.currentTodo.uuid || "";
    }

    function isAnnotationsVisible(todo) {
        const todoId = todo.uuid || "";
        if (todoId.length === 0)
            return false;
        return root.expandedAnnotationIds[todoId] === true;
    }

    function toggleCurrentAnnotations() {
        const todoId = root.currentTodoId();
        if (todoId.length === 0)
            return;

        const nextExpandedAnnotationIds = Object.assign({}, root.expandedAnnotationIds);
        if (nextExpandedAnnotationIds[todoId] === true)
            delete nextExpandedAnnotationIds[todoId];
        else
            nextExpandedAnnotationIds[todoId] = true;
        root.expandedAnnotationIds = nextExpandedAnnotationIds;
    }

    function iconForStatus(s: string): string {
        switch (s) {
        case "x":
            return "\uf14a";
        case "/":
            return "\uf017";
        case ">":
            return "\uf061";
        case "-":
            return "\uf057";
        case "?":
            return "\uf128";
        case "!":
            return "\uf12a";
        case " ":
        default:
            return "\uf096";
        }
    }

    onTodoCountChanged: clampIndex()
    onCurrentTagFilterChanged: clampIndex()
    onCurrentIndexChanged: todoListView.positionViewAtIndex(root.currentIndex, ListView.Contain)

    onIsOpenChanged: {
        if (isOpen) {
            root.currentIndex = 0;
            root.noteMode = false;
            Tasks.fetchTodos();
            focusTimer.restart();
        } else {
            root.noteMode = false;
            focusAnchor.focus = false;
            root.focus = false;
        }
    }

    Keys.onPressed: event => {
        if (root.noteMode)
            return;

        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_A) {
            root.openNoteMode();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_V) {
            root.toggleCurrentAnnotations();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_T) {
            root.rotateTagFilter();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_R || event.key === Qt.Key_F5) {
            Tasks.fetchTodos();
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
                font.pixelSize: 34
                color: Appearance.m3colors.m3accentPrimary
                renderType: Text.NativeRendering
            }

            Text {
                text: "Daily TODOs"
                font.family: root.fontFamily
                font.pixelSize: 32
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3primaryText
                renderType: Text.NativeRendering
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: Qt.formatDate(new Date(), "ddd, dd/MM")
                font.family: root.fontFamily
                font.pixelSize: 16
                color: Appearance.m3colors.m3secondaryText
                renderType: Text.NativeRendering
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.mix(Appearance.m3colors.m3accentPrimary, Appearance.m3colors.m3borderSecondary, 0.3)
            opacity: 0.5
        }

        Item {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.fillHeight: false
            implicitHeight: root.todoCount === 0 ? 200 : Math.min(todoListView.contentHeight, 640)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: root.todoCount === 0

                Text {
                    text: "\uf058"
                    font.family: root.fontFamily
                    font.pixelSize: 48
                    color: Appearance.m3colors.m3secondaryText
                    opacity: 0.4
                    Layout.alignment: Qt.AlignHCenter
                    renderType: Text.NativeRendering
                }

                Text {
                    text: root.currentTagFilter.length === 0 ? "No tasks" : `No #${root.currentTagFilter} tasks`
                    font.family: root.fontFamily
                    font.pixelSize: 19
                    color: Appearance.m3colors.m3secondaryText
                    Layout.alignment: Qt.AlignHCenter
                    renderType: Text.NativeRendering
                }
            }

            ListView {
                id: todoListView
                anchors.fill: parent
                spacing: 4
                clip: true
                model: root.filteredTodos
                visible: root.todoCount > 0
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                currentIndex: root.currentIndex

                ScrollBar.vertical: ScrollBar {
                    policy: todoListView.contentHeight > todoListView.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                delegate: Rectangle {
                    id: todoItem

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: index === root.currentIndex

                    width: ListView.view.width
                    height: todoRow.implicitHeight + 20
                    radius: 10
                    color: isSelected ? Colors.transparentize(Appearance.m3colors.m3accentPrimary, 0.82) : todoMouseArea.containsMouse ? Colors.transparentize(Appearance.m3colors.m3accentPrimary, 0.92) : "transparent"
                    border.width: isSelected ? 1 : 0
                    border.color: Colors.transparentize(Appearance.m3colors.m3accentPrimary, 0.5)

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
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

                        Text {
                            readonly property string status: todoItem.modelData.status || " "
                            text: root.iconForStatus(status)
                            font.family: root.fontFamily
                            font.pixelSize: 22
                            color: Appearance.m3colors.m3accentPrimary
                            opacity: status !== " " ? 1.0 : 0.7
                            renderType: Text.NativeRendering
                            Layout.alignment: Qt.AlignTop
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: todoItem.modelData.description || ""
                                font.family: root.fontFamily
                                font.pixelSize: 19
                                color: Appearance.m3colors.m3primaryText
                                wrapMode: Text.WordWrap
                                renderType: Text.NativeRendering
                            }

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
                                        color: Colors.transparentize(Appearance.m3colors.m3accentPrimary, 0.85)

                                        Text {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: "#" + parent.modelData
                                            font.family: root.fontFamily
                                            font.pixelSize: 14
                                            color: Appearance.m3colors.m3accentPrimary
                                            renderType: Text.NativeRendering
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: root.isAnnotationsVisible(todoItem.modelData)

                                Repeater {
                                    model: todoItem.modelData.annotations || []

                                    Text {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        text: modelData.description || ""
                                        font.family: root.fontFamily
                                        font.pixelSize: 14
                                        color: Appearance.m3colors.m3secondaryText
                                        wrapMode: Text.WordWrap
                                        renderType: Text.NativeRendering
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

        // Footer hint
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 16

            Text {
                visible: root.currentTagFilter.length > 0
                text: "#" + root.currentTagFilter
                font.family: root.fontFamily
                font.pixelSize: 13
                color: Appearance.m3colors.m3accentPrimary
                opacity: 0.8
                renderType: Text.NativeRendering
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "j/k navigate · t tags · v notes · d done · p pending · n next day · u won't do · a note · r refresh · esc close"
                font.family: root.fontFamily
                font.pixelSize: 13
                color: Appearance.m3colors.m3secondaryText
                opacity: 0.6
                renderType: Text.NativeRendering
            }
        }
    }

    Rectangle {
        id: noteOverlay
        anchors.fill: parent
        visible: root.noteMode
        z: 50
        color: Colors.transparentize(Appearance.m3colors.m3windowBackground, 0.2)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.closeNoteMode()
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 96
            height: noteCard.implicitHeight + 36
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3layerBackground1
            border.width: 1
            border.color: Colors.transparentize(Appearance.m3colors.m3accentPrimary, 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    mouse.accepted = true;
                }
            }

            ColumnLayout {
                id: noteCard
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 22
                    rightMargin: 22
                }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "\uf075"
                        font.family: root.fontFamily
                        font.pixelSize: 22
                        color: Appearance.m3colors.m3accentPrimary
                        renderType: Text.NativeRendering
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.todoCount > 0 ? (root.currentTodo.description || "") : ""
                        font.family: root.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3primaryText
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Appearance.m3colors.m3borderSecondary
                    opacity: 0.4
                }

                TextInput {
                    id: noteInput
                    Layout.fillWidth: true
                    Layout.minimumHeight: 36

                    font.family: root.fontFamily
                    font.pixelSize: 19
                    color: Appearance.m3colors.m3primaryText
                    selectionColor: Appearance.m3colors.m3accentPrimary
                    selectedTextColor: Appearance.m3colors.m3windowBackground
                    renderType: Text.NativeRendering
                    clip: true

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeNoteMode();
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.submitNote();
                            event.accepted = true;
                            return;
                        }
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Add a note..."
                        font: noteInput.font
                        color: Appearance.m3colors.m3secondaryText
                        visible: noteInput.text.length === 0
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "enter save · esc cancel"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    color: Appearance.m3colors.m3secondaryText
                    opacity: 0.6
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
