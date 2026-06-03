import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    property var tagFocused: [false, false, false, false, false, false, false, false, false]
    property var tagClients: [0, 0, 0, 0, 0, 0, 0, 0, 0]
    property int focusedTag: 1
    property bool canScroll: true

    function parseLine(line) {
        var trimmed = line.trim()
        if (trimmed.length === 0) return
        try {
            var json = JSON.parse(trimmed)
            var monitors = json["all_tags"]
            if (!monitors || monitors.length === 0) return
            // use first monitor's tags
            var tags = monitors[0]["tags"]
            if (!tags) return

            var f = [false, false, false, false, false, false, false, false, false]
            var c = [0, 0, 0, 0, 0, 0, 0, 0, 0]
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

    // one-shot on startup
    Process {
        id: initProc
        command: ["mmsg", "get", "all-tags"]
        running: true
        stdout: SplitParser {
            onRead: (line) => root.parseLine(line)
        }
    }

    // persistent watch
    Process {
        id: watchProc
        command: ["mmsg", "watch", "all-tags"]
        running: true
        onRunningChanged: if (!running) watchRestartTimer.start()
        stdout: SplitParser {
            onRead: (line) => root.parseLine(line)
        }
    }

    Timer {
        id: watchRestartTimer
        interval: 1000
        onTriggered: watchProc.running = true
    }

    Timer {
        id: scrollThrottle
        interval: 30
        onTriggered: root.canScroll = true
    }

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
            width:   shouldShow ? 28 : 0
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
            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            clip: true

            Text {
                anchors.centerIn: parent
                text:             pill.tagNum
                color:            pill.isFocused ? PanelColors.pillForeground : PanelColors.textDim
                font.pixelSize:   16
                font.bold:        true
                font.family:      "JetBrainsMono Nerd Font"
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered:    pill.hovered = true
                onExited:     pill.hovered = false

                onClicked: {
                    Quickshell.execDetached(["mmsg", "dispatch", "view," + pill.tagNum])
                }

                onWheel: (event) => {
                    if (!root.canScroll) return
                    var visible = []
                    for (var i = 0; i < 9; i++) {
                        if (root.tagFocused[i] || root.tagClients[i] > 0)
                            visible.push(i + 1)
                    }
                    if (visible.length === 0) return
                    var idx = visible.indexOf(root.focusedTag)
                    if (event.angleDelta.y < 0) {
                        idx = Math.min(idx + 1, visible.length - 1)
                    } else {
                        idx = Math.max(idx - 1, 0)
                    }
                    Quickshell.execDetached(["mmsg", "dispatch", "view," + visible[idx]])
                    root.canScroll = false
                    scrollThrottle.start()
                }
            }
        }
    }
}
