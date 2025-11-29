import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Media Player service using MPRIS
 * Provides access to currently playing media and player controls
 */
Singleton {
    id: root

    // Current active player (prioritizes playing/paused players)
    property MprisPlayer activePlayer: null

    // Convenience properties for the active player
    readonly property bool hasActivePlayer: activePlayer !== null
    readonly property string title: activePlayer?.metadata["xesam:title"] ?? ""
    readonly property string artist: activePlayer?.metadata["xesam:artist"] ?? ""
    readonly property string album: activePlayer?.metadata["xesam:album"] ?? ""
    readonly property string artUrl: activePlayer?.metadata["mpris:artUrl"] ?? ""
    readonly property int playbackState: activePlayer?.playbackState ?? MprisPlaybackState.Stopped
    readonly property bool canPlay: activePlayer?.canPlay ?? false
    readonly property bool canPause: activePlayer?.canPause ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0

    // Player identity
    readonly property string identity: activePlayer?.identity ?? ""

    // Formatted position/length for display
    readonly property string positionText: formatTime(position)
    readonly property string lengthText: formatTime(length)
    readonly property real progress: length > 0 ? position / length : 0

    // Playback state helpers
    readonly property bool isPlaying: playbackState === MprisPlaybackState.Playing
    readonly property bool isPaused: playbackState === MprisPlaybackState.Paused
    readonly property bool isStopped: playbackState === MprisPlaybackState.Stopped

    // Track the preferred player
    property MprisPlayer trackedPlayer: null

    // Monitor all available players using Instantiator
    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                // console.log("[MediaPlayer] Player registered:", modelData.identity)
                if (root.trackedPlayer == null || modelData.playbackState === MprisPlaybackState.Playing) {
                    root.trackedPlayer = modelData
                    // console.log("[MediaPlayer] Setting active player to:", modelData.identity)
                }
            }

            Component.onDestruction: {
                // console.log("[MediaPlayer] Player destroyed:", modelData.identity)
                // If our tracked player is destroyed, find a new one
                if (root.trackedPlayer === modelData) {
                    root.trackedPlayer = null
                    updateActivePlayer()
                }
            }

            function onPlaybackStateChanged() {
                // console.log("[MediaPlayer] Playback state changed for", modelData.identity, "to", modelData.playbackState)
                // If a player starts playing, make it tracked
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    root.trackedPlayer = modelData
                }
            }
        }
    }

    // Active player fallback: use tracked player or first available
    onTrackedPlayerChanged: {
        activePlayer = trackedPlayer ?? Mpris.players.values[0] ?? null
        // if (activePlayer) {
        //     console.log("[MediaPlayer] Active player changed to:", activePlayer.identity)
        // } else {
        //     console.log("[MediaPlayer] No active player")
        // }
    }

    // Update active player when current one's state changes
    Connections {
        target: activePlayer

        function onPlaybackStateChanged() {
            // console.log("[MediaPlayer] Active player state changed to", activePlayer.playbackState)
            // If current player stops, look for another playing one
            if (activePlayer && activePlayer.playbackState === MprisPlaybackState.Stopped) {
                updateActivePlayer()
            }
        }
    }

    // Select the most relevant active player
    function updateActivePlayer() {
        // console.log("[MediaPlayer] Updating active player, available players:", Mpris.players.values.length)

        if (!Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) {
            trackedPlayer = null
            return
        }

        // Priority: Playing > Paused > Any
        let playingPlayer = null
        let pausedPlayer = null
        let anyPlayer = null

        for (const player of Mpris.players.values) {
            if (!anyPlayer) anyPlayer = player

            if (player.playbackState === MprisPlaybackState.Playing) {
                playingPlayer = player
                break  // Highest priority, stop searching
            } else if (player.playbackState === MprisPlaybackState.Paused && !pausedPlayer) {
                pausedPlayer = player
            }
        }

        trackedPlayer = playingPlayer || pausedPlayer || anyPlayer
    }

    // Player controls
    function play() {
        if (activePlayer && canPlay) {
            activePlayer.play()
        }
    }

    function pause() {
        if (activePlayer && canPause) {
            activePlayer.pause()
        }
    }

    function playPause() {
        if (activePlayer) {
            if (isPlaying) {
                pause()
            } else {
                play()
            }
        }
    }

    function next() {
        if (activePlayer && canGoNext) {
            activePlayer.next()
        }
    }

    function previous() {
        if (activePlayer && canGoPrevious) {
            activePlayer.previous()
        }
    }

    function stop() {
        if (activePlayer) {
            activePlayer.stop()
        }
    }

    // Format time in seconds to MM:SS
    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"

        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Initialize
    Component.onCompleted: {
        updateActivePlayer()
    }
}
