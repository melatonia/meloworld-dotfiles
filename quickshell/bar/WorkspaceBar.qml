import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    // ── Backend detection ─────────────────────────────────────────────────────
    // Hyprland.requestSocketPath is an empty string when not running under
    // Hyprland. This is synchronous, deterministic, and has no race condition.
    readonly property bool isHyprland: Hyprland.requestSocketPath !== ""

    // ── Shared visual state ───────────────────────────────────────────────────
    property var tagFocused: [false, false, false, false, false, false, false, false, false]
    property var tagClients: [0, 0, 0, 0, 0, 0, 0, 0, 0]
    property int focusedTag: 1
    property bool canScroll: true

    // ── Hyprland: reactive state ──────────────────────────────────────────────
    // Both workspace-list changes (open/close window) and focusedWorkspace
    // changes (switch workspace) are caught here.
    // toplevels.values.length is a live ObjectModel count — no lastIpcObject.
    Connections {
        target: Hyprland
        enabled: root.isHyprland

        function onWorkspacesChanged()       { root._syncHyprland() }
        function onFocusedWorkspaceChanged() { root._syncHyprland() }
    }

    function _syncHyprland() {
        var f       = [false, false, false, false, false, false, false, false, false]
        var c       = [0,     0,     0,     0,     0,     0,     0,     0,     0    ]
        var focused = 1

        var wsList = Hyprland.workspaces.values
        for (var i = 0; i < wsList.length; i++) {
            var ws = wsList[i]
            if (ws.id < 1 || ws.id > 9) continue   // skip named/special workspaces
            var idx = ws.id - 1
            f[idx] = ws.focused || ws.active
            c[idx] = ws.toplevels.values.length     // live count, always accurate
            if (ws.focused) focused = ws.id
        }

        root.tagFocused = f
        root.tagClients = c
        root.focusedTag = focused
    }

    // Also react to toplevel changes on individual workspaces.
    // We do this by watching the global Hyprland.toplevels ObjectModel —
    // it fires when any window is added or removed anywhere, which is exactly
    // when we need to re-run _syncHyprland. This avoids the broken pattern of
    // Connections { target: Hyprland.focusedWorkspace } which does NOT rebind
    // when focusedWorkspace itself changes.
    Connections {
        target: Hyprland.toplevels
        enabled: root.isHyprland
        function onObjectInsertedPost() { root._syncHyprland() }
        function onObjectRemovedPost()  { root._syncHyprland() }
    }

    // ── MangoWM: process-based backend (original, unchanged) ──────────────────
    function parseLine(line) {
        var trimmed = line.trim()
        if (trimmed.length === 0) return
        try {
            var json     = JSON.parse(trimmed)
            var monitors = json["all_tags"]
            if (!monitors || monitors.length === 0) return
            var tags = monitors[0]["tags"]
            if (!tags) return

            var f       = [false, false, false, false, false, false, false, false, false]
            var c       = [0, 0, 0, 0, 0, 0, 0, 0, 0]
            var focused = 1

            for (var i = 0; i < tags.length; i++) {
                var tag = tags[i]
                var idx = tag["index"] - 1
                if (idx < 0 || idx >= 9) continue
                f[idx] = tag["is_active"] === true
                c[idx] = tag["client_count"] || 0
                if (f[idx]) focused = tag["index"]
            }

            root.tagFocused = f
            root.tagClients = c
            root.focusedTag = focused
        } catch (e) {
            console.warn("WorkspaceBar parse error:", e, trimmed)
        }
    }

    Process {
        id: initProc
        command: ["mmsg", "get", "all-tags"]
        running: !root.isHyprland
        stdout: SplitParser { onRead: (line) => root.parseLine(line) }
    }

    Process {
        id: watchProc
        command: ["mmsg", "watch", "all-tags"]
        running: !root.isHyprland
        onRunningChanged: if (!running && !root.isHyprland) watchRestartTimer.start()
        stdout: SplitParser { onRead: (line) => root.parseLine(line) }
    }

    Timer {
        id: watchRestartTimer
        interval: 1000
        onTriggered: if (!root.isHyprland) watchProc.running = true
    }

    // ── Scroll throttle (shared) ──────────────────────────────────────────────
    Timer {
        id: scrollThrottle
        interval: 30
        onTriggered: root.canScroll = true
    }

    // ── Delegates ─────────────────────────────────────────────────────────────
    Repeater {
        model: 9
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

                onClicked: {
                    if (root.isHyprland) {
                        var ws = Hyprland.workspaces.values.find(w => w.id === pill.tagNum)
                        if (ws) ws.activate()
                        else Hyprland.dispatch("workspace " + pill.tagNum)
                    } else {
                        Quickshell.execDetached(["mmsg", "dispatch", "view," + pill.tagNum])
                    }
                }

                onWheel: (event) => {
                    if (!root.canScroll) return

                    if (root.isHyprland) {
                        // Build sorted list of populated workspace ids (1–9 only)
                        var ids = []
                        var wsList = Hyprland.workspaces.values
                        for (var i = 0; i < wsList.length; i++) {
                            var ws = wsList[i]
                            if (ws.id >= 1 && ws.id <= 9) ids.push(ws.id)
                        }
                        // ObjectModel is already sorted by id per the docs
                        var idx = ids.indexOf(root.focusedTag)
                        if (idx === -1) idx = 0
                        idx = event.angleDelta.y < 0
                            ? Math.min(idx + 1, ids.length - 1)
                            : Math.max(idx - 1, 0)
                        Hyprland.dispatch("workspace " + ids[idx])
                    } else {
                        var visible = []
                        for (var i = 0; i < 9; i++) {
                            if (root.tagFocused[i] || root.tagClients[i] > 0)
                                visible.push(i + 1)
                        }
                        if (visible.length === 0) return
                        var idx = visible.indexOf(root.focusedTag)
                        idx = event.angleDelta.y < 0
                            ? Math.min(idx + 1, visible.length - 1)
                            : Math.max(idx - 1, 0)
                        Quickshell.execDetached(["mmsg", "dispatch", "view," + visible[idx]])
                    }

                    root.canScroll = false
                    scrollThrottle.start()
                }
            }
        }
    }
}
