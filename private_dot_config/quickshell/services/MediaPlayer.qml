pragma Singleton
pragma ComponentBehavior: Bound
import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property MprisPlayer trackedPlayer: null
    property MprisPlayer activePlayer: null

    readonly property bool hasActivePlayer: activePlayer !== null
    readonly property string title: activePlayer?.metadata["xesam:title"] ?? ""
    readonly property string artist: activePlayer?.metadata["xesam:artist"] ?? ""
    readonly property string album: activePlayer?.metadata["xesam:album"] ?? ""
    readonly property string artUrl: activePlayer?.metadata["mpris:artUrl"] ?? ""
    readonly property string identity: activePlayer?.identity ?? ""
    readonly property int playbackState: activePlayer?.playbackState ?? MprisPlaybackState.Stopped
    readonly property bool isPlaying: playbackState === MprisPlaybackState.Playing
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false

    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property string positionText: formatTime(position)
    readonly property string lengthText: formatTime(length)
    readonly property real progress: length > 0 ? position / length : 0

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                if (root.trackedPlayer == null || modelData.playbackState === MprisPlaybackState.Playing) {
                    root.trackedPlayer = modelData;
                }
            }

            Component.onDestruction: {
                if (root.trackedPlayer === modelData) {
                    root.trackedPlayer = null;
                    root.updateActivePlayer();
                }
            }

            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    root.trackedPlayer = modelData;
                }
            }
        }
    }

    onTrackedPlayerChanged: {
        activePlayer = trackedPlayer ?? Mpris.players.values[0] ?? null;
    }

    Connections {
        target: activePlayer

        function onPlaybackStateChanged() {
            if (activePlayer && activePlayer.playbackState === MprisPlaybackState.Stopped) {
                root.updateActivePlayer();
            }
        }
    }

    function updateActivePlayer() {
        const players = Mpris.players?.values ?? [];
        if (players.length === 0) {
            trackedPlayer = null;
            return;
        }

        let pausedPlayer = null;
        for (const player of players) {
            if (player.playbackState === MprisPlaybackState.Playing) {
                trackedPlayer = player;
                return;
            }
            if (player.playbackState === MprisPlaybackState.Paused && !pausedPlayer) {
                pausedPlayer = player;
            }
        }

        trackedPlayer = pausedPlayer ?? players[0];
    }

    function playPause() {
        if (!activePlayer)
            return;
        if (isPlaying) {
            if (activePlayer.canPause)
                activePlayer.pause();
        } else if (activePlayer.canPlay) {
            activePlayer.play();
        }
    }

    function next() {
        if (activePlayer && canGoNext)
            activePlayer.next();
    }

    function previous() {
        if (activePlayer && canGoPrevious)
            activePlayer.previous();
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0)
            return "0:00";

        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    Component.onCompleted: updateActivePlayer()
}
