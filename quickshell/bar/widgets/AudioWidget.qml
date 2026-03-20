import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.audio

    property int volume: 0
    property bool muted: false
    property string volStep: ""

    label: (muted || volume === 0) ? "󰝟" : "󰕾 " + volume + "%"

    function refresh() {
        volProc.running = true
        muteProc.running = true
    }

    Process {
	id: subscribeProc
    	command: ["pactl", "subscribe"]
    	running: true
    	stdout: SplitParser {
        onRead: (line) => {
            if (line.indexOf("sink") !== -1)
                root.refresh()
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
        command: ["pactl", "set-sink-volume", "@DEFAULT_SINK@", root.volStep]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.opacity = 0.85
        onExited:  root.opacity = 1.0
        onWheel: (wheel) => {
	    var newVol = wheel.angleDelta.y > 0
                ? Math.min(100, root.volume + 5)
            	: Math.max(0, root.volume - 5)
            root.volStep = newVol + "%"
            setVolProc.running = true
        }
    }
}
