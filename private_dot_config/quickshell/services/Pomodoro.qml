import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Pomodoro timer service with work/break intervals
 */
Singleton {
    id: root

    // Timer durations in seconds
    property int workDuration: 25 * 60    // 25 minutes
    property int shortBreakDuration: 5 * 60    // 5 minutes
    property int longBreakDuration: 15 * 60   // 15 minutes
    property int pomodorosUntilLongBreak: 4

    // Timer state
    enum State {
        Idle,
        Working,
        ShortBreak,
        LongBreak,
        Paused
    }

    property int state: Pomodoro.State.Idle
    property int timeRemaining: workDuration  // seconds remaining
    property int totalTime: workDuration      // total duration of current session
    property int completedPomodoros: 0
    property int currentCycle: 0  // Current pomodoro in the cycle (0-3)

    // Computed properties
    readonly property string displayTime: formatTime(timeRemaining)
    readonly property real progress: totalTime > 0 ? (1 - timeRemaining / totalTime) : 0
    readonly property bool isRunning: state === Pomodoro.State.Working ||
                                     state === Pomodoro.State.ShortBreak ||
                                     state === Pomodoro.State.LongBreak
    readonly property bool isPaused: state === Pomodoro.State.Paused
    readonly property string stateLabel: {
        switch (state) {
            case Pomodoro.State.Working: return "Focus Time"
            case Pomodoro.State.ShortBreak: return "Short Break"
            case Pomodoro.State.LongBreak: return "Long Break"
            case Pomodoro.State.Paused: return "Paused"
            default: return "Ready"
        }
    }

    // Timer
    Timer {
        id: timer
        interval: 1000
        repeat: true
        running: isRunning
        onTriggered: {
            if (timeRemaining > 0) {
                timeRemaining--
            } else {
                onTimerComplete()
            }
        }
    }

    // Sound player for notifications
    Process {
        id: beepProcess
        running: false
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"]
    }

    function formatTime(seconds) {
        const mins = Math.floor(seconds / 60)
        const secs = seconds % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function playBeep() {
        // Try to play system sound, fallback to beep command
        beepProcess.running = true

        // Also try aplay as fallback
        Quickshell.execDetached(["sh", "-c",
            "paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || " +
            "aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || " +
            "beep 2>/dev/null || " +
            "paplay /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null"
        ])
    }

    function start() {
        if (state === Pomodoro.State.Idle) {
            startWork()
        } else if (isPaused) {
            // Resume from pause
            if (timeRemaining > 0) {
                state = timer.running ? state : Pomodoro.State.Working
            }
        }
    }

    function startWork() {
        state = Pomodoro.State.Working
        timeRemaining = workDuration
        totalTime = workDuration
    }

    function pause() {
        if (isRunning) {
            state = Pomodoro.State.Paused
        }
    }

    function resume() {
        if (isPaused && timeRemaining > 0) {
            // Restore previous state based on what we were doing
            if (currentCycle >= pomodorosUntilLongBreak - 1 && completedPomodoros > 0) {
                state = Pomodoro.State.LongBreak
            } else if (completedPomodoros > 0) {
                state = Pomodoro.State.ShortBreak
            } else {
                state = Pomodoro.State.Working
            }
        }
    }

    function stop() {
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
            onTimerComplete()
        }
    }

    function onTimerComplete() {
        playBeep()

        if (state === Pomodoro.State.Working) {
            completedPomodoros++
            currentCycle++

            // Determine next break type
            if (currentCycle >= pomodorosUntilLongBreak) {
                // Time for long break
                state = Pomodoro.State.LongBreak
                timeRemaining = longBreakDuration
                totalTime = longBreakDuration
                currentCycle = 0
            } else {
                // Short break
                state = Pomodoro.State.ShortBreak
                timeRemaining = shortBreakDuration
                totalTime = shortBreakDuration
            }
        } else {
            // Break finished, start next work session
            startWork()
        }
    }

    // Settings functions
    function setWorkDuration(minutes) {
        workDuration = minutes * 60
        if (state === Pomodoro.State.Idle) {
            timeRemaining = workDuration
            totalTime = workDuration
        }
    }

    function setShortBreakDuration(minutes) {
        shortBreakDuration = minutes * 60
    }

    function setLongBreakDuration(minutes) {
        longBreakDuration = minutes * 60
    }
}
