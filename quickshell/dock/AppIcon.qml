import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../theme"
import "../launcher"

Item {
    id: root

    property string appId:    ""
    property string appLabel: ""
    property string iconName: ""
    property string steamId:  ""
    property string execName: ""

    // Detected from the app's .desktop file:
    //   true  → app prefers dGPU (non-default) → alt option is iGPU (default)
    //   false → app uses iGPU (default)         → alt option is dGPU (non-default)
    property bool appPrefersNonDefault: false

    implicitWidth:  56
    implicitHeight: 64

    // ── Read .desktop file to detect GPU preference ────────────────
    // Tries ~/.local/share/applications/ first, falls back to /usr/share/applications/.
    Process {
        id: desktopReader
        command: ["bash", "-c",
            "f=\"$HOME/.local/share/applications/" + root.appId + ".desktop\"; " +
            "[ -f \"$f\" ] || f=\"/usr/share/applications/" + root.appId + ".desktop\"; " +
            "[ -f \"$f\" ] && cat \"$f\" || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._parseDesktopEntry(this.text)
        }
    }

    function _parseDesktopEntry(text) {
        if (text === "") return
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()

            // Standard freedesktop key
            var prefMatch = line.match(/^PrefersNonDefaultGPU\s*=\s*(.+)$/)
            if (prefMatch) {
                var val = prefMatch[1].trim()
                if (val === "true" || val === "1")
                    root.appPrefersNonDefault = true
                continue
            }

            // Custom: Exec line already uses switcherooctl (user-configured)
            var execMatch = line.match(/^Exec\s*=\s*(.+)$/)
            if (execMatch && execMatch[1].includes("switcherooctl"))
                root.appPrefersNonDefault = true
        }
    }

    HoverHandler { id: hover }

    // ── Hover background ───────────────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width:  48
        height: 48
        radius: 10
        color:  hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── App icon ───────────────────────────────────────────────────
    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: 40
        source: Quickshell.iconPath(root.iconName)

        scale: hover.hovered ? 1.1 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    // ── Auto-dismiss: 3 s idle ─────────────────────────────────────
    Timer {
        id: dismissTimer
        interval: 3000
        running:  ctxMenu.isOpen
        onTriggered: {
            ctxMenu.closeMenu()
            DockState.close()
        }
    }

    Connections {
        target: dock
        function onDockVisibleChanged() {
            if (!dock.dockVisible && ctxMenu.isOpen) {
                ctxMenu.closeMenu()
                DockState.close()
            }
        }
    }

    Connections {
        target: DockState
        function onCloseAll() {
            if (ctxMenu.isOpen)
                ctxMenu.closeMenu()
        }
    }

    // ── Mouse ──────────────────────────────────────────────────────
    MouseArea {
        anchors.fill:    parent
        cursorShape:     Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (ctxMenu.isOpen) {
                    ctxMenu.closeMenu()
                    DockState.close()
                } else {
                    DockState.openFor(root)
                    ctxMenu.openMenu()
                }
            } else {
                root._launchDefault()
            }
        }
    }

    // ── Launch helpers ─────────────────────────────────────────────
    function _launchDefault() {
        AppUsageTracker.recordLaunch(root.appId)
        if (root.steamId !== "") {
            Quickshell.execDetached(["xdg-open", "steam://rungameid/" + root.steamId])
        } else if (root.appPrefersNonDefault) {
            // App wants dGPU — launch via switcherooctl directly
            var bin = root.execName !== "" ? root.execName : root.appId
            Quickshell.execDetached([
                "/usr/bin/switcherooctl", "launch", "--gpu", "1", bin
            ])
        } else {
            var entry = DesktopEntries.byId(root.appId)
            if (entry) entry.execute()
            else Quickshell.execDetached([root.appId])
        }
    }

    function _launchOnGpu(gpuIndex) {
        AppUsageTracker.recordLaunch(root.appId)
        var base = ["switcherooctl", "launch", "-g", String(gpuIndex)]
        var argv
        if (root.steamId !== "") {
            argv = base.concat(["steam", "-applaunch", root.steamId])
        } else {
            var bin = root.execName !== "" ? root.execName : root.appId
            argv = base.concat([bin])
        }
        Quickshell.execDetached(argv)
    }

    // Returns [{label, gpuIndex}] where gpuIndex -1 means default launch.
    // The alt entry targets whichever GPU the app does NOT already prefer.

    function _buildMenuModel() {
        var entries = [{ label: "Launch", gpuIndex: -1, action: "launch" }]

        if (root.steamId !== "") {
            entries.push({ label: "Unpin from dock", gpuIndex: -1, action: "unpin" })
            return entries
        }

        if (DockState.gpuInfoReady) {
            if (root.appPrefersNonDefault) {
                if (DockState.defaultGpuName !== "")
                    entries.push({ label: "Launch with " + DockState.defaultGpuName,
                                   gpuIndex: DockState.defaultGpuIndex, action: "gpu" })
            } else {
                if (DockState.nonDefaultGpuName !== "")
                    entries.push({ label: "Launch with " + DockState.nonDefaultGpuName,
                                   gpuIndex: DockState.nonDefaultGpuIndex, action: "gpu" })
            }
        }

        var pinned = PinnedApps.isPinned(root.appId)
        entries.push({
            label:    pinned ? "Unpin from dock" : "Pin to dock",
            gpuIndex: -1,
            action:   pinned ? "unpin" : "pin"
        })
        return entries
    }

    // ── Context menu popup ─────────────────────────────────────────
    PopupWindow {
        id: ctxMenu

        anchor.item:           icon
        anchor.edges:          Edges.Top
        anchor.gravity:        Edges.Top
        anchor.margins.bottom: 8

        color:          "transparent"
        implicitWidth:  200
        implicitHeight: innerRect.implicitHeight

        visible: false
        property bool isOpen: false

        function openMenu() {
            menuRepeater.model = root._buildMenuModel()
            innerRect.y        = 14
            innerRect.opacity  = 0.0
            visible            = true
            isOpen             = true
            dock.anyMenuOpen   = true
            dock.hovering      = true
            openAnim.restart()
            dismissTimer.restart()
        }

        function closeMenu() {
            if (!isOpen) return
            isOpen = false
            openAnim.stop()
            closeAnim.restart()
        }

        SequentialAnimation {
            id: openAnim
            ParallelAnimation {
                NumberAnimation {
                    target: innerRect; property: "y"
                    to: 0; duration: 220; easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: innerRect; property: "opacity"
                    to: 1.0; duration: 170; easing.type: Easing.OutCubic
                }
            }
        }

        SequentialAnimation {
            id: closeAnim
            ParallelAnimation {
                NumberAnimation {
                    target: innerRect; property: "y"
                    to: 14; duration: 160; easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: innerRect; property: "opacity"
                    to: 0.0; duration: 130; easing.type: Easing.InCubic
                }
            }
            ScriptAction {
                script: {
                    ctxMenu.visible  = false
                    dock.anyMenuOpen = false
                }
            }
        }

        mask: Region { item: innerRect }

        Rectangle {
            id: innerRect

            width:          parent.width
            implicitHeight: menuCol.implicitHeight + padding * 2
            height:         implicitHeight
            radius:         10
            color:          PanelColors.popupBackground
            border.color:   PanelColors.border
            border.width:   2
            clip:           true

            readonly property int padding: 12

            Behavior on color        { ColorAnimation { duration: PanelColors.transitionDuration } }
            Behavior on border.color { ColorAnimation { duration: PanelColors.transitionDuration } }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) dismissTimer.restart()
                }
            }

            Column {
                id: menuCol
                anchors {
                    top:     parent.top
                    left:    parent.left
                    right:   parent.right
                    margins: innerRect.padding
                }
                spacing: 4

                Text {
                    width:          parent.width
                    text:           root.appLabel
                    font.pixelSize: 12
                    font.bold:      true
                    font.family:    "JetBrainsMono Nerd Font"
                    color:          PanelColors.textDim
                    bottomPadding:  4
                }

                Rectangle {
                    width:  parent.width
                    height: 2
                    color:  PanelColors.border
                }

                Repeater {
                    id: menuRepeater
                    model: []

                    delegate: Item {
                        required property var modelData
                        width:  menuCol.width
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            radius:       6
                            color: rowMouse.containsMouse
                                ? Qt.lighter(PanelColors.rowBackground, 1.15)
                                : PanelColors.rowBackground
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Rectangle {
                                width: 3; height: parent.height - 10; radius: 2
                                anchors {
                                    left:           parent.left
                                    leftMargin:     4
                                    verticalCenter: parent.verticalCenter
                                }
                                color: PanelColors.textDim
                            }

                            Text {
                                anchors {
                                    left:           parent.left
                                    leftMargin:     14
                                    right:          parent.right
                                    rightMargin:    10
                                    verticalCenter: parent.verticalCenter
                                }
                                text:           modelData.label
                                font.pixelSize: 13
                                font.bold:      true
                                font.family:    "JetBrainsMono Nerd Font"
                                color:          PanelColors.textMain
                                elide:          Text.ElideRight
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true

                                onContainsMouseChanged: {
                                    if (containsMouse) dismissTimer.restart()
                                }

                                onClicked: {
                                    ctxMenu.closeMenu()
                                    DockState.close()
                                    if (modelData.action === "unpin") {
                                        PinnedApps.unpinApp(root.appId)
                                    } else if (modelData.action === "pin") {
                                        PinnedApps.pinApp(root.appId, root.appLabel, root.iconName, root.execName, root.steamId)
                                    } else if (modelData.gpuIndex === -1) {
                                        root._launchDefault()
                                    } else {
                                        root._launchOnGpu(modelData.gpuIndex)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
