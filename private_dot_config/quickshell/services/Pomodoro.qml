pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import QsUtils

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
    readonly property bool isRunning: _isActive(state)
    readonly property bool isPaused: state === Pomodoro.State.Paused
    readonly property bool isOnBreak: _isBreak(state)
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
            if (root.timeRemaining > 0)
                root.timeRemaining--;
            else
                root._completeSegment();
        }
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

    function _isBreak(s: int): bool {
        return s === Pomodoro.State.ShortBreak || s === Pomodoro.State.LongBreak;
    }

    function _isActive(s: int): bool {
        return s === Pomodoro.State.Working || _isBreak(s);
    }

    function _durationFor(s: int): int {
        switch (s) {
        case Pomodoro.State.Working:
            return workDuration;
        case Pomodoro.State.ShortBreak:
            return shortBreakDuration;
        case Pomodoro.State.LongBreak:
            return longBreakDuration;
        default:
            throw new Error(`Pomodoro._durationFor: no duration for state ${s}`);
        }
    }

    function _typeName(s: int): string {
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

    function playBeep() {
        Quickshell.execDetached(["sh", "-c", "paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || beep 2>/dev/null || paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null"]);
    }

    function logEvent(event: string, stateVal: int, duration: int, elapsed: int) {
        const entry = JSON.stringify({
            ts: _isoNow(),
            event: event,
            type: _typeName(stateVal),
            duration: duration,
            elapsed: elapsed,
            cycle: currentCycle,
            completed: completedPomodoros
        });
        Quickshell.execDetached(["sh", "-c", `mkdir -p '${_logDir}' && printf '%s\\n' '${entry}' >> '${_logPath}'`]);
    }

    function _accountElapsed(s: int, elapsed: int) {
        if (s === Pomodoro.State.Working)
            _totalFocusSeconds += elapsed;
        else if (_isBreak(s))
            _totalBreakSeconds += elapsed;
    }

    function _enterPhase(phase: int) {
        const duration = _durationFor(phase);
        state = phase;
        previousRunningState = phase;
        totalTime = duration;
        timeRemaining = duration;
        _segmentStartEpoch = _nowEpoch();
        logEvent("started", phase, duration, 0);
    }

    function _resetToIdle() {
        state = Pomodoro.State.Idle;
        timeRemaining = workDuration;
        totalTime = workDuration;
    }

    function start() {
        if (state === Pomodoro.State.Idle)
            startWork();
        else if (isPaused)
            resume();
    }

    function startWork() {
        _enterPhase(Pomodoro.State.Working);
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
            const wasState = isPaused ? previousRunningState : state;
            const elapsed = Math.round(_nowEpoch() - _segmentStartEpoch);
            logEvent("stopped", wasState, totalTime, elapsed);
            _accountElapsed(wasState, elapsed);
            _pushEvent("Stopped");
            _flushSessionToTodo();
        }
        _resetToIdle();
        currentCycle = 0;
    }

    function reset() {
        stop();
        completedPomodoros = 0;
    }

    function skip() {
        if (isRunning || isPaused) {
            const wasState = isPaused ? previousRunningState : state;
            const elapsed = Math.round(_nowEpoch() - _segmentStartEpoch);
            logEvent("skipped", wasState, totalTime, elapsed);
            _accountElapsed(wasState, elapsed);
            _pushEvent(wasState === Pomodoro.State.Working ? "Skipped" : "Break Skipped");
            _advanceAfterComplete(wasState);
        }
    }

    function _completeSegment() {
        playBeep();
        logEvent("completed", state, totalTime, totalTime);
        _accountElapsed(state, totalTime);
        _pushEvent(state === Pomodoro.State.Working ? "Finish" : "Break End");
        _advanceAfterComplete(state);
    }

    function _advanceAfterComplete(fromState: int) {
        if (fromState !== Pomodoro.State.Working) {
            _flushSessionToTodo();
            _resetToIdle();
            return;
        }

        completedPomodoros++;
        currentCycle++;

        if (currentCycle >= pomodorosUntilLongBreak) {
            currentCycle = 0;
            _enterPhase(Pomodoro.State.LongBreak);
            _pushEvent("Long Break");
        } else {
            _enterPhase(Pomodoro.State.ShortBreak);
            _pushEvent("Short Break");
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
        _resetSession();
    }

    function clearTodo() {
        currentTodo = null;
        _resetSession();
    }

    function _resetSession() {
        _sessionEvents = [];
        _totalBreakSeconds = 0;
        _totalFocusSeconds = 0;
    }

    function _pushEvent(text: string) {
        _sessionEvents = _sessionEvents.concat({
            time: new Date().toLocaleTimeString(Qt.locale(), "HH:mm"),
            text: text
        });
    }

    function _flushSessionToTodo() {
        if (!currentTodo || !currentTodo.noteId || _sessionEvents.length === 0)
            return;
        const focusMin = Math.round(_totalFocusSeconds / 60);
        const breakMin = Math.round(_totalBreakSeconds / 60);
        ObsidianTodo.appendSessionLog(currentTodo.noteId, focusMin, breakMin, _sessionEvents.slice());
        _resetSession();
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
}
