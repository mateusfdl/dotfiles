pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    readonly property string scriptPath: Directories.home + "/scripts/weather"

    property bool loaded: false
    property bool fetching: false
    property string error: ""
    property string city: ""
    property bool isDay: true
    property real currentTemp: 0
    property int currentCode: 0
    property var forecast: []

    function refresh() {
        if (fetching)
            return;
        fetching = true;
        proc.running = true;
    }

    function _parse(text) {
        try {
            const data = JSON.parse(text);
            root.city = data.city || "";
            root.currentTemp = data.current?.temperature_2m ?? 0;
            root.currentCode = data.current?.weather_code ?? 0;
            root.isDay = (data.current?.is_day ?? 1) === 1;

            const daily = data.daily || {};
            const codes = daily.weather_code || [];
            const maxes = daily.temperature_2m_max || [];
            const mins = daily.temperature_2m_min || [];
            const times = daily.time || [];

            const out = [];
            for (let i = 0; i < times.length; i++) {
                const d = new Date(times[i]);
                out.push({
                    "date": times[i],
                    "weekday": d.toLocaleDateString(Qt.locale(), "ddd"),
                    "code": codes[i] ?? 0,
                    "max": Math.round(maxes[i] ?? 0),
                    "min": Math.round(mins[i] ?? 0)
                });
            }
            root.forecast = out;
            root.loaded = true;
            root.error = "";
        } catch (e) {
            root.error = String(e);
        }
    }

    function iconFor(code, isDay) {
        if (code === 0)
            return isDay ? "wb_sunny" : "bedtime";
        if (code === 1 || code === 2)
            return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
        if (code === 3)
            return "cloud";
        if (code === 45 || code === 48)
            return "foggy";
        if ((code >= 51 && code <= 57) || (code >= 80 && code <= 82))
            return "rainy";
        if (code >= 61 && code <= 67)
            return "rainy";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "weather_snowy";
        if (code >= 95)
            return "thunderstorm";
        return "cloud";
    }

    function colorFor(code, isDay) {
        if (code === 0)
            return isDay ? Qt.rgba(1.0, 0.78, 0.18, 1) : Qt.rgba(0.85, 0.85, 0.95, 1);
        if (code === 1 || code === 2)
            return isDay ? Qt.rgba(1.0, 0.85, 0.40, 1) : Qt.rgba(0.75, 0.78, 0.92, 1);
        if (code === 3)
            return Qt.rgba(0.80, 0.83, 0.88, 1);
        if (code === 45 || code === 48)
            return Qt.rgba(0.70, 0.72, 0.78, 1);
        if ((code >= 51 && code <= 57) || (code >= 80 && code <= 82) || (code >= 61 && code <= 67))
            return Qt.rgba(0.40, 0.68, 1.0, 1);
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return Qt.rgba(0.78, 0.88, 1.0, 1);
        if (code >= 95)
            return Qt.rgba(0.78, 0.55, 1.0, 1);
        return Qt.rgba(0.80, 0.83, 0.88, 1);
    }

    function descriptionFor(code) {
        if (code === 0)
            return "Clear";
        if (code === 1)
            return "Mainly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code === 45 || code === 48)
            return "Fog";
        if (code >= 51 && code <= 57)
            return "Drizzle";
        if (code >= 61 && code <= 67)
            return "Rain";
        if (code >= 71 && code <= 77)
            return "Snow";
        if (code >= 80 && code <= 82)
            return "Rain showers";
        if (code === 85 || code === 86)
            return "Snow showers";
        if (code >= 95)
            return "Thunderstorm";
        return "";
    }

    Process {
        id: proc
        command: [root.scriptPath]
        stdout: StdioCollector {
            id: stdoutCollector
            onStreamFinished: root._parse(stdoutCollector.text)
        }
        stderr: StdioCollector {
            id: stderrCollector
            onStreamFinished: {
                if (stderrCollector.text.trim() !== "")
                    root.error = stderrCollector.text.trim();
            }
        }
        onExited: exitCode => {
            root.fetching = false;
            if (exitCode !== 0 && root.error === "")
                root.error = "weather script exited with code " + exitCode;
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
