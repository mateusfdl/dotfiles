pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Parses Hyprland keybind config files in pure QML.
 * Groups keybinds by section headers (# comments above bind groups).
 * Re-parses on Hyprland configreloaded events.
 */
Singleton {
    id: root

    readonly property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(
        `${Directories.config}/hypr/configs/keybinds.conf`
    )
    readonly property string userKeybindConfigPath: FileUtils.trimFileProtocol(
        `${Directories.config}/hypr/user/keybinds.conf`
    )

    property var keybinds: []
    property string _defaultText: ""
    property string _userText: ""

    Component.onCompleted: {
        readDefaultConfig.running = true
        readUserConfig.running = true
    }

    // Code-to-key mapping for Hyprland keycodes
    readonly property var codeMap: ({
        "code:10": "1", "code:11": "2", "code:12": "3", "code:13": "4", "code:14": "5",
        "code:15": "6", "code:16": "7", "code:17": "8", "code:18": "9", "code:19": "0"
    })

    // Friendly names for special keys
    readonly property var keyNameMap: ({
        "return": "Return", "space": "Space", "tab": "Tab", "delete": "Delete",
        "print": "Print", "left": "Left", "right": "Right", "up": "Up", "down": "Down",
        "bracketleft": "[", "bracketright": "]", "period": ".", "comma": ",",
        "mouse_down": "Scroll Down", "mouse_up": "Scroll Up",
        "mouse:272": "LMB", "mouse:273": "RMB",
        "xf86audioraisevolume": "Vol+", "xf86audiolowervolume": "Vol-",
        "xf86audiomute": "Mute", "xf86audiomicmute": "Mic Mute",
        "xf86sleep": "Sleep", "alt_l": "Alt"
    })

    // Friendly names for dispatchers/actions
    readonly property var actionNameMap: ({
        "killactive": "Kill window",
        "togglesplit": "Toggle split",
        "pseudo": "Pseudo-tile",
        "togglegroup": "Toggle group",
        "changegroupactive": "Next in group",
        "togglefloating": "Toggle floating",
        "togglespecialworkspace": "Toggle special workspace",
        "fullscreen": "Fullscreen",
        "workspace": "Workspace",
        "movetoworkspace": "Move to workspace",
        "movetoworkspacesilent": "Move to workspace (silent)",
        "movefocus": "Focus",
        "movewindow": "Move window",
        "swapwindow": "Swap window",
        "resizeactive": "Resize",
        "global": "Global shortcut"
    })

    function parseKeyName(raw) {
        const lower = raw.toLowerCase().trim();
        if (root.codeMap[lower]) return root.codeMap[lower];
        if (root.keyNameMap[lower]) return root.keyNameMap[lower];
        return raw.charAt(0).toUpperCase() + raw.slice(1);
    }

    function formatMods(modStr) {
        const mods = modStr.trim().split(/\s+/);
        const result = [];
        for (const mod of mods) {
            const m = mod.toUpperCase();
            if (m === "$MAINMOD" || m === "SUPER") result.push("Super");
            else if (m === "CTRL") result.push("Ctrl");
            else if (m === "ALT") result.push("Alt");
            else if (m === "SHIFT") result.push("Shift");
            else if (m.length > 0) result.push(mod);
        }
        return result;
    }

    function describeAction(dispatcher, args) {
        const d = dispatcher.trim().toLowerCase();
        const a = args.trim();

        if (d === "exec") {
            if (a.includes("quickshell ipc call")) {
                const parts = a.split("quickshell ipc call")[1]?.trim().split(/\s+/) ?? [];
                return parts.length >= 2 ? `${parts[1]} ${parts[0]}` : a;
            }
            if (a.includes("hyprctl reload")) return "Reload config";
            if (a.includes("hyprctl dispatch exit")) return "Exit Hyprland";
            if (a.includes("hyprctl dispatch splitratio")) return "Set split ratio";
            if (a.includes("hyprctl dispatch workspaceopt allfloat")) return "Toggle all float";
            if (a.includes("hyprctl setprop active opaque")) return "Toggle opacity";
            if (a.includes("hyprctl keyword cursor:zoom_factor")) {
                return a.includes("* 2") ? "Zoom in" : "Zoom out";
            }
            if (a.includes("wpctl set-volume") && a.includes("+")) return "Volume up";
            if (a.includes("wpctl set-volume") && a.includes("-")) return "Volume down";
            if (a.includes("wpctl set-mute") && a.includes("SINK")) return "Toggle mute";
            if (a.includes("wpctl set-mute") && a.includes("SOURCE")) return "Toggle mic mute";
            if (a.includes("systemctl suspend")) return "Suspend";
            if (a.includes("screenshot.sh")) {
                if (a.includes("--now")) return "Screenshot (full)";
                if (a.includes("--area")) return "Screenshot (area)";
                if (a.includes("--in5")) return "Screenshot (5s delay)";
                if (a.includes("--in10")) return "Screenshot (10s delay)";
                if (a.includes("--active")) return "Screenshot (window)";
                return "Screenshot";
            }
            if (a.includes("xdg-open")) return "Open browser";
            const cmd = a.replace(/.*\//, "").replace(/\s.*/, "");
            return cmd || a;
        }

        if (d === "global") {
            if (a.includes("launcherToggle")) return "Toggle launcher";
            if (a.includes("overviewToggle")) return "Toggle overview";
            if (a.includes("cheatsheetToggle")) return "Toggle cheatsheet";
            if (a.includes("windowSwitcherNext")) return "Next window";
            if (a.includes("windowSwitcherPrevious")) return "Previous window";
            if (a.includes("windowSwitcherActivate")) return "Activate window";
            return a.replace("quickshell:", "");
        }

        const name = root.actionNameMap[d] || d;
        if (d === "workspace" || d === "movetoworkspace" || d === "movetoworkspacesilent") {
            if (a === "special") return name + " (special)";
            if (a.startsWith("m+")) return name + " (next)";
            if (a.startsWith("m-")) return name + " (prev)";
            if (a.startsWith("e+")) return name + " (scroll next)";
            if (a.startsWith("e-")) return name + " (scroll prev)";
            if (a === "-1" || a === "+1") return name + " " + a;
            return name + " " + a;
        }
        if (d === "movefocus" || d === "movewindow" || d === "swapwindow") {
            const dirMap = {"l": "left", "r": "right", "u": "up", "d": "down"};
            return name + " " + (dirMap[a] || a);
        }
        if (d === "resizeactive") return name;
        if (d === "fullscreen" && a === "1") return "Fake fullscreen";

        return a ? `${name} ${a}` : name;
    }

    function parseLine(line) {
        const match = line.match(/^bind([a-z]*)\s*=\s*(.*)$/);
        if (!match) return null;

        const flags = match[1];
        const parts = match[2].split(",");
        if (parts.length < 3) return null;

        const mods = parts[0].trim();
        const key = parts[1].trim();
        const dispatcher = parts[2].trim();
        const args = parts.slice(3).join(",").trim();

        // Skip mouse-only bindings (bindm)
        if (flags.includes("m") && !flags.includes("e")) return null;

        const modList = formatMods(mods);
        const keyName = parseKeyName(key);
        const description = describeAction(dispatcher, args);

        return {
            mods: modList,
            key: keyName,
            description: description,
        };
    }

    function parseConfig(text) {
        const lines = text.split("\n");
        const sections = [];
        let currentSection = null;
        const seen = new Set();

        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (!line) continue;

            if (line.startsWith("#") && !line.startsWith("#!")) {
                const title = line.replace(/^#+\s*/, "").trim();
                if (title.length > 0 && title.length < 60) {
                    currentSection = { title: title, binds: [] };
                    sections.push(currentSection);
                }
                continue;
            }

            if (line.startsWith("$")) continue;

            if (line.match(/^bind/)) {
                const cleaned = line.replace(/#.*$/, "").trim();
                const bind = parseLine(cleaned);
                if (bind) {
                    const dedupKey = `${bind.mods.join("+")}+${bind.key}`;
                    if (!seen.has(dedupKey)) {
                        seen.add(dedupKey);
                        if (!currentSection) {
                            currentSection = { title: "General", binds: [] };
                            sections.push(currentSection);
                        }
                        currentSection.binds.push(bind);
                    }
                }
            }
        }

        return sections.filter(s => s.binds.length > 0);
    }

    function rebuildKeybinds() {
        let sections = [];
        try {
            if (root._defaultText.length > 0)
                sections = sections.concat(parseConfig(root._defaultText));
            if (root._userText.length > 0)
                sections = sections.concat(parseConfig(root._userText));
        } catch (e) {
            console.error("[HyprlandKeybinds] Error parsing configs:", e);
        }
        console.log("[HyprlandKeybinds] Parsed", sections.length, "sections,",
            sections.reduce((acc, s) => acc + s.binds.length, 0), "total binds");
        root.keybinds = sections;
    }

    // Read configs via cat using StdioCollector (collects all output, fires once)
    Process {
        id: readDefaultConfig
        command: ["cat", root.defaultKeybindConfigPath]
        running: false
        stdout: StdioCollector {
            id: defaultCollector
            onStreamFinished: {
                root._defaultText = defaultCollector.text;
                console.log("[HyprlandKeybinds] Default config loaded:", root._defaultText.length, "chars");
                root.rebuildKeybinds();
            }
        }
    }

    Process {
        id: readUserConfig
        command: ["cat", root.userKeybindConfigPath]
        running: false
        stdout: StdioCollector {
            id: userCollector
            onStreamFinished: {
                root._userText = userCollector.text;
                console.log("[HyprlandKeybinds] User config loaded:", root._userText.length, "chars");
                root.rebuildKeybinds();
            }
        }
    }

    // Re-parse on Hyprland config reload
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                readDefaultConfig.running = true;
                readUserConfig.running = true;
            }
        }
    }
}
