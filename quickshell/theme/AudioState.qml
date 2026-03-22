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

    function show() {
        refresh()
        popupVisible = true
    }
    function hide() {
        popupVisible = false
    }
    function refresh() {
        sinksProc.running = true
        sourcesProc.running = true
        defaultSinkProc.running = true
        defaultSourceProc.running = true
        volProc.running = true
        muteProc.running = true
        micVolProc.running = true
    }
    function setDefaultSink(name) {
        setSinkProc.sinkName = name
        setSinkProc.running = true
        defaultSink = name
    }
    function setDefaultSource(name) {
        setSourceProc.sourceName = name
        setSourceProc.running = true
        defaultSource = name
    }
    function setVolume(newVol) {
        setVolProc.step = newVol + "%"
        setVolProc.running = true
    }
    function setMicVolume(newVol) {
        setMicVolProc.step = newVol + "%"
        setMicVolProc.running = true
    }

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

    Process {
        id: setSinkProc
        property string sinkName: ""
        command: ["pactl", "set-default-sink", sinkName]
        running: false
    }

    Process {
        id: setSourceProc
        property string sourceName: ""
        command: ["pactl", "set-default-source", sourceName]
        running: false
    }

    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("sink") !== -1) {
                    sinksProc.running = true
                    defaultSinkProc.running = true
                    volProc.running = true
                    muteProc.running = true
                }
                if (line.indexOf("source") !== -1) {
                    sourcesProc.running = true
                    defaultSourceProc.running = true
                    micVolProc.running = true
                }
            }
        }
    }

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

    Process {
        id: setVolProc
        property string step: ""
        command: ["pactl", "set-sink-volume", "@DEFAULT_SINK@", step]
        running: false
    }

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

    Process {
        id: setMicVolProc
        property string step: ""
        command: ["pactl", "set-source-volume", "@DEFAULT_SOURCE@", step]
        running: false
    }
}
