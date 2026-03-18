import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import QsUtils
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Pomodoro timer service with work/break intervals.
 * - Reads initial durations from Config.options.time.pomodoro
 * - Logs every session event as JSONL to ~/.local/state/quickshell/pomodoro-sessions.jsonl
 * - After a break finishes the timer goes to Idle (user must click Start again)
 * - Optional lockOnBreak flag shows a fullscreen overlay during breaks
 */
Singleton {
    id: root

    // Timer durations in seconds — initialised from Config
    property int workDuration: Config.options.time.pomodoro.focus
    property int shortBreakDuration: Config.options.time.pomodoro.breakTime
    property int longBreakDuration: Config.options.time.pomodoro.longBreak
    property int pomodorosUntilLongBreak: Config.options.time.pomodoro.cyclesBeforeLongBreak

    // Lock-on-break: when true, a fullscreen overlay is shown during breaks
    property bool lockOnBreak: false

    // Timer state machine
    enum State {
        Idle,
        Working,
        ShortBreak,
        LongBreak,
        Paused
    }

    property int state: Pomodoro.State.Idle
    property int previousRunningState: Pomodoro.State.Working  // tracks what was running before pause
    property int timeRemaining: workDuration   // seconds remaining
    property int totalTime: workDuration       // total duration of current segment
    property int completedPomodoros: 0
    property int currentCycle: 0               // current pomodoro in the cycle (0 .. pomodorosUntilLongBreak-1)

    // Computed properties
    readonly property string displayTime: formatTime(timeRemaining)
    readonly property real progress: totalTime > 0 ? (1 - timeRemaining / totalTime) : 0
    readonly property bool isRunning: state === Pomodoro.State.Working ||
                                     state === Pomodoro.State.ShortBreak ||
                                     state === Pomodoro.State.LongBreak
    readonly property bool isPaused: state === Pomodoro.State.Paused
    readonly property bool isOnBreak: state === Pomodoro.State.ShortBreak ||
                                     state === Pomodoro.State.LongBreak
    readonly property string stateLabel: {
        switch (state) {
            case Pomodoro.State.Working: return "Focus Time"
            case Pomodoro.State.ShortBreak: return "Short Break"
            case Pomodoro.State.LongBreak: return "Long Break"
            case Pomodoro.State.Paused: return "Paused"
            default: return "Ready"
        }
    }

    // ── Session-start timestamp (epoch seconds) for elapsed calculation ──
    property real _segmentStartEpoch: 0

    // ── Log file path ──
    readonly property string _logDir: Files.trimFileProtocol(`${Directories.state}`)
    readonly property string _logPath: `${_logDir}/pomodoro-sessions.jsonl`

    // ── Timer ──
    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: root.isRunning
        onTriggered: {
            if (root.timeRemaining > 0) {
                root.timeRemaining--
            } else {
                root.onTimerComplete()
            }
        }
    }

    // ── Sound ──
    Process {
        id: beepProcess
        running: false
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"]
    }

    // ── Helpers ──
    function formatTime(seconds: int): string {
        const mins = Math.floor(seconds / 60)
        const secs = seconds % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function _nowEpoch(): real {
        return Math.floor(Date.now() / 1000)
    }

    function _isoNow(): string {
        return new Date().toISOString()
    }

    function playBeep() {
        beepProcess.running = true
        Quickshell.execDetached(["sh", "-c",
            "paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || " +
            "aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || " +
            "beep 2>/dev/null || " +
            "paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null"
        ])
    }

    // ── Logging ──
    function _stateTypeString(s: int): string {
        switch (s) {
            case Pomodoro.State.Working:    return "focus"
            case Pomodoro.State.ShortBreak: return "shortBreak"
            case Pomodoro.State.LongBreak:  return "longBreak"
            default:                        return "idle"
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
        })
        Quickshell.execDetached(["sh", "-c",
            `mkdir -p '${_logDir}' && printf '%s\\n' '${entry}' >> '${_logPath}'`
        ])
    }

    // ── Actions ──
    function start() {
        if (state === Pomodoro.State.Idle) {
            startWork()
        } else if (isPaused) {
            resume()
        }
    }

    function startWork() {
        state = Pomodoro.State.Working
        previousRunningState = Pomodoro.State.Working
        timeRemaining = workDuration
        totalTime = workDuration
        _segmentStartEpoch = _nowEpoch()
        logEvent("started", Pomodoro.State.Working, workDuration, 0)
    }

    function pause() {
        if (isRunning) {
            previousRunningState = state
            state = Pomodoro.State.Paused
        }
    }

    function resume() {
        if (isPaused && timeRemaining > 0) {
            state = previousRunningState
        }
    }

    function stop() {
        if (state !== Pomodoro.State.Idle) {
            const elapsed = Math.round(_nowEpoch() - _segmentStartEpoch)
            const wasState = isPaused ? previousRunningState : state
            logEvent("stopped", wasState, totalTime, elapsed)
        }
        state = Pomodoro.State.Idle
        timeRemaining = workDuration
        totalTime = workDuration
        currentCycle = 0
    }

    function reset() {
        stop()
        completedPomodoros = 0
    }

    function skip() {
        if (isRunning || isPaused) {
            const elapsed = Math.round(_nowEpoch() - _segmentStartEpoch)
            const wasState = isPaused ? previousRunningState : state
            logEvent("skipped", wasState, totalTime, elapsed)
            _advanceAfterComplete(wasState)
        }
    }

    // ── Timer completion ──
    function onTimerComplete() {
        playBeep()

        const elapsed = totalTime  // ran to zero → full duration
        logEvent("completed", state, totalTime, elapsed)

        _advanceAfterComplete(state)
    }

    function _advanceAfterComplete(fromState: int) {
        if (fromState === Pomodoro.State.Working) {
            completedPomodoros++
            currentCycle++

            if (currentCycle >= pomodorosUntilLongBreak) {
                // Long break
                state = Pomodoro.State.LongBreak
                previousRunningState = Pomodoro.State.LongBreak
                timeRemaining = longBreakDuration
                totalTime = longBreakDuration
                currentCycle = 0
            } else {
                // Short break
                state = Pomodoro.State.ShortBreak
                previousRunningState = Pomodoro.State.ShortBreak
                timeRemaining = shortBreakDuration
                totalTime = shortBreakDuration
            }
            _segmentStartEpoch = _nowEpoch()
            logEvent("started", state, totalTime, 0)
        } else {
            // Break finished → go to Idle (user must click Start again)
            state = Pomodoro.State.Idle
            timeRemaining = workDuration
            totalTime = workDuration
        }
    }

    // ── Settings ──
    function setWorkDuration(minutes: int) {
        workDuration = minutes * 60
        if (state === Pomodoro.State.Idle) {
            timeRemaining = workDuration
            totalTime = workDuration
        }
    }

    function setShortBreakDuration(minutes: int) {
        shortBreakDuration = minutes * 60
    }

    function setLongBreakDuration(minutes: int) {
        longBreakDuration = minutes * 60
    }

    // ── Ensure log directory exists on startup ──
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", _logDir])
    }
}
