pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int brightness: 0
    property bool popupVisible: false

    function setBrightness(value) {
        let val = Math.round(value)
        Quickshell.execDetached(["brightnessctl", "set", val + "%"])
        brightness = val
    }

    function show() {
        popupVisible = true
    }

    function hide() {
        popupVisible = false
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
                        root.brightness = Math.round((raw / max) * 100)
                    }
                }
            }
        }
    }

    Timer {
        id: udevRestartTimer
        interval: 1000
        onTriggered: udevProc.running = true
    }

    Process {
        id: udevProc
        command: ["udevadm", "monitor", "-s", "backlight"]
        running: true
        onRunningChanged: {
            if (!running) udevRestartTimer.start()
        }
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("change") !== -1) {
                    brightnessProc.running = true
                }
            }
        }
    }
}
