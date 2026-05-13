import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."
import "../theme"

PanelWindow {
    id: dock

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    exclusionMode: ExclusionMode.Ignore
    color:         "transparent"

    readonly property int margin:     8
    readonly property int pillHeight: 64
    readonly property int fullHeight: pillHeight + margin * 2
    implicitHeight: fullHeight

    mask: Region {
        item: dockVisible ? pill : triggerStrip
    }

    // ── state ──────────────────────────────────────────────────────
    property bool windowsPresent: false
    property bool hovering:       false
    readonly property bool dockVisible: !windowsPresent || hovering

    property var instanceCounts: ({})

    // ── hide debounce ──────────────────────────────────────────────
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: dock.hovering = false
    }

    // ── trigger strip ──────────────────────────────────────────────
    Item {
        id: triggerStrip
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height: 4

        HoverHandler {
            onHoveredChanged: {
                if (hovered) { hideTimer.stop(); dock.hovering = true }
                else hideTimer.restart()
            }
        }
    }

    // ── mmsg -w -t : watch tag changes, update windowsPresent ─────
    Timer {
        id: watchRestartTimer
        interval: 1000
        onTriggered: watchProc.running = true
    }

    Process {
        id: watchProc
        command: ["mmsg", "-w", "-t"]
        running: true
        onRunningChanged: {
            if (!running) watchRestartTimer.start()
        }
        stdout: SplitParser {
            onRead: (line) => {
                var match = line.match(/\S+\s+tag\s+\d+\s+(\d+)\s+(\d+)\s+\d+/)
                if (!match) return
                var focused = parseInt(match[1]) === 1
                var clients = parseInt(match[2])
                if (focused) dock.windowsPresent = clients > 0

                pollProc.running = false
                pollProc.running = true
            }
        }
    }

    // ── mmsg -g : one-shot poll to get all client appids ──────────
    Process {
        id: pollProc
        command: ["mmsg", "-g"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var m = line.match(/\S+\s+client\s+\S+\s+(\S+)/)
                if (!m) return
                var appId = m[1]
                var counts = dock.instanceCounts
                counts[appId] = (counts[appId] || 0) + 1
                dock.instanceCounts = counts
            }
        }
        onStarted: {
            dock.instanceCounts = ({})
        }
    }

    // ── pill ───────────────────────────────────────────────────────
    Item {
        id: pill

        // No anchors — position is managed entirely by y so that layout
        // geometry always matches visual position, letting the mask track
        // pill directly without a shadow item.
        x: (parent.width - width) / 2
        width:  row.implicitWidth + dock.margin * 2
        height: dock.pillHeight

        readonly property real restingY: parent.height - dock.pillHeight - dock.margin
        readonly property real hiddenY:  parent.height + dock.margin
        y: dock.dockVisible ? restingY : hiddenY

        Behavior on y {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        opacity: dock.dockVisible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            color:        PanelColors.barBackground
            radius:       10
            border.color: PanelColors.border
            border.width: 3
            opacity:      0.95
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: PinnedApps.apps
                AppIcon {
                    appId:         modelData.id
                    appLabel:      modelData.label
                    iconName:      modelData.icon
                    instanceCount: dock.instanceCounts[modelData.id] || 0
                }
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) { hideTimer.stop(); dock.hovering = true }
                else hideTimer.restart()
            }
        }
    }
}
