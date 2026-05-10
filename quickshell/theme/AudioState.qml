pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool popupVisible: false
    property var sinks: []
    property var sources: []
    property string defaultSink: ""
    property string defaultSource: ""
    property int volume: 0
    property bool muted: false
    property int micVolume: 0
    property bool micMuted: false

    function show() {
        SessionState.closeAllPopups()
        refresh()
        popupVisible = true
    }

    function hide() {
        popupVisible = false
    }

    function refresh() {
        if (!sinksProc.running)         sinksProc.running = true
        if (!sourcesProc.running)       sourcesProc.running = true
        if (!defaultSinkProc.running)   defaultSinkProc.running = true
        if (!defaultSourceProc.running) defaultSourceProc.running = true
        if (!volProc.running)           volProc.running = true
        if (!muteProc.running)          muteProc.running = true
        if (!micVolProc.running)        micVolProc.running = true
        if (!micMuteProc.running)       micMuteProc.running = true
    }

    function setDefaultSink(name) {
        Quickshell.execDetached(["pactl", "set-default-sink", name])
        defaultSink = name
    }

    function setDefaultSource(name) {
        Quickshell.execDetached(["pactl", "set-default-source", name])
        defaultSource = name
    }

    function setVolume(newVol) {
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", newVol + "%"])
    }

    function setMicVolume(newVol) {
        Quickshell.execDetached(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", newVol + "%"])
    }

    function setMute(mute) {
        Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", mute ? "1" : "0"])
        root.muted = mute
    }

    function setMicMute(mute) {
        Quickshell.execDetached(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", mute ? "1" : "0"])
        root.micMuted = mute
    }

    // ── Sink list ─────────────────────────────────
    Process {
        id: sinksProc
        command: ["pactl", "list", "sinks"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var result = []
                var current = {}
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.startsWith("Name:")) {
                        if (current.name) result.push(current)
                        current = { name: line.replace("Name:", "").trim() }
                    } else if (line.startsWith("Description:")) {
                        current.description = line.replace("Description:", "").trim()
                    }
                }
                if (current.name) result.push(current)
                root.sinks = result.filter(s => !s.name.includes(".monitor"))
            }
        }
    }

    // ── Source list ───────────────────────────────
    Process {
        id: sourcesProc
        command: ["pactl", "list", "sources"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var result = []
                var current = {}
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line.startsWith("Name:")) {
                        if (current.name) result.push(current)
                        current = { name: line.replace("Name:", "").trim() }
                    } else if (line.startsWith("Description:")) {
                        current.description = line.replace("Description:", "").trim()
                    }
                }
                if (current.name) result.push(current)
                root.sources = result.filter(s => !s.name.includes(".monitor"))
            }
        }
    }

    // ── Default sink/source ───────────────────────
    Process {
        id: defaultSinkProc
        command: ["pactl", "get-default-sink"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.defaultSink = text.trim()
        }
    }

    Process {
        id: defaultSourceProc
        command: ["pactl", "get-default-source"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.defaultSource = text.trim()
        }
    }

    // ── Subscribe to changes ──────────────────────
    Timer {
        id: subRestartTimer
        interval: 1000
        onTriggered: subscribeProc.running = true
    }

    Timer {
        id: debounceTimer
        interval: 50
        running: false
        repeat: false
        property bool sinkChanged: false
        property bool sourceChanged: false
        onTriggered: {
            if (sinkChanged) {
                if (!sinksProc.running)       sinksProc.running = true
                if (!defaultSinkProc.running) defaultSinkProc.running = true
                if (!volProc.running)         volProc.running = true
                if (!muteProc.running)        muteProc.running = true
                sinkChanged = false
            }
            if (sourceChanged) {
                if (!sourcesProc.running)       sourcesProc.running = true
                if (!defaultSourceProc.running) defaultSourceProc.running = true
                if (!micVolProc.running)        micVolProc.running = true
                if (!micMuteProc.running)       micMuteProc.running = true
                sourceChanged = false
            }
        }
    }

    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        running: true
        onRunningChanged: {
            if (!running) {
                subRestartTimer.start()
            }
        }
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("sink") !== -1) {
                    debounceTimer.sinkChanged = true
                    debounceTimer.restart()
                }
                if (line.indexOf("source") !== -1) {
                    debounceTimer.sourceChanged = true
                    debounceTimer.restart()
                }
            }
        }
    }

    // ── Volume ────────────────────────────────────
    Process {
        id: volProc
        command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/(\d+)%/)
                if (match) root.volume = parseInt(match[1])
            }
        }
    }

    // ── Mute ──────────────────────────────────────
    Process {
        id: muteProc
        command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.muted = text.indexOf("yes") !== -1
            }
        }
    }

    // ── Mic volume ────────────────────────────────
    Process {
        id: micVolProc
        command: ["pactl", "get-source-volume", "@DEFAULT_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/(\d+)%/)
                if (match) root.micVolume = parseInt(match[1])
            }
        }
    }

    // ── Mic mute ──────────────────────────────────
    Process {
        id: micMuteProc
        command: ["pactl", "get-source-mute", "@DEFAULT_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.micMuted = text.indexOf("yes") !== -1
            }
        }
    }
}
