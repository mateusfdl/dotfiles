pragma Singleton

import qs.modules.common
import "root:/modules/common/functions/fuzzysort.js" as Fuzzy
import "root:/modules/common/functions/levendist.js" as Levendist
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "zen": "zen-browser",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    // Pre-defined quickshell internal apps
    readonly property var quickshellApps: [
        {
            name: "Wallpaper Selector",
            icon: "preferences-desktop-wallpaper",
            comment: "Change your wallpaper",
            isQuickshellApp: true,
            command: "quickshell ipc wallpaper-selector open"
        },
        {
            name: "Overview",
            icon: "view-grid",
            comment: "Open overview mode",
            isQuickshellApp: true,
            command: "quickshell ipc overview open"
        }
    ]

    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    function search(query: string): var {
        return fuzzyQuery(query)
    }

    function launch(entry: DesktopEntry): void {
        if (!entry) return;

        if (typeof entry.execute === "function") {
            entry.execute();
        } else if (typeof entry.launch === "function") {
            entry.launch();
        } else if (typeof entry.run === "function") {
            entry.run();
        } else if (entry.command) {
            Quickshell.execDetached({
                command: entry.command,
                workingDirectory: entry.workingDirectory ?? ""
            });
        }
    }

    function fuzzyQuery(search: string): var {
        const searchLower = search.toLowerCase();

        // Search in desktop apps
        let desktopResults = [];
        if (root.sloppySearch) {
            desktopResults = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), searchLower)
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
                .map(item => item.entry);
        } else {
            desktopResults = Fuzzy.go(search, preppedNames, {
                all: true,
                key: "name"
            }).map(r => r.obj.entry);
        }

        // Search in quickshell apps
        const quickshellResults = quickshellApps.filter(app =>
            app.name.toLowerCase().includes(searchLower) ||
            (app.comment && app.comment.toLowerCase().includes(searchLower))
        );

        // Merge results, putting quickshell apps first
        return [...quickshellResults, ...desktopResults];
    }

    function iconExists(iconName) {
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function guessIcon(str) {
        if (!str || str.length == 0) return "image-missing";

        if (substitutions[str])
            return substitutions[str];

        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        if (iconExists(str)) return str;

        let guessStr = str;
        guessStr = str.split('.').slice(-1)[0].toLowerCase();
        if (iconExists(guessStr)) return guessStr;
        guessStr = str.toLowerCase().replace(/\s+/g, "-");
        if (iconExists(guessStr)) return guessStr;
        const searchResults = root.fuzzyQuery(str);
        if (searchResults.length > 0) {
            const firstEntry = searchResults[0];
            guessStr = firstEntry.icon
            if (iconExists(guessStr)) return guessStr;
        }

        return str;
    }
}
