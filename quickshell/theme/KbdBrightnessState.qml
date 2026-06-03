pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// brightnessctl --list --machine-readable format (verified from source):
//   printf("%s,%s,%d,%d%%,%d\n", dev->id, dev->class, curr, curr_pct, max)
//   columns → 0:id  1:class  2:curr  3:curr%  4:max
Singleton {
    id: root

    property bool   available:     false
    property string deviceName:    ""
    property int    brightness:    0
    property int    maxBrightness: 0

    // ── Detection — runs once at startup ──────────────────────────────────────
    Process {
        id: detectProc
        command: ["brightnessctl", "--list", "--machine-readable"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                for (const line of lines) {
                    const parts = line.trim().split(",")
                    if (parts.length < 5) continue
                    const id  = parts[0]
                    const cls = parts[1]
                    const cur = parseInt(parts[2], 10)
                    // parts[3] is "curr%" with literal % — skip it
                    const max = parseInt(parts[4], 10)
                    if (cls === "leds" && id.includes("kbd_backlight")) {
                        root.deviceName    = id
                        root.maxBrightness = max
                        root.brightness    = cur
                        root.available     = true
                        break
                    }
                }
            }
        }
    }

    // ── Read — syncs after external Fn-key changes ────────────────────────────
    Process {
        id: readProc
        command: ["brightnessctl", "-d", root.deviceName, "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(this.text.trim(), 10)
                if (!isNaN(val)) root.brightness = val
            }
        }
    }

    // ── Write ─────────────────────────────────────────────────────────────────
    // running must be toggled false→true each call; setting true on a completed
    // Process is a no-op in Quickshell.
    Process {
        id: writeProc
        command: []
        running: false
    }

    // ── Poll — keeps slider honest after Fn-key presses ───────────────────────
    // 1 s is sufficient; tighter polling just wastes forks.
    // Guard against firing during an active write to avoid fighting the user.
    Timer {
        interval: 1000
        repeat: true
        running: root.available
        onTriggered: {
            if (!writeProc.running) {
                readProc.running = false
                readProc.running = true
            }
        }
    }

    // ── API ───────────────────────────────────────────────────────────────────
    function setBrightness(val) {
        if (!root.available) return
        const v = Math.max(0, Math.min(root.maxBrightness, Math.round(val)))
        root.brightness = v
        writeProc.running = false
        writeProc.command = ["brightnessctl", "-d", root.deviceName, "set", String(v)]
        writeProc.running = true
    }

    function refresh() {
        if (!root.available) return
        readProc.running = false
        readProc.running = true
    }
}
