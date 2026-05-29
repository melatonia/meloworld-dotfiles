import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."
import "../theme"

PanelWindow {
    id: dock

    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayershell.Top
    color: "transparent"

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
    property bool anyMenuOpen:    false
    readonly property bool dockVisible: !windowsPresent || hovering || anyMenuOpen

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

    // ── watch all-tags: hide when active tag has clients ───────────
    Process {
        id: watchTagsProc
        command: ["mmsg", "watch", "all-tags"]
        running: true
        onRunningChanged: if (!running) tagsRestartTimer.start()
        stdout: SplitParser {
            onRead: (line) => {
                var trimmed = line.trim()
                if (trimmed.length === 0) return
                try {
                    var json = JSON.parse(trimmed)
                    var monitors = json["all_tags"] || []
                    if (monitors.length === 0) return
                    var tags = monitors[0]["tags"] || []
                    var active = tags.find(t => t["is_active"])
                    if (active) dock.windowsPresent = active["client_count"] > 0
                } catch (e) {
                    console.warn("DockWidget parse error:", e)
                }
            }
        }
    }

    Timer {
        id: tagsRestartTimer
        interval: 1000
        onTriggered: watchTagsProc.running = true
    }

    // ── pill ───────────────────────────────────────────────────────
    Item {
        id: pill

        x: (parent.width - width) / 2
        width:  row.implicitWidth + dock.margin * 2
        height: dock.pillHeight

        readonly property real restingY: parent.height - dock.pillHeight - dock.margin
        readonly property real hiddenY:  parent.height + dock.margin
        y: dock.dockVisible ? restingY : hiddenY

        Behavior on y {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        opacity: dock.dockVisible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            color:        PanelColors.barBackground
            Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
            radius:       10
            border.color: PanelColors.border
            Behavior on border.color { ColorAnimation { duration: PanelColors.transitionDuration } }
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
                    appId:    modelData.id
                    appLabel: modelData.label
                    iconName: modelData.icon
                    steamId:  modelData.steamId  ?? ""
                    execName: modelData.execName ?? ""
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
