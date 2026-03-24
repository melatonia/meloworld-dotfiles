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
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "dev"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let hasWifi = false
                let hasEth = false
                let activeSsid = ""
                
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(":")
                    if (parts.length >= 2) {
                        const type = parts[0]
                        const state = parts[1]
                        const conn = parts.length > 2 ? parts[2] : ""
                        
                        if (state.startsWith("connected")) {
                            if (type === "wifi") {
                                hasWifi = true
                                activeSsid = conn
                            } else if (type === "ethernet") {
                                hasEth = true
                            }
                        }
                    }
                }
                
                if (hasWifi) {
                    root.connected = true
                    root.ssid = activeSsid
                    signalProc.running = true
                } else if (hasEth) {
                    root.connected = true
                    root.ssid = ""
                    root.signal = 0
                } else {
                    root.connected = false
                    root.ssid = ""
                    root.signal = 0
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
