import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.network

    property string mode: "none"
    property int strength: 0
    property string ssid: ""

    label: {
        if (mode === "wifi") {
            var sym = ""
            if (strength >= 80) sym = "󰤨"
            else if (strength >= 60) sym = "󰤥"
            else if (strength >= 40) sym = "󰤢"
            else if (strength >= 20) sym = "󰤟"
            else sym = "󰤯"
            return sym + " " + ssid.substring(0, 8)
        } else if (mode === "ethernet") {
            return "󰈀 ETH"
        } else {
            return "󰤭"
        }
    }

    function refresh() {
        modeProc.running = true
    }

    Process {
        id: modeProc
        command: ["sh", "-c", "cat /sys/class/net/wlp4s0/operstate 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "up") {
                    root.mode = "wifi"
                    strengthProc.running = true
                    ssidProc.running = true
                } else {
                    etherProc.running = true
                }
            }
        }
    }

    Process {
        id: etherProc
        command: ["sh", "-c", "cat /sys/class/net/eno1/operstate 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.mode = text.trim() === "up" ? "ethernet" : "none"
            }
        }
    }

    Process {
        id: strengthProc
        command: ["sh", "-c", "awk 'NR==3 {printf \"%3.0f\", ($3/70)*100}' /proc/net/wireless"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim())
                root.strength = isNaN(val) ? 0 : Math.min(100, val)
            }
        }
    }

    Process {
        id: ssidProc
        command: ["sh", "-c", "iw dev wlp4s0 link | awk '/SSID:/ {print $2}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.ssid = text.trim()
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
