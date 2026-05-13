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

    // Surface is always fullHeight and never resizes.
    // The mask switches between the pill's resting rect and the trigger strip —
    // but crucially we use `pillMask` (a static Item at the pill's resting
    // position) rather than `pill` itself, so the Translate animation never
    // affects the mask geometry and there is no feedback loop.
    readonly property int margin:     8
    readonly property int pillHeight: 64
    readonly property int fullHeight: pillHeight + margin * 2
    implicitHeight: fullHeight

    mask: Region {
        item: dockVisible ? pillMask : triggerStrip
    }

    // ── state ──────────────────────────────────────────────────────
    property bool windowsPresent: false
    property bool hovering:       false
    readonly property bool dockVisible: !windowsPresent || hovering

    // Map of appId -> instance count, rebuilt on every tag event
    property var instanceCounts: ({})

    // ── hide debounce ──────────────────────────────────────────────
    Timer {
        id: hideTimer
        interval: 300
        onTriggered: dock.hovering = false
    }

    // ── trigger strip: thin hotzone at screen edge when dock is hidden ─
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

    // ── pillMask: static rect at the pill's resting position ───────
    // Used only as a mask geometry reference — never animated, never moved.
    Item {
        id: pillMask
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     dock.margin
        width:  pill.width
        height: dock.pillHeight
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

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     dock.margin

        width:  row.implicitWidth + dock.margin * 2
        height: dock.pillHeight

        // Slide: 0 = resting position, positive = pushed down (hidden)
        readonly property real hiddenOffset: dock.fullHeight + 8
        property real slideOffset: dock.dockVisible ? 0 : hiddenOffset

        Behavior on slideOffset {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate { y: pill.slideOffset }

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
