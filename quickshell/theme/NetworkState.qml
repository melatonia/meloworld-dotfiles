pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: true
    property bool connected: false
    property string activeSSID: ""
    property int activeSignal: 0
    property var networks: []
    property var knownSSIDs: []
    
    property bool connecting: false
    property string connectError: ""

    function refresh() {
        stateProc.running = false
        stateProc.running = true
        knownProc.running = false
        knownProc.running = true
        if (!scanProc.running) {
            scanProc.command = ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "no"]
            scanProc.running = true
        }
    }

    function rescan() {
        if (!scanProc.running) {
            scanProc.command = ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
            scanProc.running = true
        }
    }

    function toggleWifi() {
        if (wifiEnabled) {
            Quickshell.execDetached(["nmcli", "radio", "wifi", "off"])
            wifiEnabled = false
            activeSSID = ""
            activeSignal = 0
            networks = []
        } else {
            Quickshell.execDetached(["nmcli", "radio", "wifi", "on"])
            wifiEnabled = true
            rescanTimer.start()
        }
    }

    function connect(ssid, password) {
        var pw = password || ""
        connecting = true
        connectError = ""
        connectProc.ssid = ssid
        connectProc.pw = pw
        connectProc.running = false
        connectProc.running = true
    }

    Timer {
        id: rescanTimer
        interval: 1000
        onTriggered: root.rescan()
    }

    // ── Subscription Logic (The "Standard" way) ────
    Process {
        id: monitorProc
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                // Any change in NetworkManager triggers a refresh
                root.refresh()
            }
        }
    }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled"
            }
        }
    }

    // ── Data Fetching ──────────────────────────────

    Process {
        id: stateProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "dev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var hasWifi = false
                var activeConn = ""
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length >= 2) {
                        if (parts[0] === "wifi" && parts[1].indexOf("connected") !== -1) {
                            hasWifi = true
                            activeConn = parts.length > 2 ? parts[2] : ""
                        }
                    }
                }
                root.connected = hasWifi
                root.activeSSID = activeConn
            }
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "no"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.parseNetworks(text)
        }
    }

    function parseNetworks(rawText) {
        if (!rawText) return
        var lines = rawText.trim().split("\n")
        if (lines.length === 0 || (lines.length === 1 && lines[0] === "")) return
        
        var nets = []
        var foundActive = false
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            var parts = line.split(":")
            if (parts.length < 4) continue
            
            var active = parts[0] === "yes"
            var sig = parseInt(parts[parts.length - 2]) || 0
            var sec = parts[parts.length - 1]
            var ssid = parts.slice(1, parts.length - 2).join(":")
            
            if (ssid === "") continue
            
            if (active) {
                root.activeSSID = ssid
                root.activeSignal = sig
                foundActive = true
            } else {
                var exists = false
                for (var j = 0; j < nets.length; j++) {
                    if (nets[j].ssid === ssid) {
                        if (sig > nets[j].signal) {
                            nets[j].signal = sig
                            nets[j].security = sec
                        }
                        exists = true
                        break
                    }
                }
                if (!exists) {
                    nets.push({
                        ssid: ssid,
                        signal: sig,
                        security: sec,
                        known: root.knownSSIDs.indexOf(ssid) !== -1
                    })
                }
            }
        }
        
        if (!foundActive) {
            root.activeSignal = 0
        }
        
        nets.sort(function(a, b) { return b.signal - a.signal })
        root.networks = nets
    }

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "con", "show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var ssids = []
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length >= 2 && parts[1] === "802-11-wireless") {
                        ssids.push(parts[0])
                    }
                }
                root.knownSSIDs = ssids
            }
        }
    }

    Process {
        id: connectProc
        property string ssid: ""
        property string pw: ""
        onSsidChanged: updateCmd()
        onPwChanged: updateCmd()
        function updateCmd() {
            if (pw !== "") {
                command = ["nmcli", "dev", "wifi", "connect", ssid, "password", pw]
            } else {
                command = ["nmcli", "dev", "wifi", "connect", ssid]
            }
        }
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.connecting = false
                if (text.toLowerCase().indexOf("error") !== -1) {
                    if (text.indexOf("secrets") !== -1 || text.indexOf("password") !== -1) {
                        root.connectError = "Password required"
                    } else {
                        root.connectError = "Connection failed"
                    }
                } else {
                    root.connectError = ""
                    root.rescan()
                }
            }
        }
    }

    Connections {
        target: SessionState
        function onWifiPopupVisibleChanged() {
            if (SessionState.wifiPopupVisible) {
                pollTimer.interval = 5000
                pollTimer.restart()
                root.refresh()
                wifiStatusProc.running = true
            } else {
                pollTimer.interval = 15000
                pollTimer.restart()
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    
    Component.onCompleted: {
        root.refresh()
        root.rescan()
        wifiStatusProc.running = true
    }
}
