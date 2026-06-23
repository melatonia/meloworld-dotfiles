import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    // ── State ─────────────────────────────────────────────────────────────
    // workspaceList: plain JS array of { wsId, idx, isFocused, clientCount }
    // Assigned as a whole to trigger Repeater reactivity (no ListModel needed).
    property var workspaceList: []
    property int focusedTag: 1
    property bool canScroll: true

    // Internal lookup tables
    // workspaceIndexMap:  { workspaceId → idx (1-based) }
    // windowWorkspaceMap: { windowId   → workspaceId }
    property var workspaceIndexMap: ({})
    property var windowWorkspaceMap: ({})

    // ── Niri event stream socket ───────────────────────────────────────────
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

    // ── Model rebuild helpers ─────────────────────────────────────────────

    function _rebuildWorkspaces(wsList) {
        const indexMap = {}
        let focused = root.focusedTag

        const entries = []
        for (let i = 0; i < wsList.length; i++) {
            const ws = wsList[i]
            const idx = ws["idx"]
            if (idx === undefined || idx < 1) continue
            indexMap[ws["id"]] = idx
            if (ws["is_focused"]) focused = idx
            entries.push({
                wsId:       ws["id"],
                idx:        idx,
                isFocused:  ws["is_focused"] === true,
                clientCount: 0
            })
        }
        entries.sort((a, b) => a.idx - b.idx)

        root.workspaceIndexMap = indexMap
        root.focusedTag = focused
        root.workspaceList = entries   // single assignment → Repeater rebuilds once
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

    // Both _recomputeFocused and _recomputeClients rebuild the array from
    // scratch so that the assignment triggers a proper reactive update.
    // (Mutating elements of a var array in place does not notify QML.)

    function _recomputeFocused() {
        const focused = root.focusedTag
        const next = root.workspaceList.map(ws => Object.assign({}, ws, {
            isFocused: ws.idx === focused
        }))
        root.workspaceList = next
    }

    function _recomputeClients() {
        const indexMap = root.workspaceIndexMap
        const winMap   = root.windowWorkspaceMap

        // Count clients per idx
        const counts = {}
        for (const wid in winMap) {
            const wsId = winMap[wid]
            const idx  = indexMap[wsId]
            if (idx === undefined) continue
            counts[idx] = (counts[idx] || 0) + 1
        }

        const focused = root.focusedTag
        const next = root.workspaceList.map(ws => Object.assign({}, ws, {
            clientCount: counts[ws.idx] || 0,
            isFocused:   ws.idx === focused
        }))
        root.workspaceList = next
    }

    // ── Scroll throttle ───────────────────────────────────────────────────
    Timer {
        id: scrollThrottle
        interval: 30
        onTriggered: root.canScroll = true
    }

    // ── Delegates ─────────────────────────────────────────────────────────
    Repeater {
        model: root.workspaceList
        delegate: Rectangle {
            id: pill

            required property var modelData

            readonly property int  tagIdx:     modelData.idx
            readonly property bool isFocused:  modelData.isFocused
            readonly property bool hasClients: modelData.clientCount > 0
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
                text:           pill.tagIdx
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

                onClicked: root.focusWorkspaceByIndex(pill.tagIdx)

                onWheel: (event) => {
                    if (!root.canScroll) return

                    const visible = []
                    for (let i = 0; i < root.workspaceList.length; i++) {
                        const ws = root.workspaceList[i]
                        if (ws.isFocused || ws.clientCount > 0)
                            visible.push(ws.idx)
                    }
                    if (visible.length === 0) return

                    let pos = visible.indexOf(root.focusedTag)
                    if (pos === -1) pos = 0
                    pos = event.angleDelta.y < 0
                        ? Math.min(pos + 1, visible.length - 1)
                        : Math.max(pos - 1, 0)
                    root.focusWorkspaceByIndex(visible[pos])

                    root.canScroll = false
                    scrollThrottle.start()
                }
            }
        }
    }
}
