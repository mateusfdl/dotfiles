pragma Singleton

import qs
import qs.modules.common
import QsUtils
import Quickshell
import QtQuick

Singleton {
    id: root

    Binding {
        target: AppSearchBackend
        property: "sloppySearch"
        value: Config.options?.search.sloppy ?? false
    }

    readonly property var quickshellApps: [
        {
            name: "Wallpaper Selector",
            icon: "preferences-desktop-wallpaper",
            comment: "Change your wallpaper",
            action: "wallpaperSelector"
        },
        {
            name: "Overview",
            icon: "view-grid",
            comment: "Open overview mode",
            action: "overview"
        },
        {
            name: "SoundCloud",
            icon: "soundcloud",
            comment: "Listen to music on SoundCloud",
            exec: "soundcloud"
        },
        {
            name: "Spotify",
            icon: "spotify",
            comment: "Music streaming",
            exec: "spotify"
        },
        {
            name: "Obsidian",
            icon: "obsidian",
            comment: "Knowledge base and notes",
            exec: "obsidian"
        },
        {
            name: "Brave",
            icon: "brave-browser",
            comment: "Web browser",
            exec: "brave"
        },
        {
            name: "Discord",
            icon: "discord",
            comment: "Chat and voice",
            exec: "discord"
        },
        {
            name: "Morgen",
            icon: "morgen",
            comment: "Calendar and scheduling",
            exec: "morgen"
        }
    ]

    readonly property var list: AppSearchBackend.applications

    function search(query: string): var {
        return fuzzyQuery(query);
    }

    function launch(entry): void {
        if (!entry)
            return;

        if (entry.action) {
            switch (entry.action) {
            case "wallpaperSelector":
                GlobalStates.wallpaperSelectorOpen = true;
                break;
            case "overview":
                GlobalStates.overviewOpen = true;
                break;
            }
            return;
        }

        AppSearchBackend.launch(entry);
    }

    function fuzzyQuery(search: string): var {
        const searchLower = search.toLowerCase();
        const desktopResults = AppSearchBackend.search(search);

        const quickshellResults = quickshellApps.filter(
            app => app.name.toLowerCase().includes(searchLower)
                || (app.comment && app.comment.toLowerCase().includes(searchLower))
        );

        const qsNames = new Set(quickshellResults.map(a => a.name.toLowerCase()));
        const filtered = desktopResults.filter(
            app => !qsNames.has((app.name ?? "").toLowerCase())
        );

        return [...quickshellResults, ...filtered];
    }

    function guessIcon(str) {
        return AppSearchBackend.guessIcon(str);
    }
}
