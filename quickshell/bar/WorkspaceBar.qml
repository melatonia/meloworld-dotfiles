import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    // ── State (9 slots, index = workspaceIdx - 1) ─────────────────────────
    property var tagFocused: [false, false, false, false, false, false, false, false, false, false]
    property var tagClients: [0,     0,     0,     0,     0,     0,     0,     0,     0,    0]
    property int focusedTag: 1
    property bool canScroll: true

    // Internal lookup tables
    // workspaceIndexMap:  { workspaceId → idx (1-based) }
    // windowWorkspaceMap: { windowId   → workspaceId }
    property var workspaceIndexMap: ({})
    property var windowWorkspaceMap: ({})

    // ── Niri event stream socket (read-only after EventStream) ────────────
    // After sending "EventStream", niri stops reading this socket entirely.
    // All actions MUST go through a separate process (niri msg).
    Socket {
        id: eventSocket

        readonly property string socketPath: Quickshell.env("NIRI_SOCKET")

        path: socketPath
        connected: socketPath !== ""

        onConnectedChanged: {
            if (connected) {
                eventSocket.write('"EventStream"\n')
            } else {
                eventReconnectTimer.start()
            }
        }

        parser: SplitParser {
            onRead: (line) => {
                const trimmed = line.trim()
                if (trimmed.length === 0) return
                try {
                    root.handleNiriEvent(JSON.parse(trimmed))
                } catch (e) {
                    console.warn("WorkspaceBar: JSON parse error:", e, "raw:", trimmed)
                }
            }
        }
    }

    Timer {
        id: eventReconnectTimer
        interval: 1000
        onTriggered: eventSocket.connected = eventSocket.socketPath !== ""
    }

    // ── Action: focus workspace by 1-based index ──────────────────────────
    // Correct CLI syntax: niri msg action focus-workspace N  (no --index flag)
    function focusWorkspaceByIndex(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)])
    }

    // ── Event handler ─────────────────────────────────────────────────────
    function handleNiriEvent(ev) {
        if (ev["WorkspacesChanged"] !== undefined) {
            _rebuildWorkspaces(ev["WorkspacesChanged"]["workspaces"])

        } else if (ev["WorkspaceActivated"] !== undefined) {
            const data = ev["WorkspaceActivated"]
            if (data["focused"]) {
                const idx = root.workspaceIndexMap[data["id"]]
                if (idx !== undefined) {
                    root.focusedTag = idx
                    _recomputeFocused()
                }
            }

        } else if (ev["WindowsChanged"] !== undefined) {
            _rebuildWindows(ev["WindowsChanged"]["windows"])

        } else if (ev["WindowOpenedOrChanged"] !== undefined) {
            const w = ev["WindowOpenedOrChanged"]["window"]
            if (w["workspace_id"] !== undefined) {
                const map = Object.assign({}, root.windowWorkspaceMap)
                map[w["id"]] = w["workspace_id"]
                root.windowWorkspaceMap = map
                _recomputeClients()
            }

        } else if (ev["WindowClosed"] !== undefined) {
            const map = Object.assign({}, root.windowWorkspaceMap)
            delete map[ev["WindowClosed"]["id"]]
            root.windowWorkspaceMap = map
            _recomputeClients()
        }
    }

    function _rebuildWorkspaces(workspaces) {
        const indexMap = {}
        let focused = root.focusedTag

        for (let i = 0; i < workspaces.length; i++) {
            const ws = workspaces[i]
            const idx = ws["idx"]
            if (idx === undefined || idx < 1 || idx > 10) continue
            indexMap[ws["id"]] = idx
            if (ws["is_focused"]) focused = idx
        }

        root.workspaceIndexMap = indexMap
        root.focusedTag = focused
        _recomputeFocused()
        _recomputeClients()
    }

    function _rebuildWindows(windows) {
        const map = {}
        for (let i = 0; i < windows.length; i++) {
            const w = windows[i]
            if (w["workspace_id"] !== undefined)
                map[w["id"]] = w["workspace_id"]
        }
        root.windowWorkspaceMap = map
        _recomputeClients()
    }

    function _recomputeFocused() {
        const f = [false, false, false, false, false, false, false, false, false, false]
        const focused = root.focusedTag
        if (focused >= 1 && focused <= 10) f[focused - 1] = true
        root.tagFocused = f
    }

    function _recomputeClients() {
        const c        = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        const indexMap = root.workspaceIndexMap
        const winMap   = root.windowWorkspaceMap
        for (const wid in winMap) {
            const wsId = winMap[wid]
            const idx  = indexMap[wsId]
            if (idx >= 1 && idx <= 10) c[idx - 1]++
        }
        root.tagClients = c
    }

    // ── Scroll throttle ───────────────────────────────────────────────────
    Timer {
        id: scrollThrottle
        interval: 30
        onTriggered: root.canScroll = true
    }

    // ── Delegates ─────────────────────────────────────────────────────────
    Repeater {
        model: 10
        delegate: Rectangle {
            id: pill

            required property int modelData

            readonly property int  tagNum:     modelData + 1
            readonly property bool isFocused:  root.tagFocused[modelData]
            readonly property bool hasClients: root.tagClients[modelData] > 0
            readonly property bool shouldShow: isFocused || hasClients
            property bool hovered: false

            visible: width > 0
            width: shouldShow ? 28 : 0
            Behavior on width {
                SmoothedAnimation { velocity: 120; easing.type: Easing.OutExpo }
            }

            height: 28
            radius: 5

            color: {
                if (isFocused) return hovered
                    ? Qt.lighter(PanelColors.workspaceActive, 1.15)
                    : PanelColors.workspaceActive
                return hovered
                    ? Qt.lighter(PanelColors.workspaceInactive, 1.4)
                    : PanelColors.workspaceInactive
            }
            Behavior on color { ColorAnimation { duration: 150 } }

            clip: true

            Text {
                anchors.centerIn: parent
                text:           pill.tagNum
                color:          pill.isFocused ? PanelColors.pillForeground : PanelColors.textDim
                font.pixelSize: 16
                font.bold:      true
                font.family:    "JetBrainsMono Nerd Font"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: pill.hovered = true
                onExited:  pill.hovered = false

                onClicked: root.focusWorkspaceByIndex(pill.tagNum)

                onWheel: (event) => {
                    if (!root.canScroll) return

                    const visible = []
                    for (let i = 0; i < 10; i++) {
                        if (root.tagFocused[i] || root.tagClients[i] > 0)
                            visible.push(i + 1)
                    }
                    if (visible.length === 0) return

                    let idx = visible.indexOf(root.focusedTag)
                    if (idx === -1) idx = 0
                    idx = event.angleDelta.y < 0
                        ? Math.min(idx + 1, visible.length - 1)
                        : Math.max(idx - 1, 0)
                    root.focusWorkspaceByIndex(visible[idx])

                    root.canScroll = false
                    scrollThrottle.start()
                }
            }
        }
    }
}
