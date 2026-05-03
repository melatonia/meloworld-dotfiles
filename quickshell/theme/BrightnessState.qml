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
        interval: 500
        running: true
        repeat: true
        onTriggered: brightnessProc.running = true
    }
}
