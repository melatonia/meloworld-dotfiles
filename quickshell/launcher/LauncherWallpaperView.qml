// Self-contained wallpaper picker: loads, filters, and sets wallpapers.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────────
    signal dismissed()

    property var filteredWallpapers: []

    function load() {
        if (wallpaperModel.count > 0) {
            _applyFilter()
            return
        }
        wallpaperModel.clear()
        root.filteredWallpapers = []
        wallpaperProc.running = false
        wallpaperProc.running = true
    }

    function setFilter(query) {
        _query = query
        _applyFilter()
    }

    function navigateUp()      { _move(0, -1) }
    function navigateDown()    { _move(0, +1) }
    function navigateLeft()    { _move(-1, 0) }
    function navigateRight()   { _move(+1, 0) }
    function navigateTab()     { _move(+1, 0) }
    function navigateBacktab() { _move(-1, 0) }
    function confirm() {
        if (wallpaperGrid.currentIndex >= 0 && wallpaperGrid.currentIndex < root.filteredWallpapers.length) {
            wallpaperSetProc.apply(root.filteredWallpapers[wallpaperGrid.currentIndex].filePath)
            root.dismissed()
        }
    }

    // ── Internal ──────────────────────────────────────────────────────────
    property string _query: ""

    function _applyFilter() {
        var q = _query.toLowerCase()
        var result = []
        for (var i = 0; i < wallpaperModel.count; i++) {
            var e = wallpaperModel.get(i)
            if (q === "" || e.wallName.toLowerCase().includes(q))
                result.push({ filePath: e.filePath, wallName: e.wallName })
        }
        root.filteredWallpapers = result
        wallpaperGrid.currentIndex = 0
    }

    function _move(colDelta, rowDelta) {
        if (root.filteredWallpapers.length === 0) return
        var cols    = wallpaperGrid.cols
        var maxIdx  = root.filteredWallpapers.length - 1
        var cur     = wallpaperGrid.currentIndex < 0 ? 0 : wallpaperGrid.currentIndex
        var next    = Math.max(0, Math.min(cur + colDelta + rowDelta * cols, maxIdx))
        wallpaperGrid.currentIndex = next
        wallpaperGrid.positionViewAtIndex(next, GridView.Contain)
    }

    // ── Wallpaper model + loader ──────────────────────────────────────────
    ListModel { id: wallpaperModel }

    Process {
        id: wallpaperProc
        command: [
            "bash", "-c",
            "find \"${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}\" " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.webp' -o -iname '*.gif' -o -iname '*.jxl' \\) " +
            "-type f | sort"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                wallpaperModel.clear()
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim()
                    if (path === "") continue
                    var base = path.split("/").pop()
                    var name = base.replace(/\.[^/.]+$/, "")
                    wallpaperModel.append({ filePath: path, wallName: name })
                }
                root._applyFilter()
            }
        }
    }

    // ── Wallpaper setter ──────────────────────────────────────────────────
    Process {
        id: wallpaperSetProc
        running: false
        command: ["true"]
        function apply(path) {
            var p = path.replace(/'/g, "'\\''")
            wallpaperSetProc.command = [
                "bash", "-c",
                "if command -v awww >/dev/null 2>&1 && [ -n \"$WAYLAND_DISPLAY\" ]; then " +
                "  awww query >/dev/null 2>&1 || awww init && " +
                "  awww img '" + p + "' --transition-type fade --transition-duration 0.8 --transition-fps 60; " +
                "elif command -v swaybg >/dev/null 2>&1; then " +
                "  pkill swaybg 2>/dev/null; swaybg -m fill -i '" + p + "' & " +
                "elif command -v feh >/dev/null 2>&1; then " +
                "  feh --bg-scale '" + p + "'; " +
                "fi; " +
                "ln -sf '" + p + "' \"$HOME/.config/hypr/wallpaper.png\""
            ]
            wallpaperSetProc.running = false
            wallpaperSetProc.running = true
        }
    }

    // ── Grid ─────────────────────────────────────────────────────────────
    GridView {
        id:           wallpaperGrid
        anchors.fill: parent
        clip:         true

        readonly property int cols:   4
        readonly property int thumbW: Math.floor(width / cols)
        readonly property int thumbH: Math.floor(thumbW * 0.60)
        readonly property int labelH: 22
        cellWidth:  thumbW
        cellHeight: thumbH + labelH + 12

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        model: root.filteredWallpapers

        delegate: Item {
            required property var modelData
            required property int index

            width:  wallpaperGrid.cellWidth
            height: wallpaperGrid.cellHeight

            Rectangle {
                anchors { fill: parent; margins: 4 }
                radius: 10
                color:  tileHover.containsMouse || index === wallpaperGrid.currentIndex
                            ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Column {
                    anchors { fill: parent; margins: 4 }
                    spacing: 6

                    Item {
                        width:  parent.width
                        height: wallpaperGrid.thumbH - 8

                        Rectangle {
                            anchors.fill: parent; color: PanelColors.rowBackground
                            radius: 8; visible: wallImg.status !== Image.Ready
                        }
                        Image {
                            id:              wallImg
                            anchors.fill:    parent
                            anchors.margins: 2
                            source:          "file://" + modelData.filePath
                            sourceSize:      Qt.size(256, 256)
                            fillMode:        Image.PreserveAspectCrop
                            asynchronous:    true; cache: true; smooth: true; mipmap: true
                        }
                        Rectangle {
                            anchors.fill: parent; color: "transparent"
                            border.color: tileHover.containsMouse || index === wallpaperGrid.currentIndex
                                              ? PanelColors.launcher : PanelColors.border
                            border.width: 2; radius: 8
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Text {
                        width:               parent.width
                        height:              wallpaperGrid.labelH
                        text:                modelData.wallName
                        font.pixelSize:      13; font.bold: true
                        font.family:         "JetBrainsMono Nerd Font"
                        color:               index === wallpaperGrid.currentIndex
                                                 ? PanelColors.launcher : PanelColors.textMain
                        Behavior on color    { ColorAnimation { duration: 120 } }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                        elide:               Text.ElideRight
                    }
                }

                MouseArea {
                    id:           tileHover
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wallpaperSetProc.apply(modelData.filePath)
                        root.dismissed()
                    }
                }
            }
        }
    }
}
