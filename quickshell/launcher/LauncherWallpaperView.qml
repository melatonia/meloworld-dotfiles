// Self-contained wallpaper picker: images/gifs (awww) + videos (mpvpaper).
// Images dir : ~/Pictures/Wallpapers  (.jpg .jpeg .png .webp .gif .jxl .bmp .tiff .tga .webp .avif .pnm .farbfeld .svg)
// Videos dir : ~/Videos/Wallpapers    (.mp4 .mkv .webm .mov .avi .flv .wmv .ts .m4v .ogv)
// Thumbnails  : cached in ~/.cache/meloworld/wallpaper-thumbs/ via ffmpeg
// Daemon      : awww-daemon for images/gifs; mpvpaper for videos (ALL outputs)
// State       : last wallpaper persisted to ~/.cache/meloworld/last-wallpaper for restore on login

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────────
    signal dismissed()

    property var    filteredWallpapers: []
    // "all" | "image" | "video"
    // "image" includes gifs; "video" is mpvpaper-handled files only.
    property string mediaFilter: "all"

    function load() {
        wallpaperModel.clear()
        root.filteredWallpapers = []
        scanProc.running = false
        scanProc.running = true
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
            var entry = root.filteredWallpapers[wallpaperGrid.currentIndex]
            wallpaperSetProc.apply(entry.filePath, entry.mediaType)
            root.dismissed()
        }
    }

    // ── Internal ──────────────────────────────────────────────────────────
    property string _query: ""

    // Rerun filter whenever the media type toggle changes
    onMediaFilterChanged: _applyFilter()

    // Returns "gif" | "video" | "image"
    function _mediaType(path) {
        var ext = path.split(".").pop().toLowerCase()
        if (ext === "gif") return "gif"
        if (["mp4","mkv","webm","mov","avi","flv","wmv","ts","m4v","ogv"].indexOf(ext) !== -1) return "video"
        return "image"
    }

    // Cache path mirrors the file path with slashes replaced by underscores.
    function _thumbPath(filePath) {
        var safe = filePath.replace(/\//g, "_").replace(/^_+/, "")
        return Quickshell.env("HOME") + "/.cache/meloworld/wallpaper-thumbs/" + safe + ".jpg"
    }

    function _applyFilter() {
        var q = _query.toLowerCase()
        var result = []
        for (var i = 0; i < wallpaperModel.count; i++) {
            var e = wallpaperModel.get(i)

            // Media type filter: "image" matches image+gif, "video" matches video only
            var typeMatch = root.mediaFilter === "all"
                || (root.mediaFilter === "image" && e.mediaType !== "video")
                || (root.mediaFilter === "video" && e.mediaType === "video")
            if (!typeMatch) continue

            if (q === "" || e.wallName.toLowerCase().includes(q))
                result.push({
                    filePath:  e.filePath,
                    wallName:  e.wallName,
                    mediaType: e.mediaType,
                    thumbPath: e.thumbPath
                })
        }
        root.filteredWallpapers = result
        wallpaperGrid.currentIndex = result.length > 0 ? 0 : -1
    }

    function _move(colDelta, rowDelta) {
        if (root.filteredWallpapers.length === 0) return
        var cols   = wallpaperGrid.cols
        var maxIdx = root.filteredWallpapers.length - 1
        var cur    = wallpaperGrid.currentIndex < 0 ? 0 : wallpaperGrid.currentIndex
        var next   = Math.max(0, Math.min(cur + colDelta + rowDelta * cols, maxIdx))
        wallpaperGrid.currentIndex = next
        wallpaperGrid.positionViewAtIndex(next, GridView.Contain)
    }

    // ── Step 1: scan wallpaper dirs + Steam Workshop ───────────────────────
    Process {
        id: scanProc
        command: [
            "bash", "-c",
            // Images (awww-supported formats) — ~/Pictures/Wallpapers
            "find \"$HOME/Pictures/Wallpapers\" -type f \\( " +
            "-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' " +
            "-o -iname '*.gif' -o -iname '*.jxl' -o -iname '*.bmp' -o -iname '*.tiff' " +
            "-o -iname '*.tga' -o -iname '*.avif' -o -iname '*.pnm' -o -iname '*.svg' \\) " +
            "2>/dev/null | sort | sed 's/$/ IMAGE/'; " +
            // Videos (mpvpaper/mpv-supported formats) — ~/Videos/Wallpapers
            "find \"$HOME/Videos/Wallpapers\" -type f \\( " +
            "-iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' " +
            "-o -iname '*.avi' -o -iname '*.flv' -o -iname '*.wmv' " +
            "-o -iname '*.ts' -o -iname '*.m4v' -o -iname '*.ogv' \\) " +
            "2>/dev/null | sort | sed 's/$/ VIDEO/'; " +
            // Steam Wallpaper Engine workshop — both images and videos, fully recursive
            "find \"$HOME/.local/share/Steam/steamapps/workshop/content/431960\" -type f \\( " +
            "-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' " +
            "-o -iname '*.gif' -o -iname '*.jxl' -o -iname '*.bmp' -o -iname '*.tiff' " +
            "-o -iname '*.tga' -o -iname '*.avif' -o -iname '*.pnm' -o -iname '*.svg' " +
            "-o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' " +
            "-o -iname '*.avi' -o -iname '*.flv' -o -iname '*.wmv' " +
            "-o -iname '*.ts' -o -iname '*.m4v' -o -iname '*.ogv' \\) " +
            "2>/dev/null | sort | awk '{ " +
            "  ext = tolower($0); sub(/.*\\./, \"\", ext); " +
            "  tag = (ext ~ /^(mp4|mkv|webm|mov|avi|flv|wmv|ts|m4v|ogv)$/) ? \"VIDEO\" : \"IMAGE\"; " +
            "  print $0 \" \" tag " +
            "}'"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                wallpaperModel.clear()
                var videoPaths = []

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line === "") continue

                    var lastSpace = line.lastIndexOf(" ")
                    var path  = line.substring(0, lastSpace).trim()
                    var base  = path.split("/").pop()
                    var name  = base.replace(/\.[^/.]+$/, "")
                    var mtype = root._mediaType(path)
                    var thumb = (mtype === "video") ? root._thumbPath(path) : ""

                    wallpaperModel.append({
                        filePath:  path,
                        wallName:  name,
                        mediaType: mtype,
                        thumbPath: thumb
                    })

                    if (mtype === "video") videoPaths.push(path)
                }

                if (videoPaths.length > 0) {
                    thumbGenProc.generateAll(videoPaths)
                } else {
                    root._applyFilter()
                }
            }
        }
    }

    // ── Step 2: generate missing video thumbnails (ffmpeg, cached) ────────
    Process {
        id: thumbGenProc
        running: false

        function generateAll(paths) {
            var home     = Quickshell.env("HOME")
            var cacheDir = home + "/.cache/meloworld/wallpaper-thumbs"
            var cmds     = ["mkdir -p \"" + cacheDir + "\""]

            for (var i = 0; i < paths.length; i++) {
                var p     = paths[i].replace(/'/g, "'\\''")
                var thumb = root._thumbPath(paths[i]).replace(/'/g, "'\\''")
                // Skip generation if cache file already exists
                cmds.push(
                    "[ -f '" + thumb + "' ] || " +
                    "ffmpeg -y -ss 00:00:01 -i '" + p + "' " +
                    "-vframes 1 -vf 'scale=256:-1' -q:v 3 '" + thumb + "' " +
                    ">/dev/null 2>&1"
                )
            }

            thumbGenProc.command = ["bash", "-c", cmds.join("\n")]
            thumbGenProc.running = false
            thumbGenProc.running = true
        }

        stdout: StdioCollector {
            onStreamFinished: {
                root._applyFilter()
            }
        }
    }

    // ── Step 3: apply wallpaper ───────────────────────────────────────────
    Process {
        id: wallpaperSetProc
        running: false
        command: ["true"]

        function apply(path, mediaType) {
            var p    = path.replace(/'/g, "'\\''")
            var lock = "\"$HOME/.config/quickshell/lockscreen/wallpaper.png\""
            var script

            if (mediaType === "video") {
                script =
                    "pkill -x awww-daemon 2>/dev/null; " +
                    "pkill -x mpvpaper 2>/dev/null; " +
                    "while pgrep -x 'mpvpaper|awww-daemon' > /dev/null; do sleep 0.05; done; " +
                    "mkdir -p \"$HOME/.cache/meloworld\"; " +
                    "echo 'video:" + p + "' > \"$HOME/.cache/meloworld/last-wallpaper\"; " +
                    // Extract frame at 1s → lockscreen wallpaper (runs in background, non-blocking)
                    "ffmpeg -y -ss 00:00:01 -i '" + p + "' -vframes 1 " + lock + " >/dev/null 2>&1 & " +
                    "mpvpaper -f -p -o '--loop-file=inf --no-audio --hwdec=auto' ALL '" + p + "'"
            } else {
                script =
                    "pkill -x mpvpaper 2>/dev/null; " +
                    "awww query >/dev/null 2>&1 || { awww-daemon &>/dev/null & " +
                    "for i in $(seq 1 20); do sleep 0.1 && awww query >/dev/null 2>&1 && break; done; }; " +
                    "mkdir -p \"$HOME/.cache/meloworld\"; " +
                    "echo 'image:" + p + "' > \"$HOME/.cache/meloworld/last-wallpaper\"; " +
                    "awww img '" + p + "' --transition-type fade --transition-duration 0.8 --transition-fps 60; " +
                    // Copy image to a consistent path the lockscreen always reads
                    "cp -f '" + p + "' " + lock

            }

            wallpaperSetProc.command = ["bash", "-c", script]
            wallpaperSetProc.running = false
            wallpaperSetProc.running = true
        }
    }

    // ── Wallpaper model ───────────────────────────────────────────────────
    ListModel { id: wallpaperModel }

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

            readonly property bool isSelected: index === wallpaperGrid.currentIndex
            readonly property bool isHovered:  tileHover.containsMouse

            Rectangle {
                anchors { fill: parent; margins: 4 }
                radius: 10
                color:  isHovered || isSelected ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Column {
                    anchors { fill: parent; margins: 4 }
                    spacing: 6

                    // ── Thumbnail ─────────────────────────────────────────
                    Item {
                        id:     thumbItem
                        width:  parent.width
                        height: wallpaperGrid.thumbH - 8

                        // Loading / missing placeholder
                        Rectangle {
                            anchors.fill: parent
                            color:        PanelColors.rowBackground
                            radius:       8
                            visible:      thumbImg.status !== Image.Ready
                        }

                        Image {
                            id:              thumbImg
                            anchors.fill:    parent
                            anchors.margins: 2
                            source:          modelData.mediaType === "video"
                                                 ? ("file://" + modelData.thumbPath)
                                                 : ("file://" + modelData.filePath)
                            sourceSize:      Qt.size(256, 160)
                            fillMode:        Image.PreserveAspectCrop
                            asynchronous:    true
                            cache:           true
                            smooth:          true
                            mipmap:          true
                        }

                        // Overlay border
                        Rectangle {
                            anchors.fill: parent
                            color:        "transparent"
                            radius:       8
                            border.color: isHovered || isSelected ? PanelColors.launcher : PanelColors.border
                            border.width: 2
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }

                        // ── Media badge (gif / video only) ────────────────
                        Rectangle {
                            visible: modelData.mediaType !== "image"
                            anchors {
                                right:   parent.right
                                bottom:  parent.bottom
                                margins: 6
                            }
                            width:  badgeLabel.implicitWidth + 10
                            height: 20
                            radius: 4
                            color:  PanelColors.rowBackground

                            Text {
                                id:               badgeLabel
                                anchors.centerIn: parent
                                text:             modelData.mediaType === "gif" ? "󰵸 GIF" : " VID"
                                font.family:      "JetBrainsMono Nerd Font"
                                font.pixelSize:   11
                                font.bold:        true
                                color:            modelData.mediaType === "gif" ? Colors.teal200 : Colors.green200
                            }
                        }
                    }

                    // ── Label ─────────────────────────────────────────────
                    Text {
                        width:               parent.width
                        height:              wallpaperGrid.labelH
                        text:                modelData.wallName
                        font.pixelSize:      13
                        font.bold:           true
                        font.family:         "JetBrainsMono Nerd Font"
                        color:               isSelected ? PanelColors.launcher : PanelColors.textMain
                        Behavior on color    { ColorAnimation { duration: 120 } }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                        elide:               Text.ElideRight
                    }
                }

                MouseArea {
                    id:           tileHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        wallpaperSetProc.apply(modelData.filePath, modelData.mediaType)
                        root.dismissed()
                    }
                }
            }
        }
    }
}
