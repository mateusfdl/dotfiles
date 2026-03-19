pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import QsUtils

/**
 * Pomodoro timer service with work/break intervals.
 * - Reads initial durations from Config.options.time.pomodoro
 * - Logs every session event as JSONL to ~/.local/state/quickshell/pomodoro-sessions.jsonl
 * - After a break finishes the timer goes to Idle (user must click Start again)
 * - Optional lockOnBreak flag shows a fullscreen overlay during breaks
 */
Singleton {
    id: root

    property int workDuration: Config.options.time.pomodoro.focus
    property int shortBreakDuration: Config.options.time.pomodoro.breakTime
    property int longBreakDuration: Config.options.time.pomodoro.longBreak
    property int pomodorosUntilLongBreak: Config.options.time.pomodoro.cyclesBeforeLongBreak

    property bool lockOnBreak: false

    property var currentTodo: null
    property var _sessionEvents: []
    property int _totalBreakSeconds: 0
    property int _totalFocusSeconds: 0
    property real _breakStartEpoch: 0

    enum State {
        Idle,
        Working,
        ShortBreak,
        LongBreak,
        Paused
    }

    property int state: Pomodoro.State.Idle
    property int previousRunningState: Pomodoro.State.Working
    property int timeRemaining: workDuration
    property int totalTime: workDuration
    property int completedPomodoros: 0
    property int currentCycle: 0

    readonly property string displayTime: formatTime(timeRemaining)
    readonly property real progress: totalTime > 0 ? (1 - timeRemaining / totalTime) : 0
    readonly property bool isRunning: state === Pomodoro.State.Working || state === Pomodoro.State.ShortBreak || state === Pomodoro.State.LongBreak
    readonly property bool isPaused: state === Pomodoro.State.Paused
    readonly property bool isOnBreak: state === Pomodoro.State.ShortBreak || state === Pomodoro.State.LongBreak
    readonly property string stateLabel: {
        switch (state) {
        case Pomodoro.State.Working:
            return "Focus Time";
        case Pomodoro.State.ShortBreak:
            return "Short Break";
        case Pomodoro.State.LongBreak:
            return "Long Break";
        case Pomodoro.State.Paused:
            return "Paused";
        default:
            return "Ready";
        }
    }

    property real _segmentStartEpoch: 0

    readonly property string _logDir: Files.trimFileProtocol(`${Directories.state}`)
    readonly property string _logPath: `${_logDir}/pomodoro-sessions.jsonl`

    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: root.isRunning
        onTriggered: {
            if (root.timeRemaining > 0) {
                root.timeRemaining--;
            } else {
                root.onTimerComplete();
            }
        }
    }

    Process {
        id: beepProcess
        running: false
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"]
    }

    function formatTime(seconds: int): string {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    function _nowEpoch(): real {
        return Math.floor(Date.now() / 1000);
    }

    function _isoNow(): string {
        return new Date().toISOString();
    }

    function playBeep() {
        beepProcess.running = true;
        Quickshell.execDetached(["sh", "-c", "paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || " + "aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || " + "beep 2>/dev/null || " + "paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null"]);
    }

    function _stateTypeString(s: int): string {
        switch (s) {
        case Pomodoro.State.Working:
            return "focus";
        case Pomodoro.State.ShortBreak:
            return "shortBreak";
        case Pomodoro.State.LongBreak:
            return "longBreak";
        default:
            return "idle";
        }
    }

    function logEvent(event: string, stateVal: int, duration: int, elapsed: int) {
        const entry = JSON.stringify({
            ts: _isoNow(),
            event: event,
            type: _stateTypeString(stateVal),
            duration: duration,
            elapsed: elapsed,
            cycle: currentCycle,
            completed: completedPomodoros
        });
        Quickshell.execDetached(["sh", "-c", `mkdir -p '${_logDir}' && printf '%s\\n' '${entry}' >> '${_logPath}'`]);
    }

    function start() {
        if (state === Pomodoro.State.Idle) {
            startWork();
        } else if (isPaused) {
            resume();
        }
    }

    function startWork() {
        state = Pomodoro.State.Working;
        previousRunningState = Pomodoro.State.Working;
        timeRemaining = workDuration;
        totalTime = workDuration;
        _segmentStartEpoch = _nowEpoch();
        logEvent("started", Pomodoro.State.Working, workDuration, 0);
        _pushEvent("Start Session");
    }

    function pause() {
        if (isRunning) {
            previousRunningState = state;
            state = Pomodoro.State.Paused;
            _pushEvent("Pause");
        }
    }

    function resume() {
        if (isPaused && timeRemaining > 0) {
            state = previousRunningState;
            _pushEvent("Resume");
        }
    }

    function stop() {
        if (state !== Pomodoro.State.Idle) {
            const elapsed = Math.round(_nowEpoch() - _segmentStartEpoch);
            const wasState = isPaused ? previousRunningState : state;
            logEvent("stopped", wasState, totalTime, elapsed);

            if (wasState === Pomodoro.State.Working) {
                _totalFocusSeconds += elapsed;
            } else if (wasState === Pomodoro.State.ShortBreak || wasState === Pomodoro.State.LongBreak) {
                _totalBreakSeconds += elapsed;
            }

            _pushEvent("Stopped");
            _flushSessionToTodo();
        }
        state = Pomodoro.State.Idle;
        timeRemaining = workDuration;
        totalTime = workDuration;
        currentCycle = 0;
    }

    function reset() {
        stop();
        completedPomodoros = 0;
    }

    function skip() {
        if (isRunning || isPaused) {
            const elapsed = Math.round(_nowEpoch() - _segmentStartEpoch);
            const wasState = isPaused ? previousRunningState : state;
            logEvent("skipped", wasState, totalTime, elapsed);

            if (wasState === Pomodoro.State.Working) {
                _totalFocusSeconds += elapsed;
                _pushEvent("Skipped");
            } else if (wasState === Pomodoro.State.ShortBreak || wasState === Pomodoro.State.LongBreak) {
                _totalBreakSeconds += elapsed;
                _pushEvent("Break Skipped");
            }

            _advanceAfterComplete(wasState);
        }
    }

    function onTimerComplete() {
        playBeep();

        const elapsed = totalTime;
        logEvent("completed", state, totalTime, elapsed);

        if (state === Pomodoro.State.Working) {
            _totalFocusSeconds += elapsed;
            _pushEvent("Finish");
        } else if (state === Pomodoro.State.ShortBreak || state === Pomodoro.State.LongBreak) {
            _totalBreakSeconds += elapsed;
            _pushEvent("Break End");
        }

        _advanceAfterComplete(state);
    }

    function _advanceAfterComplete(fromState: int) {
        if (fromState === Pomodoro.State.Working) {
            completedPomodoros++;
            currentCycle++;

            if (currentCycle >= pomodorosUntilLongBreak) {
                state = Pomodoro.State.LongBreak;
                previousRunningState = Pomodoro.State.LongBreak;
                timeRemaining = longBreakDuration;
                totalTime = longBreakDuration;
                currentCycle = 0;
            } else {
                state = Pomodoro.State.ShortBreak;
                previousRunningState = Pomodoro.State.ShortBreak;
                timeRemaining = shortBreakDuration;
                totalTime = shortBreakDuration;
            }
            _segmentStartEpoch = _nowEpoch();
            logEvent("started", state, totalTime, 0);
            _pushEvent(state === Pomodoro.State.LongBreak ? "Long Break" : "Short Break");
        } else {
            _flushSessionToTodo();
            state = Pomodoro.State.Idle;
            timeRemaining = workDuration;
            totalTime = workDuration;
        }
    }

    function pickupTodo(description: string, noteId: string, tags: list<string>) {
        if (state !== Pomodoro.State.Idle)
            return;
        currentTodo = {
            description: description,
            noteId: noteId,
            tags: tags
        };
        _sessionEvents = [];
        _totalBreakSeconds = 0;
        _totalFocusSeconds = 0;
    }

    function clearTodo() {
        currentTodo = null;
        _sessionEvents = [];
        _totalBreakSeconds = 0;
        _totalFocusSeconds = 0;
    }

    function _pushEvent(text: string) {
        const timeStr = new Date().toLocaleTimeString(Qt.locale(), "HH:mm");
        let events = _sessionEvents.slice();
        events.push({
            time: timeStr,
            text: text
        });
        _sessionEvents = events;
    }

    function _flushSessionToTodo() {
        if (!currentTodo || !currentTodo.noteId || _sessionEvents.length === 0)
            return;
        const focusMin = Math.round(_totalFocusSeconds / 60);
        const breakMin = Math.round(_totalBreakSeconds / 60);

        let events = [];
        for (let i = 0; i < _sessionEvents.length; i++) {
            events.push(_sessionEvents[i]);
        }

        ObsidianTodo.appendSessionLog(currentTodo.noteId, focusMin, breakMin, events);
        _sessionEvents = [];
        _totalBreakSeconds = 0;
        _totalFocusSeconds = 0;
    }

    function setWorkDuration(minutes: int) {
        workDuration = minutes * 60;
        if (state === Pomodoro.State.Idle) {
            timeRemaining = workDuration;
            totalTime = workDuration;
        }
    }

    function setShortBreakDuration(minutes: int) {
        shortBreakDuration = minutes * 60;
    }

    function setLongBreakDuration(minutes: int) {
        longBreakDuration = minutes * 60;
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", _logDir]);
    }
}
