pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        let parents = [obj];

        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    FileView {
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter
            property JsonObject ui: JsonObject {
                property string theme: "dark"
                property real scale: 1.25
            }

            property JsonObject font: JsonObject {
                property JsonObject family: JsonObject {
                    property string uiFont: "Open Sans"
                    property string iconFont: "FiraConde Nerd Font"
                    property string codeFont: "JetBrains Mono NF"
                }
                property JsonObject pixelSize: JsonObject {
                    property int textSmall: 13
                    property int textBase: 15
                    property int textMedium: 16
                    property int textLarge: 19
                    property int iconLarge: 22
                }
            }

            property JsonObject ai: JsonObject {
                property string systemPrompt: "## Style\n- Use casual tone, don't be formal! Make sure you answer precisely without hallucination and prefer bullet points over walls of text. You can have a friendly greeting at the beginning of the conversation, but don't repeat the user's question\n\n## Context (ignore when irrelevant)\n- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n- Desktop environment: {DE}\n- Current date & time: {DATETIME}\n- Focused app: {WINDOWCLASS}\n\n## Presentation\n- Use Markdown features in your response: \n  - **Bold** text to **highlight keywords** in your response\n  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n"
                property string tool: "functions"
                property list<var> extraModels: [
                    {
                        "api_format": "openai",
                        "description": "This is a custom model. Edit the config to add more! | Anyway, this is DeepSeek R1 Distill LLaMA 70B",
                        "endpoint": "https://openrouter.ai/api/v1/chat/completions",
                        "homepage": "https://openrouter.ai/deepseek/deepseek-r1-distill-llama-70b:free" // Not mandatory
                        ,
                        "icon": "spark-symbolic",
                        "key_get_link": "https://openrouter.ai/settings/keys" // Not mandatory
                        ,
                        "key_id": "openrouter",
                        "model": "deepseek/deepseek-r1-distill-llama-70b:free",
                        "name": "Custom: DS R1 Dstl. LLaMA 70B",
                        "requires_key": true
                    }
                ]
            }

            property JsonObject appearance: JsonObject {
                property bool extraBackgroundTint: true
                property int fakeScreenRounding: 2
                property JsonObject palette: JsonObject {
                    property string type: "auto"
                }
            }

            property JsonObject audio: JsonObject {
                property JsonObject protection: JsonObject {
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string network: "kitty -1 fish -c nmtui"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1"
            }

            property JsonObject bar: JsonObject {
                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                    property int hoverRegionWidth: 2
                    property bool pushWindows: false
                    property JsonObject showWhenPressingSuper: JsonObject {
                        property bool enable: true
                        property int delay: 140
                    }
                }
                property bool bottom: false
                property int cornerStyle: 0
                property bool borderless: false
                property string topLeftIcon: "spark"
                property bool showBackground: true
                property string iconColor: ""
                property bool verbose: true
                property bool vertical: false
                property int margins: 15
                property int spacing: 10
                property JsonObject resources: JsonObject {
                    property bool alwaysShowSwap: true
                    property bool alwaysShowCpu: true
                    property int memoryWarningThreshold: 95
                    property int swapWarningThreshold: 85
                    property int cpuWarningThreshold: 90
                }
                property list<string> screenList: []
                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: false
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: true
                    property bool showDarkModeToggle: true
                    property bool showPerformanceProfileToggle: false
                }
                property JsonObject tray: JsonObject {
                    property bool monochromeIcons: true
                    property bool showItemId: false
                    property bool invertPinnedItems: true
                    property list<string> pinnedItems: []
                    property int itemSize: 24
                    property int iconSize: 20
                    property int spacing: 14
                }
                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: true
                    property int shown: 10
                    property int spacing: 4
                    property int size: 24
                    property int iconSize: 16
                    property bool showAppIcons: true
                    property bool alwaysShowNumbers: false
                    property int showNumberDelay: 300
                    property list<string> numberMap: ["1", "2"] // Characters to show instead of numbers on workspace indicator
                    property bool useNerdFont: false
                    property int activeSize: 8
                    property int inactiveSize: 8
                }
                property JsonObject weather: JsonObject {
                    property bool enable: false
                    property bool enableGPS: true
                    property string city: ""
                    property bool useUSCS: false
                    property int fetchInterval: 10
                }
            }

            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject {
                    property bool fasterTouchpadScroll: false
                    property int mouseScrollDeltaThreshold: 120
                    property int mouseScrollFactor: 120
                    property int touchpadScrollFactor: 450
                }
                property JsonObject deadPixelWorkaround: JsonObject {
                    property bool enable: false
                }
            }

            property JsonObject lock: JsonObject {
                property bool launchOnStartup: false
                property JsonObject blur: JsonObject {
                    property bool enable: false
                    property real radius: 100
                    property real extraZoom: 1.1
                }
                property bool centerClock: true
                property bool showLockedText: true
                property JsonObject security: JsonObject {
                    property bool unlockKeyring: true
                    property bool requirePasswordToPower: false
                }
            }

            property JsonObject modules: JsonObject {
                property bool topbar: true
                property bool overview: true
                property bool windowSwitcher: true
                property bool launcher: true
                property bool wallpaper: true
                property bool notifications: true
                property bool aiChat: true
                property bool lockScreen: true
                property bool cheatsheet: true
                property bool obsidianTodo: true
            }

            property JsonObject networking: JsonObject {
                property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7000
            }

            property JsonObject osd: JsonObject {
                property int timeout: 1000
            }

            property JsonObject overview: JsonObject {
                property bool enable: true
                property real scale: 0.18
                property real numOfRows: 2
                property real numOfCols: 5
                property bool showXwaylandIndicator: true
                property real windowPadding: 6
                property real position: 1
                property real workspaceNumberSize: 120
            }

            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
            }

            property JsonObject search: JsonObject {
                property bool searchEnabled: false
                property int nonAppResultDelay: 30
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com"]
                property bool sloppy: false
                property JsonObject prefix: JsonObject {
                    property bool showDefaultActionsWithoutPrefix: true
                    property string action: "/"
                    property string app: ">"
                    property string clipboard: ";"
                    property string emojis: ":"
                    property string math: "="
                    property string shellCommand: "$"
                    property string webSearch: "?"
                }
            }

            property JsonObject launcher: JsonObject {
                property bool enabled: true
                property int maxShown: 7
                property JsonObject sizes: JsonObject {
                    property int itemWidth: 600
                    property int itemHeight: 57
                    property int wallpaperWidth: 280
                    property int wallpaperHeight: 200
                }
            }

            property JsonObject time: JsonObject {

                property string format: "hh:mm"
                property string shortDateFormat: "dd/MM"
                property string dateFormat: "ddd, dd/MM"
                property JsonObject pomodoro: JsonObject {
                    property string alertSound: ""
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }
            }

            property JsonObject wallpaperSelector: JsonObject {
                property bool useSystemFileDialog: false
            }

            property JsonObject windows: JsonObject {
                property bool showTitlebar: true
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20
            }
        }
    }
}
