import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../theme"
import "../dock"

Item {
    id: root

    property string appId:   ""
    property string appName: ""
    property string appIcon: ""
    property var    appData: null

    // Derived from appId for pre-pinned steam apps (steam_app_XXXXX format),
    // but also set by _parseDesktopEntry via rungameid URL for name-based desktop files.
    property string steamId: {
        var m = root.appId.match(/^steam_app_(\d+)$/)
        return m ? m[1] : ""
    }

    property bool isMatch:       true
    property int  filteredIndex: 0

    property int  launcherItemsPerPage: 15
    property int  launcherCurrentPage:  0
    property int  launcherSelectedIdx:  -1
    property int  delegateIndex:        0
    property bool launcherIsGridView:   true

    property var launcherView:        null
    property int launcherOpenMenuIdx: -1

    onLauncherOpenMenuIdxChanged: {
        if (launcherOpenMenuIdx !== -1 && launcherOpenMenuIdx !== delegateIndex && ctxMenu.isOpen)
            ctxMenu.closeMenu()
    }

    property int pageNumber:  filteredIndex < 0 ? -1 : Math.floor(filteredIndex / launcherItemsPerPage)
    property int indexOnPage: filteredIndex < 0 ?  0 : filteredIndex % launcherItemsPerPage

    property int gridCol: launcherIsGridView ? indexOnPage % 5 : 0
    property int gridRow: launcherIsGridView ? Math.floor(indexOnPage / 5) : indexOnPage

    // ── Pagination Crossfade ──────────────────────────────────────────────
    readonly property bool onCurrentPage: isMatch && (pageNumber === launcherCurrentPage)
    visible: opacity > 0
    opacity: onCurrentPage ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.InOutSine }
    }

    x: launcherIsGridView ? gridCol * 144 + 4 : 4
    y: launcherIsGridView ? gridRow * 136 + 4 : gridRow * 48 + 4
    width:  launcherIsGridView ? 136 : parent.width - 8
    height: launcherIsGridView ? 132 : 44

    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    property bool   appPrefersNonDefault: false
    property bool   isTerminal:           false
    property string execName:             ""

    Process {
        id: desktopReader
        command: ["bash", "-c",
            "f=\"$HOME/.local/share/applications/$1.desktop\"; " +
            "[ -f \"$f\" ] || f=\"/usr/share/applications/$1.desktop\"; " +
            "[ -f \"$f\" ] && cat \"$f\" || true",
            "--", root.appId]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._parseDesktopEntry(this.text)
        }
    }

    function _parseDesktopEntry(text) {
        if (text === "") return
        var lines = text.split("\n")
        var inMainSection = false
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()

            if (line === "[Desktop Entry]") { inMainSection = true; continue }
            if (line.startsWith("[") && line !== "[Desktop Entry]") { inMainSection = false; continue }
            if (!inMainSection) continue

            var termMatch = line.match(/^Terminal\s*=\s*(.+)$/)
            if (termMatch) {
                var v = termMatch[1].trim()
                root.isTerminal = (v === "true" || v === "1")
                continue
            }

            var prefMatch = line.match(/^PrefersNonDefaultGPU\s*=\s*(.+)$/)
            if (prefMatch) {
                if (prefMatch[1].trim() === "true" || prefMatch[1].trim() === "1")
                    root.appPrefersNonDefault = true
                continue
            }

            var execMatch = line.match(/^Exec\s*=\s*(.+)$/)
            if (execMatch) {
                var execLine = execMatch[1].trim()

                // Detect Steam games by rungameid URL — takes priority over everything else
                var steamMatch = execLine.match(/steam:\/\/rungameid\/(\d+)/)
                if (steamMatch) {
                    root.steamId = steamMatch[1]
                    continue
                }

                // Detect switcherooctl / prime-run
                if (execLine.includes("switcherooctl") || execLine.includes("prime-run")) {
                    root.appPrefersNonDefault = true
                    var parts = execLine.split(/\s+/)
                    var gIdx = parts.indexOf("-g")
                    if (gIdx !== -1 && gIdx + 2 < parts.length)
                        execLine = parts.slice(gIdx + 2).join(" ")
                    else
                        execLine = execLine.replace(/switcherooctl\s+launch\s+(--gpu[= ]\d+\s+|-g\s+\d+\s+)?/, "")
                }
                var bin = execLine.split(/\s+/)[0].replace(/%[uUfFdDnNickvm]/g, "").trim()
                if (bin !== "" && bin !== "switcherooctl" && bin !== "prime-run")
                    root.execName = bin
            }
        }
    }

    function _buildMenuModel() {
        var pinned  = PinnedApps.isPinned(root.appId)
        var entries = [{ label: "Launch", action: "launch", gpuIndex: -1 }]

        // Steam apps: no GPU options, just pin/unpin and hide
        if (root.steamId !== "") {
            entries.push({
                label:    pinned ? "Unpin from dock" : "Pin to dock",
                action:   pinned ? "unpin" : "pin",
                gpuIndex: -1
            })
            entries.push({ label: "Hide", action: "hide", gpuIndex: -1 })
            return entries
        }

        if (DockState.gpuInfoReady) {
            if (root.appPrefersNonDefault) {
                if (DockState.defaultGpuName !== "")
                    entries.push({ label: "Launch with " + DockState.defaultGpuName,
                                   action: "gpu", gpuIndex: DockState.defaultGpuIndex })
            } else {
                if (DockState.nonDefaultGpuName !== "")
                    entries.push({ label: "Launch with " + DockState.nonDefaultGpuName,
                                   action: "gpu", gpuIndex: DockState.nonDefaultGpuIndex })
            }
        }

        entries.push({
            label:    pinned ? "Unpin from dock" : "Pin to dock",
            action:   pinned ? "unpin" : "pin",
            gpuIndex: -1
        })
        entries.push({ label: "Hide", action: "hide", gpuIndex: -1 })

        return entries
    }

    function _launchDefault() {
        AppUsageTracker.recordLaunch(root.appId)
        if (root.isTerminal && root.steamId === "") {
            var exec = root.execName !== "" ? root.execName : root.appId
            exec = exec.replace(/%[uUfFdDnNickvm]/g, "").trim()
            Quickshell.execDetached(["ghostty", "-e", "bash", "-c", exec])
        } else if (root.steamId !== "") {
            Quickshell.execDetached(["xdg-open", "steam://rungameid/" + root.steamId])
        } else if (root.appPrefersNonDefault) {
            var bin = root.execName !== "" ? root.execName : root.appId
            Quickshell.execDetached(["/usr/bin/switcherooctl", "launch", bin])
        } else if (root.appData) {
            root.appData.execute()
        } else {
            Quickshell.execDetached([root.appId])
        }
        LauncherState.hide()
    }

    function _launchOnGpu(gpuIndex) {
        AppUsageTracker.recordLaunch(root.appId)
        var bin = root.execName !== "" ? root.execName : root.appId
        Quickshell.execDetached(["/usr/bin/switcherooctl", "launch", "-g", String(gpuIndex), bin])
        LauncherState.hide()
    }

    function executeApp() { _launchDefault() }

    Timer {
        id: dismissTimer
        interval: 3000
        running:  ctxMenu.isOpen
        onTriggered: ctxMenu.closeMenu()
    }

    Connections {
        target: LauncherState
        function onVisibleChanged() {
            if (!LauncherState.visible) {
                root._isHovered = false
                if (ctxMenu.isOpen) ctxMenu.closeMenu()
            }
        }
    }

    property bool _isHovered: false

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.launcherIsGridView ? 8 : 0
        radius:       12
        color: (root.launcherSelectedIdx === root.delegateIndex || root._isHovered || ctxMenu.isOpen)
                   ? Qt.rgba(1, 1, 1, 0.08)
                   : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Visuals: Grid View ────────────────────────────────────────────────
    Column {
        visible: root.launcherIsGridView
        anchors.centerIn: parent
        spacing: 6
        width: parent.width - 8

        IconImage {
            id: iconImgGrid
            anchors.horizontalCenter: parent.horizontalCenter
            implicitSize: 64
            source: Quickshell.iconPath(root.appIcon)

            scale: (root.launcherSelectedIdx === root.delegateIndex || root._isHovered || ctxMenu.isOpen) ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:                root.appName
            font.pixelSize:      14
            font.bold:           true
            font.family:         "JetBrainsMono Nerd Font"
            color:               PanelColors.textMain
            width:               parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode:            Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount:    2
            elide:               Text.ElideRight
        }
    }

    // ── Visuals: List View ────────────────────────────────────────────────
    Row {
        visible: !root.launcherIsGridView
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        IconImage {
            id: iconImgList
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 22
            source: Quickshell.iconPath(root.appIcon)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:                root.appName
            font.pixelSize:      16
            font.bold:           true
            font.family:         "JetBrainsMono Nerd Font"
            color:               PanelColors.textMain
            width:               parent.width - iconImgList.width - 12
            horizontalAlignment: Text.AlignLeft
            elide:               Text.ElideRight
        }
    }

    // ── Mouse ─────────────────────────────────────────────────────────────
    MouseArea {
        anchors.fill:    parent
        z:               1
        hoverEnabled:    true
        cursorShape:     Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: root._isHovered = true
        onExited:  root._isHovered = false

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (ctxMenu.isOpen) ctxMenu.closeMenu()
                else                ctxMenu.openMenu()
            } else {
                root._launchDefault()
            }
        }
    }

    // ── Context menu PopupWindow ──────────────────────────────────────────
    PopupWindow {
        id: ctxMenu

        anchor.item:           root.launcherIsGridView ? iconImgGrid : iconImgList
        anchor.edges:          Edges.Top
        anchor.gravity:        Edges.Top
        anchor.margins.bottom: 8

        color:          "transparent"
        implicitWidth:  200
        implicitHeight: innerRect.implicitHeight

        visible: false
        property bool isOpen: false

        function openMenu() {
            if (root.launcherView) root.launcherView.notifyMenuOpened(root.delegateIndex)
            menuRepeater.model = root._buildMenuModel()
            innerRect.y        = 14
            innerRect.opacity  = 0.0
            visible            = true
            isOpen             = true
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
                NumberAnimation { target: innerRect; property: "y";       to: 0;   duration: 220; easing.type: Easing.OutExpo  }
                NumberAnimation { target: innerRect; property: "opacity"; to: 1.0; duration: 170; easing.type: Easing.OutCubic }
            }
        }

        SequentialAnimation {
            id: closeAnim
            ParallelAnimation {
                NumberAnimation { target: innerRect; property: "y";       to: 14;  duration: 160; easing.type: Easing.InCubic }
                NumberAnimation { target: innerRect; property: "opacity"; to: 0.0; duration: 130; easing.type: Easing.InCubic }
            }
            ScriptAction { script: ctxMenu.visible = false }
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
                onHoveredChanged: { if (hovered) dismissTimer.restart() }
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
                    text:           root.appName
                    font.pixelSize: 12
                    font.bold:      true
                    font.family:    "JetBrainsMono Nerd Font"
                    color:          PanelColors.textDim
                    bottomPadding:  4
                    elide:          Text.ElideRight
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
                                    var action = modelData.action
                                    if (action === "launch") {
                                        root._launchDefault()
                                    } else if (action === "gpu") {
                                        root._launchOnGpu(modelData.gpuIndex)
                                    } else if (action === "pin") {
                                        PinnedApps.pinApp(root.appId, root.appName, root.appIcon, root.execName, root.steamId)
                                    } else if (action === "unpin") {
                                        PinnedApps.unpinApp(root.appId)
                                    } else if (action === "hide") {
                                        LauncherHiddenApps.hide(root.appId, root.appName, root.appIcon)
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
