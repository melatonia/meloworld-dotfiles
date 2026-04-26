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

    property bool isScanning: scanProc.running

    // Tracks whether the current/last scan was a hardware rescan.
    // Replaces the brittle scanProc.command.indexOf() pattern.
    property bool _isHardwareScan: false

    // Silent state check (doesn't touch the wifi list)
    function checkState() {
        stateProc.running = false
        stateProc.running = true

        wifiStatusProc.running = false
        wifiStatusProc.running = true

        if (!knownProc.running) {
            knownProc.running = true
        }
    }

    // Refresh the list (cache-only scan)
    function refresh() {
        checkState()

        // Only do a cache scan if the popup is CLOSED.
        // If it's open, the hardware loop has exclusive control.
        if (!scanProc.running && !SessionState.wifiPopupVisible) {
            root._isHardwareScan = false
            scanProc.command = ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "no"]
            scanProc.running = true
        }
    }

    // Force a hardware scan
    function rescan() {
        // Kill any pending cache scan to make room for the hardware scan
        if (scanProc.running && !root._isHardwareScan) {
            scanProc.running = false
        }

        if (!scanProc.running) {
            root._isHardwareScan = true
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

    Process {
        id: monitorProc
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                // Monitor only updates connection state, not the full scan list.
                // This prevents "cache poisoning" where old networks re-enter the list.
                root.checkState()
            }
        }
    }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text || ""
                root.wifiEnabled = raw.trim() === "enabled"
            }
        }
    }

    Process {
        id: stateProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "dev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text || ""
                var lines = raw.trim().split("\n")
                var hasWifi = false
                var activeConn = ""
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length >= 2) {
                        var type = parts[0].trim()
                        var state = parts[1].trim()
                        if (type === "wifi" && state.indexOf("connected") !== -1) {
                            hasWifi = true
                            activeConn = parts.length > 2 ? parts[2].trim() : ""
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
            onStreamFinished: {
                root.parseNetworks(text)

                // Loop while the popup is open
                if (SessionState.wifiPopupVisible && wifiEnabled) {
                    loopTimer.start()
                }
            }
        }
    }

    Timer {
        id: loopTimer
        interval: 4000
        repeat: false
        onTriggered: {
            if (SessionState.wifiPopupVisible && wifiEnabled) {
                root.rescan()
            }
        }
    }

    function parseNetworks(rawText) {
        var raw = rawText || ""
        var rawLines = raw.trim().split("\n")

        if ((raw.trim() === "" || rawLines.length === 0) && wifiEnabled) {
            root.networks = []
            return
        }

        var nets = []
        var foundActive = false

        for (var i = 0; i < rawLines.length; i++) {
            var line = rawLines[i]
            var parts = line.split(":")
            if (parts.length < 4) continue

            var active = parts[0].trim() === "yes"
            var sig    = parseInt(parts[parts.length - 2]) || 0
            var sec    = parts[parts.length - 1].trim()
            var ssid   = parts.slice(1, parts.length - 2).join(":").trim()

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
                            nets[j].signal   = sig
                            nets[j].security = sec
                        }
                        exists = true
                        break
                    }
                }
                if (!exists) {
                    nets.push({
                        ssid:     ssid,
                        signal:   sig,
                        security: sec,
                        known:    root.knownSSIDs.indexOf(ssid) !== -1
                    })
                }
            }
        }

        if (!foundActive) {
            root.activeSignal = 0
            // Only clear activeSSID when we have a hardware scan result we trust
            if (root.activeSSID !== "" && root._isHardwareScan) {
                root.activeSSID = ""
            }
        }

        nets.sort(function(a, b) { return b.signal - a.signal })

        // Stability check — only reassign if something changed
        if (root.networks.length !== nets.length) {
            root.networks = nets
        } else {
            var changed = false
            for (var k = 0; k < nets.length; k++) {
                if (nets[k].ssid   !== root.networks[k].ssid   ||
                    nets[k].signal !== root.networks[k].signal  ||
                    nets[k].known  !== root.networks[k].known) {
                    changed = true
                    break
                }
            }
            if (changed) root.networks = nets
        }
    }

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "con", "show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text || ""
                var lines = raw.trim().split("\n")
                var ssids = []
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    var parts = line.split(":")
                    if (parts.length >= 2) {
                        var name = parts[0].trim()
                        var type = parts[1].trim()
                        if (type === "802-11-wireless") ssids.push(name)
                    }
                }
                root.knownSSIDs = ssids

                var currentNets = root.networks
                for (var k = 0; k < currentNets.length; k++) {
                    currentNets[k].known = ssids.indexOf(currentNets[k].ssid) !== -1
                }
                root.networks = currentNets
            }
        }
    }

    Process {
        id: connectProc
        property string ssid: ""
        property string pw:   ""
        onSsidChanged: { updateCmd() }
        onPwChanged:   { updateCmd() }
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
                var raw = text || ""
                root.connecting = false
                if (raw.toLowerCase().indexOf("error") !== -1) {
                    if (raw.indexOf("secrets") !== -1 || raw.indexOf("password") !== -1) {
                        root.connectError = "Password required"
                    } else {
                        root.connectError = "Connection failed"
                    }
                } else {
                    root.connectError = ""
                    var currentKnown = root.knownSSIDs
                    if (currentKnown.indexOf(connectProc.ssid) === -1) {
                        currentKnown.push(connectProc.ssid)
                        root.knownSSIDs = currentKnown
                    }
                    var currentNets = root.networks
                    for (var i = 0; i < currentNets.length; i++) {
                        if (currentNets[i].ssid === connectProc.ssid) {
                            currentNets[i].known = true
                        }
                    }
                    root.networks = currentNets
                    root.refresh()
                }
            }
        }
    }

    Connections {
        target: SessionState
        function onWifiPopupVisibleChanged() {
            if (SessionState.wifiPopupVisible) {
                // Kill any pending cache scan so the hardware scan starts clean
                scanProc.running = false
                root.rescan()
            }
        }
    }

    // Background refresh every 30 s when the popup is closed
    Timer {
        id: backgroundTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            if (!SessionState.wifiPopupVisible) root.refresh()
        }
    }

    Component.onCompleted: {
        root.rescan()
    }
}
