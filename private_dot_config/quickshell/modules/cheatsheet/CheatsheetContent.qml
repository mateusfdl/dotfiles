pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.effects
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Colors

Item {
    id: root

    property real maxWidth: 1600
    property real maxHeight: 900

    readonly property real rowHeight: 34
    readonly property real sectionRowHeight: 42
    readonly property real columnGap: 36
    readonly property string fontFamily: "IosevkaSS04 Nerd Font Mono"

    // Symbol map for modifier/special keys
    readonly property var keySymbols: ({
        "Super": "⌘",
        "Ctrl": "⌃",
        "Alt": "⌥",
        "Shift": "⇧",
        "Tab": "⇥",
        "Return": "↵",
        "Delete": "⌫",
        "Space": "␣",
        "Print": "PrtSc",
        "Left": "←",
        "Right": "→",
        "Up": "↑",
        "Down": "↓",
        "Scroll Down": "⟱",
        "Scroll Up": "⟰",
        "Sleep": "⏾",
        "Mute": "🔇",
        "Mic Mute": "🎙",
        "Vol+": "🔊",
        "Vol-": "🔉",
    })

    function keyToSymbol(key) {
        return keySymbols[key] !== undefined ? keySymbols[key] : key;
    }

    // Format a full key combo as a single string: "⌘ ⇧ ←"
    function formatKeyCombo(mods, key) {
        const parts = [];
        if (mods) {
            for (const m of mods) parts.push(keyToSymbol(m));
        }
        if (key) parts.push(keyToSymbol(key));
        return parts.join(" ");
    }

    // Shorten verbose section titles
    function shortenTitle(title) {
        const map = {
            "Move focus with mainMod + arrow keys": "Focus",
            "Switch workspaces with mainMod + [0-9]": "Switch workspace",
            "Move active window and follow to workspace mainMod + SHIFT [0-9]": "Move to workspace",
            "Move active window to a workspace silently mainMod + CTRL [0-9]": "Move to workspace (silent)",
            "Scroll through existing workspaces with mainMod + scroll": "Scroll workspaces",
            "Move/resize windows with mainMod + LMB/RMB and dragging": "Mouse move/resize",
            "Keybind cheatsheet (QuickShell)": "Cheatsheet",
            "Window Switcher (QuickShell)": "Window switcher",
            "Opacity toggle on active window": "Opacity",
            "Volume (wpctl)": "Volume",
            "Refresh hyprland config": "Config reload",
            "Workspaces related": "Workspaces",
            "Dwindle Layout": "Dwindle",
            "Resize windows": "Resize",
            "Move windows": "Move",
            "Swap windows": "Swap",
            "Window management": "Window mgmt",
            "Special workspace": "Special",
            "App launchers": "Launchers",
            "Cursor zoom": "Zoom",
        };
        return map[title] || title;
    }

    // Cached flat data
    property var _flatData: flattenBinds()

    readonly property int columnCount: Math.max(2, Math.floor((maxWidth + columnGap) / 380))

    implicitWidth: maxWidth
    implicitHeight: maxHeight

    // Collapse consecutive numbered entries (e.g. Workspace 1..10) into one row
    function collapseSections(sections) {
        const result = [];
        for (const section of sections) {
            const collapsed = [];
            let runGroup = null;

            for (const bind of section.binds) {
                const desc = bind.description || "";
                const wsMatch = desc.match(/^(.+?)(\s+[-+]?\d+)$/);
                if (wsMatch) {
                    const baseDesc = wsMatch[1].trim();
                    const num = wsMatch[2].trim();
                    if (runGroup && runGroup.baseDesc === baseDesc) {
                        runGroup.numbers.push(num);
                        runGroup.lastBind = bind;
                        continue;
                    } else {
                        if (runGroup && runGroup.numbers.length > 2) {
                            collapsed.push({
                                mods: runGroup.firstBind.mods,
                                key: runGroup.numbers[0] + ".." + runGroup.numbers[runGroup.numbers.length - 1],
                                description: runGroup.baseDesc + " " + runGroup.numbers[0] + "-" + runGroup.numbers[runGroup.numbers.length - 1],
                            });
                        } else if (runGroup) {
                            for (const b of runGroup.allBinds) collapsed.push(b);
                        }
                        runGroup = { baseDesc: baseDesc, numbers: [num], firstBind: bind, lastBind: bind, allBinds: [bind] };
                        continue;
                    }
                } else {
                    if (runGroup) {
                        if (runGroup.numbers.length > 2) {
                            collapsed.push({
                                mods: runGroup.firstBind.mods,
                                key: runGroup.numbers[0] + ".." + runGroup.numbers[runGroup.numbers.length - 1],
                                description: runGroup.baseDesc + " " + runGroup.numbers[0] + "-" + runGroup.numbers[runGroup.numbers.length - 1],
                            });
                        } else {
                            for (const b of runGroup.allBinds) collapsed.push(b);
                        }
                        runGroup = null;
                    }
                    collapsed.push(bind);
                }
                if (runGroup) runGroup.allBinds.push(bind);
            }
            if (runGroup) {
                if (runGroup.numbers.length > 2) {
                    collapsed.push({
                        mods: runGroup.firstBind.mods,
                        key: runGroup.numbers[0] + ".." + runGroup.numbers[runGroup.numbers.length - 1],
                        description: runGroup.baseDesc + " " + runGroup.numbers[0] + "-" + runGroup.numbers[runGroup.numbers.length - 1],
                    });
                } else {
                    for (const b of runGroup.allBinds) collapsed.push(b);
                }
            }

            if (collapsed.length > 0) {
                result.push({ title: section.title, binds: collapsed });
            }
        }
        return result;
    }

    function flattenBinds() {
        const allSections = collapseSections(HyprlandKeybinds.keybinds);
        const flat = [];
        for (const section of allSections) {
            flat.push({ type: "section", title: shortenTitle(section.title) });
            for (const bind of section.binds) {
                flat.push({ type: "bind", mods: bind.mods || [], key: bind.key || "", description: bind.description || "" });
            }
        }
        return flat;
    }

    function buildColumns(colCount) {
        const flat = root._flatData;
        const cols = [];
        const perCol = Math.ceil(flat.length / colCount);
        for (let i = 0; i < colCount; i++) {
            cols.push(flat.slice(i * perCol, Math.min((i + 1) * perCol, flat.length)));
        }
        return cols;
    }

    ColumnLayout {
        id: outerColumn
        anchors {
            fill: parent
            topMargin: 20
            bottomMargin: 16
            leftMargin: 28
            rightMargin: 28
        }
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            spacing: 10

            ColouredIcon {
                source: "image://icon/preferences-desktop-keyboard"
                colour: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
                implicitSize: 28
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
            }

            Text {
                text: "Keyboard Shortcuts"
                font.family: root.fontFamily
                font.pixelSize: 20
                font.weight: Font.DemiBold
                color: Appearance.m3colors?.m3primaryText ?? "#c0caf5"
                renderType: Text.NativeRendering
            }

            Item { Layout.fillWidth: true }
        }

        // Separator — uses Colors (C++ plugin) to tint with accent
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

        // Grid content with opacity mask for edge fading
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 10
            contentWidth: width
            contentHeight: columnsRow.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            layer.enabled: flickable.contentHeight > flickable.height
            layer.effect: OpacityMask {
                source: flickable
                maskSource: flickableMask
            }

            ScrollBar.vertical: ScrollBar {
                policy: flickable.contentHeight > flickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 2
                    color: Appearance.m3colors?.m3secondaryText ?? "#565f89"
                    opacity: parent.active ? 0.6 : 0.3
                }
            }

            Row {
                id: columnsRow
                width: flickable.width
                spacing: root.columnGap

                property int colCount: root.columnCount
                property real colWidth: (width - (colCount - 1) * root.columnGap) / colCount
                property var colData: root.buildColumns(colCount)

                Repeater {
                    model: columnsRow.colCount

                    Column {
                        id: col
                        required property int index
                        width: columnsRow.colWidth
                        spacing: 0

                        Repeater {
                            model: {
                                const data = columnsRow.colData;
                                return (data && data[col.index]) ? data[col.index] : [];
                            }

                            Item {
                                id: rowItem
                                required property var modelData
                                required property int index
                                width: col.width
                                height: modelData.type === "section" ? root.sectionRowHeight : root.rowHeight

                                // Section label
                                Text {
                                    visible: rowItem.modelData.type === "section"
                                    text: rowItem.modelData.title ?? ""
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    font.family: root.fontFamily
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    color: Appearance.m3colors?.m3accentPrimary ?? "#7aa2f7"
                                    renderType: Text.NativeRendering
                                }

                                // Keybind row: ⌘ ⇧ ← → Description
                                Item {
                                    visible: rowItem.modelData.type === "bind"
                                    anchors.fill: parent

                                    // Key combo as plain text with symbols
                                    Text {
                                        id: keysText
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.formatKeyCombo(rowItem.modelData.mods, rowItem.modelData.key)
                                        font.family: root.fontFamily
                                        font.pixelSize: 15
                                        color: Appearance.m3colors?.m3primaryText ?? "#c0caf5"
                                        renderType: Text.NativeRendering
                                    }

                                    // Description
                                    Text {
                                        anchors.left: keysText.right
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: rowItem.modelData.description ?? ""
                                        font.family: root.fontFamily
                                        font.pixelSize: 15
                                        color: Appearance.m3colors?.m3surfaceText ?? "#a9b1d6"
                                        renderType: Text.NativeRendering
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Mask source for the opacity fade on the flickable edges
        Item {
            id: flickableMask

            anchors.fill: flickable
            visible: false
            layer.enabled: true

            // Top fade gradient
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 20
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "white" }
                }
            }

            // Opaque center
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 20
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                width: parent.width
                color: "white"
            }

            // Bottom fade gradient
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 20
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
    }
}
