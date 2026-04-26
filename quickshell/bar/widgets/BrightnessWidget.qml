import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.brightness
    property int brightness: 0
    property int maxBrightness: 0
    property int rawBrightness: 0

    function updateBrightness() {
        if (maxBrightness > 0 && rawBrightness > 0)
            brightness = Math.round((rawBrightness / maxBrightness) * 100)
    }

    label: {
        if (brightness >= 80) return "󰃠 " + brightness + "%"
        else if (brightness >= 40) return "󰃟 " + brightness + "%"
        else return "󰃞 " + brightness + "%"
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "info", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 5) {
                    const raw = parseInt(parts[2])
                    const max = parseInt(parts[4])
                    if (!isNaN(raw) && !isNaN(max) && max > 0) {
                        root.rawBrightness = raw
                        root.maxBrightness = max
                        root.updateBrightness()
                    }
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: brightnessProc.running = true
    }

    mouseArea.onWheel: (wheel) => {
        let step = wheel.angleDelta.y > 0 ? "+5%" : "-5%"
        Quickshell.execDetached(["brightnessctl", "set", step])
        brightnessProc.running = true
    }
}
