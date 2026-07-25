pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.modules.common

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(node => node.audio !== null && node.isSink && !node.isStream)
    readonly property string sinkName: displayName(sink)

    signal sinkProtectionTriggered(string reason)

    onSinkChanged: {
        sinkAudioConnections.lastReady = false;
        sinkAudioConnections.lastVolume = 0;
    }

    function displayName(node: PwNode): string {
        if (!node)
            return "No output device";

        return node.description || node.nickname || node.name || "Unknown output device";
    }

    function setDefaultSink(node: PwNode): void {
        if (!node || !root.sinks.includes(node))
            return;

        Pipewire.preferredDefaultAudioSink = node;
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        id: sinkAudioConnections

        readonly property PwNodeAudio audio: root.sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        target: audio

        function onVolumeChanged() {
            const audio = sinkAudioConnections.audio;
            if (!audio)
                return;

            if (!Config.options.audio.protection.enable) {
                lastVolume = audio.volume;
                lastReady = true;
                return;
            }
            if (!lastReady) {
                lastVolume = audio.volume;
                lastReady = true;
                return;
            }
            const newVolume = audio.volume;
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100;
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                audio.volume = lastVolume;
                root.sinkProtectionTriggered("Illegal increment");
            } else if (newVolume > maxAllowed) {
                audio.volume = Math.min(lastVolume, maxAllowed);
                root.sinkProtectionTriggered("Exceeded max allowed");
            }
            lastVolume = audio.volume;
        }
    }
}
