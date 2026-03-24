import QtQuick
import Quickshell.Io
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.network
    property string ssid: ""
    property bool connected: false
    property int signal: 0

    label: {
        if (!connected) return "󰤭"
        if (ssid === "") return "󰈀 ETH"
        if (signal >= 80) return "󰤨 " + ssid.substring(0, 10)
        else if (signal >= 60) return "󰤥 " + ssid.substring(0, 10)
        else if (signal >= 40) return "󰤢 " + ssid.substring(0, 10)
        else if (signal >= 20) return "󰤟 " + ssid.substring(0, 10)
        else return "󰤯 " + ssid.substring(0, 10)
    }

    Process {
        id: refreshProc
        command: ["nmcli", "-g", "GENERAL.CONNECTION,GENERAL.STATE", "dev", "show", "wlp4s0"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const name = lines[0].trim()
                const state = lines[1].trim()
                root.connected = state.startsWith("100")
                root.ssid = root.connected ? name : ""
                if (root.connected) {
                    signalProc.running = true
                } else {
                    root.signal = 0
                    etherProc.running = true
                }
            }
        }
    }

    Process {
        id: signalProc
        command: ["nmcli", "-g", "ACTIVE,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                for (const line of lines) {
                    const parts = line.split(":")
                    if (parts[0] === "yes") {
                        root.signal = parseInt(parts[1]) || 0
                        return
                    }
                }
            }
        }
    }

    Process {
        id: etherProc
        command: ["cat", "/sys/class/net/eno1/operstate"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.connected = text.trim() === "up"
            }
        }
    }

    Process {
        id: nmtuiProc
        command: ["ghostty", "--title=nmtui", "-e", "nmtui"]
        running: false
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: refreshProc.running = true
    }

    mouseArea.onClicked: nmtuiProc.running = true
}
