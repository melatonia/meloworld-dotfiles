import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: dock

    // Only anchor bottom — no left/right — so the window is pill-width
    // and floats centered. With left+right it would stretch the full screen.
    anchors.bottom: true

    // ExclusionMode.Ignore means: don't push tiling windows, don't
    // reserve any strut. The dock floats over everything, purely visual.
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    implicitWidth:  row.implicitWidth + 48
    implicitHeight: 64 + 12   // pill + bottom gap

    // ── autohide state ────────────────────────────────────────────
    property bool windowsPresent: false
    property bool hovering:       false
    readonly property bool dockVisible: !windowsPresent || hovering

    // ── MangoWM watcher ──────────────────────────────────────────
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
                var match = line.match(/\S+\s+tag\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
                if (!match) return
                var focused = parseInt(match[2]) === 1
                var clients = parseInt(match[3])
                if (focused) dock.windowsPresent = clients > 0
            }
        }
    }

    // ── slide animation ──────────────────────────────────────────
    // We translate the pill downward rather than hiding it, so the
    // hover strip at the very bottom remains active even when hidden.
    readonly property real hiddenY: 64 + 12 + 4

    property real slideY: dockVisible ? 0 : hiddenY
    Behavior on slideY {
        NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
    }

    // ── hover strip ───────────────────────────────────────────────
    // Thin invisible strip at the bottom edge. When the pill is slid
    // away, this is still here and catches the cursor entering.
    MouseArea {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height:                  10
        hoverEnabled:            true
        propagateComposedEvents: true
        onEntered: dock.hovering = true
    }

    // ── pill ─────────────────────────────────────────────────────
    Item {
        id: pill

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom:           parent.bottom
            bottomMargin:     6
        }

        implicitWidth:  row.implicitWidth + 24
        implicitHeight: 64

        transform: Translate { y: dock.slideY }

        // Background — radius 6 as requested
        Rectangle {
            anchors.fill: parent
            color:        PanelColors.barBackground
            radius:       6
            border.color: PanelColors.border
            border.width: 1
            opacity:      0.95
        }

        // Icons
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing:          8

            Repeater {
                model: PinnedApps.apps
                AppIcon {
                    appId:    modelData.id
                    appLabel: modelData.label
                    iconName: modelData.icon
                }
            }
        }

        // Hover area covering the pill — onExited clears hovering
        MouseArea {
            anchors.fill:            parent
            hoverEnabled:            true
            propagateComposedEvents: true
            onEntered: dock.hovering = true
            onExited:  dock.hovering = false
        }
    }
}
