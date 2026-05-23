import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "../dock"

PanelWindow {
    id: root

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    exclusiveZone:  0

    WlrLayershell.layer:         WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color:   "transparent"
    visible: animState !== "closed"

    mask: Region { item: panel }

    // ── Panel animation state ─────────────────────────────────────────────
    property string animState:     "closed"
    property int    selectedIndex: 0

    // ── Pagination & View Mode ────────────────────────────────────────────
    property bool isGridView:     false
    property int  totalPages:     1
    property int  currentPage:    0
    property bool wallpaperMode:  false
    property bool clipboardMode:  false
    property bool emojiMode:      false
    readonly property int itemsPerPage: isGridView ? 15 : 6

    // Ordered list of original indices for all currently matched apps
    property var filteredApps: []

    // ── Wallpaper state ───────────────────────────────────────────────────
    property var filteredWallpapers: []

    function updateWallpaperFilter() {
        var q = searchInput.text.toLowerCase()
        var result = []
        for (var i = 0; i < wallpaperModel.count; i++) {
            var entry = wallpaperModel.get(i)
            if (q === "" || entry.wallName.toLowerCase().includes(q))
                result.push({ filePath: entry.filePath, wallName: entry.wallName })
        }
        root.filteredWallpapers = result
        wallpaperGrid.currentIndex = 0
    }

    // ── Clipboard state ───────────────────────────────────────────────────
    property var filteredClipboard: []

    function updateClipboardFilter() {
        var q = searchInput.text.toLowerCase()
        var result = []
        for (var i = 0; i < clipboardModel.count; i++) {
            var entry = clipboardModel.get(i)
            if (q === "" || entry.content.toLowerCase().includes(q))
                result.push({ itemId: entry.itemId, content: entry.content, rawLine: entry.rawLine })
        }
        root.filteredClipboard = result
        clipboardList.currentIndex = 0
    }

    // ── Emoji state ───────────────────────────────────────────────────────
    property var allEmoji:      []   // loaded once from JSON
    property var filteredEmoji: []

    function updateEmojiFilter() {
        var q = searchInput.text.toLowerCase()
        if (q === "") {
            root.filteredEmoji = root.allEmoji
        } else {
            var result = []
            for (var i = 0; i < root.allEmoji.length; i++) {
                if (root.allEmoji[i].name.includes(q))
                    result.push(root.allEmoji[i])
            }
            root.filteredEmoji = result
        }
        emojiGrid.currentIndex = 0
    }

    Shortcut {
        sequence: "Ctrl+G"
        onActivated: {
            if (root.wallpaperMode || root.clipboardMode || root.emojiMode) return
            root.isGridView = !root.isGridView
            filterTimer.restart()
        }
    }

    // ── Hidden-apps popup (right-click empty space) ───────────────────────
    property bool _hiddenMenuOpen: false

    Timer {
        id: hiddenDismissTimer
        interval: 3000
        running:  root._hiddenMenuOpen
        onTriggered: root._closeHiddenMenu()
    }

    function _openHiddenMenu() {
        if (_hiddenMenuOpen) { _closeHiddenMenu(); return }
        _hiddenMenuOpen         = true
        hiddenMenuInner.y       = 14
        hiddenMenuInner.opacity = 0.0
        hiddenMenuPopup.visible = true
        hiddenOpenAnim.restart()
        hiddenDismissTimer.restart()
    }

    function _closeHiddenMenu() {
        if (!_hiddenMenuOpen) return
        _hiddenMenuOpen = false
        hiddenOpenAnim.stop()
        hiddenCloseAnim.restart()
    }

    // ── App filter ────────────────────────────────────────────────────────
    Timer {
        id: filterTimer
        interval: 10
        onTriggered: root.updateFilter()
    }

    function updateFilter() {
        var firstMatch = -1
        var items = []
        var q = searchInput.text.toLowerCase()

        for (var i = 0; i < appsRepeater.count; i++) {
            var item = appsRepeater.itemAt(i)
            if (!item) continue

            var hidden = LauncherHiddenApps.isHidden(item.appId)

            var nameMatch = q === "" ||
                            item.appName.toLowerCase().includes(q) ||
                            (item.appData && item.appData.genericName && String(item.appData.genericName).toLowerCase().includes(q)) ||
                            (item.appData && item.appData.comment && String(item.appData.comment).toLowerCase().includes(q)) ||
                            (item.appData && item.appData.keywords && String(item.appData.keywords).toLowerCase().includes(q))

            var isMatch = !hidden && nameMatch
            item.isMatch = isMatch

            if (isMatch) {
                items.push({
                    item: item,
                    origIndex: i,
                    usage: AppUsageTracker.getUsage(item.appId),
                    name: item.appName.toLowerCase()
                })
            } else {
                item.filteredIndex = -1
            }
        }

        items.sort(function(a, b) {
            if (b.usage !== a.usage) return b.usage - a.usage
            return a.name.localeCompare(b.name)
        })

        var mapped = []
        for (var j = 0; j < items.length; j++) {
            items[j].item.filteredIndex = j
            mapped.push(items[j].origIndex)
            if (firstMatch === -1) firstMatch = items[j].origIndex
        }
        root.filteredApps = mapped

        root.totalPages = Math.max(1, Math.ceil(items.length / root.itemsPerPage))
        if (root.currentPage >= root.totalPages)
            root.currentPage = Math.max(0, root.totalPages - 1)
        root.selectedIndex = firstMatch
    }

    // ── Connections ───────────────────────────────────────────────────────
    Connections {
        target: LauncherState
        function onVisibleChanged() {
            root.animState = LauncherState.visible ? "open" : "closing"
            if (LauncherState.visible) {
                root._closeHiddenMenu()
                if (!root.wallpaperMode && !root.clipboardMode && !root.emojiMode) {
                    filterTimer.restart()
                }
            } else {
                root._closeHiddenMenu()
            }
        }
    }

    Connections {
        target: LauncherHiddenApps
        function onHiddenAppsChanged() {
            if (!root.wallpaperMode && !root.clipboardMode && !root.emojiMode)
                filterTimer.restart()
        }
    }

    Connections {
        target: AppUsageTracker
        function onUsageMapChanged() {
            if (!root.wallpaperMode && !root.clipboardMode && !root.emojiMode)
                filterTimer.restart()
        }
    }

    onAnimStateChanged: {
        if (animState === "open") searchInput.forceActiveFocus()
    }

    // ── Emoji JSON loader (reads once, lazy on first openEmoji) ───────────
    Process {
        id: emojiLoadProc
        command: ["cat", Quickshell.configDir + "/assets/emoji.json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allEmoji = JSON.parse(this.text)
                    root.filteredEmoji = root.allEmoji
                    emojiGrid.currentIndex = 0
                } catch (e) {
                    console.warn("Failed to parse emoji.json:", e)
                }
            }
        }
    }

    // ── Emoji copy ────────────────────────────────────────────────────────
    Process {
        id: emojiCopyProc
        running: false
        command: ["true"]

        function copyEmoji(ch) {
            emojiCopyProc.command = ["bash", "-c", "printf '%s' '" + ch + "' | wl-copy"]
            emojiCopyProc.running = false
            emojiCopyProc.running = true
        }
    }

    // ── Clipboard loader ──────────────────────────────────────────────────
    QtObject {
        id: clipboardLoader
        function loadClipboard() {
            clipboardModel.clear()
            root.filteredClipboard = []
            clipboardProc.running = false
            clipboardProc.running = true
        }
    }

    ListModel { id: clipboardModel }

    Process {
        id: clipboardProc
        command: ["cliphist", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                clipboardModel.clear()
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (line === "") continue
                    var parts = line.split("\t")
                    if (parts.length >= 2) {
                        var id = parts[0]
                        var content = parts.slice(1).join("\t")
                        clipboardModel.append({ itemId: id, content: content, rawLine: line })
                    }
                }
                root.updateClipboardFilter()
            }
        }
    }

    // ── Clipboard actions ─────────────────────────────────────────────────
    Process {
        id: clipboardActionProc
        running: false
        command: ["true"]

        function copyItem(rawLine) {
            var escaped = rawLine.replace(/'/g, "'\\''")
            clipboardActionProc.command = ["bash", "-c", "printf '%s\n' '" + escaped + "' | cliphist decode | wl-copy"]
            clipboardActionProc.running = false
            clipboardActionProc.running = true
        }

        function deleteItem(rawLine) {
            var escaped = rawLine.replace(/'/g, "'\\''")
            clipboardActionProc.command = ["bash", "-c", "printf '%s\n' '" + escaped + "' | cliphist delete"]
            clipboardActionProc.running = false
            clipboardActionProc.running = true
            clipboardLoader.loadClipboard()
        }
    }

    // ── Wallpaper loader ──────────────────────────────────────────────────
    QtObject {
        id: wallpaperLoader
        function loadWallpapers() {
            if (wallpaperModel.count > 0) {
                root.updateWallpaperFilter()
                return
            }
            wallpaperModel.clear()
            root.filteredWallpapers = []
            wallpaperProc.running = false
            wallpaperProc.running = true
        }
    }

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
                root.updateWallpaperFilter()
            }
        }
    }

    // ── Wallpaper setter ──────────────────────────────────────────────────
    Process {
        id: wallpaperSetProc
        running: false
        command: ["true"]

        function apply(path) {
            wallpaperSetProc.command = [
                "bash", "-c",
                "if command -v awww >/dev/null 2>&1 && [ -n \"$WAYLAND_DISPLAY\" ]; then " +
                "  awww query >/dev/null 2>&1 || awww init && " +
                "  awww img '" + path.replace(/'/g, "'\\''") + "' --transition-type fade --transition-duration 0.8 --transition-fps 60; " +
                "elif command -v swaybg >/dev/null 2>&1; then " +
                "  pkill swaybg 2>/dev/null; swaybg -m fill -i '" + path.replace(/'/g, "'\\''") + "' & " +
                "elif command -v feh >/dev/null 2>&1; then " +
                "  feh --bg-scale '" + path.replace(/'/g, "'\\''") + "'; " +
                "fi; " +
                "ln -sf '" + path.replace(/'/g, "'\\''") + "' \"$HOME/.config/hypr/wallpaper.png\""
            ]
            wallpaperSetProc.running = false
            wallpaperSetProc.running = true
        }
    }

    // ── IPC ───────────────────────────────────────────────────────────────
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (!LauncherState.visible) {
                root.wallpaperMode = false
                root.clipboardMode = false
                root.emojiMode     = false
                root.currentPage   = 0
                searchInput.text   = ""
            }
            LauncherState.toggle()
        }

        function openWallpaper(): void {
            root.wallpaperMode = true
            root.clipboardMode = false
            root.emojiMode     = false
            searchInput.text   = ""
            LauncherState.show()
            wallpaperLoader.loadWallpapers()
            searchInput.forceActiveFocus()
        }

        function openClipboard(): void {
            root.clipboardMode = true
            root.wallpaperMode = false
            root.emojiMode     = false
            searchInput.text   = ""
            LauncherState.show()
            clipboardLoader.loadClipboard()
            searchInput.forceActiveFocus()
        }

        function openEmoji(): void {
            root.emojiMode     = true
            root.clipboardMode = false
            root.wallpaperMode = false
            searchInput.text   = ""
            LauncherState.show()
            // Lazy-load: only read file the first time
            if (root.allEmoji.length === 0) {
                emojiLoadProc.running = false
                emojiLoadProc.running = true
            } else {
                root.filteredEmoji = root.allEmoji
                emojiGrid.currentIndex = 0
            }
            searchInput.forceActiveFocus()
        }
    }

    // ── Hidden-apps PopupWindow ───────────────────────────────────────────
    PopupWindow {
        id: hiddenMenuPopup

        anchor.item:           panel
        anchor.edges:          Edges.Top
        anchor.gravity:        Edges.Top
        anchor.margins.bottom: 8

        color:          "transparent"
        implicitWidth:  220
        implicitHeight: hiddenMenuInner.implicitHeight

        visible: false

        SequentialAnimation {
            id: hiddenOpenAnim
            ParallelAnimation {
                NumberAnimation {
                    target: hiddenMenuInner; property: "y"
                    to: 0; duration: 220; easing.type: Easing.OutExpo
                }
                NumberAnimation {
                    target: hiddenMenuInner; property: "opacity"
                    to: 1.0; duration: 170; easing.type: Easing.OutCubic
                }
            }
        }

        SequentialAnimation {
            id: hiddenCloseAnim
            ParallelAnimation {
                NumberAnimation {
                    target: hiddenMenuInner; property: "y"
                    to: 14; duration: 160; easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: hiddenMenuInner; property: "opacity"
                    to: 0.0; duration: 130; easing.type: Easing.InCubic
                }
            }
            ScriptAction { script: hiddenMenuPopup.visible = false }
        }

        mask: Region { item: hiddenMenuInner }

        Rectangle {
            id: hiddenMenuInner

            width:          parent.width
            implicitHeight: hiddenMenuCol.implicitHeight + padding * 2
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
                onHoveredChanged: { if (hovered) hiddenDismissTimer.restart() }
            }

            Column {
                id: hiddenMenuCol
                anchors {
                    top:     parent.top
                    left:    parent.left
                    right:   parent.right
                    margins: hiddenMenuInner.padding
                }
                spacing: 4

                Text {
                    width:          parent.width
                    text:           "Hidden Apps"
                    font.pixelSize: 13
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

                Text {
                    width:          parent.width
                    text:           "No hidden apps"
                    font.pixelSize: 13
                    font.family:    "JetBrainsMono Nerd Font"
                    color:          PanelColors.textDim
                    visible:        LauncherHiddenApps.hiddenApps.length === 0
                    topPadding:     4
                    bottomPadding:  4
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: LauncherHiddenApps.hiddenApps

                    delegate: Item {
                        required property var modelData
                        width:  hiddenMenuCol.width
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            radius:       6
                            color: hRow.containsMouse
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
                                text:           modelData.name
                                font.pixelSize: 13
                                font.bold:      true
                                font.family:    "JetBrainsMono Nerd Font"
                                color:          PanelColors.textMain
                                elide:          Text.ElideRight
                            }

                            MouseArea {
                                id: hRow
                                anchors.fill: parent
                                hoverEnabled: true
                                onContainsMouseChanged: {
                                    if (containsMouse) hiddenDismissTimer.restart()
                                }
                                onClicked: {
                                    LauncherHiddenApps.show(modelData.id)
                                    root._closeHiddenMenu()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Panel ─────────────────────────────────────────────────────────────
    Rectangle {
        id: panel

        readonly property int panelWidth: {
            if (root.wallpaperMode) return 860
            if (root.clipboardMode) return 600
            if (root.emojiMode)     return 540
            return root.isGridView  ? 740 : 600
        }

        width:  panelWidth
        height: panelColumn.implicitHeight + 20

        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        x: Math.round((parent.width  - width)  / 2)
        y: Math.round((parent.height - height) / 2)

        radius:       12
        color:        PanelColors.popupBackground
        Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }

        border.color: PanelColors.rowBackground
        Behavior on border.color { ColorAnimation { duration: PanelColors.transitionDuration } }
        border.width: 4
        clip:         false

        opacity: 0.0
        transform: Translate { id: panelSlide; y: 28 }

        HoverHandler {
            onHoveredChanged: { if (hovered) panel.forceActiveFocus() }
        }

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: panel;      opacity: 1.0 }
                PropertyChanges { target: panelSlide; y: 0         }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: panel;      opacity: 0.0 }
                PropertyChanges { target: panelSlide; y: 28        }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                SequentialAnimation {
                    PropertyAction { target: panelSlide; property: "y";       value: 28  }
                    PropertyAction { target: panel;      property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: panelSlide; property: "y"
                            to: 0; duration: 280; easing.type: Easing.OutExpo
                        }
                        NumberAnimation {
                            target: panel; property: "opacity"
                            to: 1.0; duration: 200; easing.type: Easing.OutCubic
                        }
                    }
                }
            },
            Transition {
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: panelSlide; property: "y"
                            to: 28; duration: 180; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: panel; property: "opacity"
                            to: 0.0; duration: 150; easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        MouseArea {
            anchors.fill:    parent
            z:               0
            acceptedButtons: Qt.RightButton
            onClicked:       root._openHiddenMenu()
        }

        // ── Content ─────────────────────────────────────────────────────
        Column {
            id: panelColumn
            anchors {
                top:     parent.top
                left:    parent.left
                right:   parent.right
                margins: 10
            }
            spacing: 8

            // ── Search bar ───────────────────────────────────────────────
            Rectangle {
                id:     searchBar
                width:  parent.width
                height: 44
                radius: 8
                color:  PanelColors.textBox
                Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }

                border.color: searchInput.activeFocus ? PanelColors.launcher : "transparent"
                Behavior on border.color { ColorAnimation { duration: 150 } }
                border.width: 0

                Item {
                    anchors {
                        fill:        parent
                        leftMargin:  12
                        rightMargin: 12
                    }

                    // ── Mode pill ────────────────────────────────────────
                    Rectangle {
                        id: modePill
                        visible: root.wallpaperMode || root.clipboardMode || root.emojiMode
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:           parent.left
                        height: 26
                        width:  pillLabel.implicitWidth + 16
                        radius: 13
                        color:  PanelColors.rowBackground
                        Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }

                        Text {
                            id: pillLabel
                            anchors.centerIn: parent
                            text: root.wallpaperMode ? "󰸉 Wallpaper"
                                : root.clipboardMode ? "󰅌 Clipboard"
                                : root.emojiMode     ? "󰞅 Emoji"
                                : ""
                            font.pixelSize: 13
                            font.bold:      true
                            font.family:    "JetBrainsMono Nerd Font"
                            color:          PanelColors.launcher
                        }
                    }

                    Text {
                        anchors.fill:      parent
                        anchors.leftMargin: modePill.visible ? modePill.width + 8 : 0
                        text:              root.wallpaperMode ? "Search wallpapers..."
                                         : root.clipboardMode ? "Search clipboard..."
                                         : root.emojiMode     ? "Search emoji..."
                                         : " Search..."
                        font.pixelSize:    16
                        font.bold:         true
                        font.family:       "JetBrainsMono Nerd Font"
                        color:             PanelColors.textDim
                        verticalAlignment: Text.AlignVCenter
                        visible:           searchInput.text === ""
                    }

                    TextInput {
                        id:                searchInput
                        anchors.fill:      parent
                        anchors.leftMargin: modePill.visible ? modePill.width + 8 : 0
                        color:             PanelColors.textMain
                        font.pixelSize:    16
                        font.bold:         true
                        font.family:       "JetBrainsMono Nerd Font"
                        selectByMouse:     true
                        clip:              true
                        verticalAlignment: TextInput.AlignVCenter
                        activeFocusOnTab:  false

                        onTextChanged: {
                            if (root.wallpaperMode)
                                root.updateWallpaperFilter()
                            else if (root.clipboardMode)
                                root.updateClipboardFilter()
                            else if (root.emojiMode)
                                root.updateEmojiFilter()
                            else
                                filterTimer.restart()
                        }

                        Keys.onPressed: (event) => {
                            if (root.wallpaperMode) {
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
                                    event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                                    event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {

                                    if (root.filteredWallpapers.length === 0) return;

                                    var wcols = wallpaperGrid.cols;
                                    var maxWidx = root.filteredWallpapers.length - 1;
                                    var cwidx = wallpaperGrid.currentIndex;
                                    if (cwidx === -1) cwidx = 0;

                                    if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                                        cwidx = Math.min(cwidx + 1, maxWidx);
                                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                                        cwidx = Math.max(cwidx - 1, 0);
                                    } else if (event.key === Qt.Key_Down) {
                                        cwidx = Math.min(cwidx + wcols, maxWidx);
                                    } else if (event.key === Qt.Key_Up) {
                                        cwidx = Math.max(cwidx - wcols, 0);
                                    }

                                    wallpaperGrid.currentIndex = cwidx;
                                    wallpaperGrid.positionViewAtIndex(cwidx, GridView.Contain);
                                    event.accepted = true;
                                }
                            } else if (root.clipboardMode) {
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
                                    event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {

                                    if (root.filteredClipboard.length === 0) return;

                                    var maxCidx = root.filteredClipboard.length - 1;
                                    var ccidx = clipboardList.currentIndex;
                                    if (ccidx === -1) ccidx = 0;

                                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                        ccidx = Math.min(ccidx + 1, maxCidx);
                                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                        ccidx = Math.max(ccidx - 1, 0);
                                    }

                                    clipboardList.currentIndex = ccidx;
                                    clipboardList.positionViewAtIndex(ccidx, ListView.Contain);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Delete) {
                                    if (root.filteredClipboard.length > 0 && clipboardList.currentIndex >= 0) {
                                        var cItem = root.filteredClipboard[clipboardList.currentIndex];
                                        clipboardActionProc.deleteItem(cItem.rawLine);
                                        event.accepted = true;
                                    }
                                }
                            } else if (root.emojiMode) {
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
                                    event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                                    event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {

                                    if (root.filteredEmoji.length === 0) return;

                                    var ecols = emojiGrid.cols;
                                    var maxEidx = root.filteredEmoji.length - 1;
                                    var ceidx = emojiGrid.currentIndex;
                                    if (ceidx === -1) ceidx = 0;

                                    if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                                        ceidx = Math.min(ceidx + 1, maxEidx);
                                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                                        ceidx = Math.max(ceidx - 1, 0);
                                    } else if (event.key === Qt.Key_Down) {
                                        ceidx = Math.min(ceidx + ecols, maxEidx);
                                    } else if (event.key === Qt.Key_Up) {
                                        ceidx = Math.max(ceidx - ecols, 0);
                                    }

                                    emojiGrid.currentIndex = ceidx;
                                    emojiGrid.positionViewAtIndex(ceidx, GridView.Contain);
                                    event.accepted = true;
                                }
                            } else {
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
                                     event.key === Qt.Key_Tab  || event.key === Qt.Key_Backtab) {

                                    if (root.filteredApps.length === 0) return

                                    var currentFidx = root.filteredApps.indexOf(root.selectedIndex)
                                    if (currentFidx === -1) currentFidx = 0

                                    var cols = root.isGridView ? 5 : 1
                                    var nextFidx = currentFidx

                                    if (event.key === Qt.Key_Down) {
                                        nextFidx = Math.min(currentFidx + cols, root.filteredApps.length - 1)
                                    } else if (event.key === Qt.Key_Up) {
                                        nextFidx = Math.max(currentFidx - cols, 0)
                                    } else if (event.key === Qt.Key_Tab) {
                                        nextFidx = Math.min(currentFidx + 1, root.filteredApps.length - 1)
                                    } else if (event.key === Qt.Key_Backtab) {
                                        nextFidx = Math.max(currentFidx - 1, 0)
                                    }

                                    if (nextFidx !== currentFidx) {
                                        root.selectedIndex = root.filteredApps[nextFidx]
                                        // List mode: scroll the ListView to keep selection visible
                                        if (!root.isGridView) {
                                            appListView.positionViewAtIndex(nextFidx, ListView.Contain)
                                        } else {
                                            var newPage = Math.floor(nextFidx / root.itemsPerPage)
                                            if (newPage !== root.currentPage)
                                                root.currentPage = newPage
                                        }
                                    }
                                    event.accepted = true
                                }
                            }
                        }

                        Keys.onReturnPressed: {
                            if (root.emojiMode) {
                                if (emojiGrid.currentIndex >= 0 && emojiGrid.currentIndex < root.filteredEmoji.length) {
                                    var em = root.filteredEmoji[emojiGrid.currentIndex]
                                    emojiCopyProc.copyEmoji(em.char)
                                    root.emojiMode   = false
                                    searchInput.text = ""
                                    LauncherState.hide()
                                }
                            } else if (root.wallpaperMode) {
                                if (wallpaperGrid.currentIndex >= 0 && wallpaperGrid.currentIndex < root.filteredWallpapers.length) {
                                    var wp = root.filteredWallpapers[wallpaperGrid.currentIndex]
                                    wallpaperSetProc.apply(wp.filePath)
                                    root.wallpaperMode = false
                                    searchInput.text   = ""
                                    filterTimer.restart()
                                    LauncherState.hide()
                                }
                            } else if (root.clipboardMode) {
                                if (clipboardList.currentIndex >= 0 && clipboardList.currentIndex < root.filteredClipboard.length) {
                                    var cp = root.filteredClipboard[clipboardList.currentIndex]
                                    clipboardActionProc.copyItem(cp.rawLine)
                                    root.clipboardMode = false
                                    searchInput.text   = ""
                                    LauncherState.hide()
                                }
                            } else {
                                if (root.selectedIndex !== -1) {
                                    var item = appsRepeater.itemAt(root.selectedIndex)
                                    if (item) item.executeApp()
                                } else if (searchInput.text.trim() !== "") {
                                    Quickshell.execDetached(["bash", "-c", searchInput.text])
                                    LauncherState.hide()
                                }
                            }
                        }

                        Keys.onEscapePressed: {
                            if (root.wallpaperMode || root.clipboardMode || root.emojiMode) {
                                LauncherState.hide()
                            } else if (root._hiddenMenuOpen) {
                                root._closeHiddenMenu()
                            } else {
                                LauncherState.hide()
                            }
                        }
                    }
                }
            }

            // ── Clipboard list ───────────────────────────────────────────
            Item {
                width:   parent.width
                height:  400
                clip:    true
                visible: root.clipboardMode
                opacity: root.clipboardMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                ListView {
                    id:           clipboardList
                    anchors.fill: parent
                    clip:         true
                    spacing:      4

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    model: root.filteredClipboard

                    delegate: Rectangle {
                        width:  clipboardList.width
                        height: 38
                        radius: 8
                        color:  clipboardHover.containsMouse || index === clipboardList.currentIndex
                                    ? Qt.rgba(1, 1, 1, 0.10)
                                    : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 3; height: parent.height - 12; radius: 2
                            anchors {
                                left:           parent.left
                                leftMargin:     4
                                verticalCenter: parent.verticalCenter
                            }
                            color: PanelColors.launcher
                            visible: index === clipboardList.currentIndex
                        }

                        Text {
                            anchors {
                                left:           parent.left
                                right:          parent.right
                                leftMargin:     14
                                rightMargin:    12
                                verticalCenter: parent.verticalCenter
                            }
                            text:           modelData.content
                            font.pixelSize: 16
                            font.family:    "JetBrainsMono Nerd Font"
                            color:          PanelColors.textMain
                            elide:          Text.ElideRight
                        }

                        MouseArea {
                            id:           clipboardHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                clipboardActionProc.copyItem(modelData.rawLine)
                                root.clipboardMode = false
                                searchInput.text   = ""
                                LauncherState.hide()
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text:             "Clipboard is empty"
                    font.pixelSize:   14
                    font.bold:        true
                    font.family:      "JetBrainsMono Nerd Font"
                    color:            PanelColors.textDim
                    visible:          root.filteredClipboard.length === 0
                }
            }

            // ── Wallpaper grid ───────────────────────────────────────────
            Item {
                width:   parent.width
                height:  520
                clip:    true
                visible: root.wallpaperMode
                opacity: root.wallpaperMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

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

                        readonly property string filePath: modelData.filePath
                        readonly property string wallName: modelData.wallName

                        width:  wallpaperGrid.cellWidth
                        height: wallpaperGrid.cellHeight

                        Rectangle {
                            anchors { fill: parent; margins: 4 }
                            radius: 10
                            color:  tileHover.containsMouse || index === wallpaperGrid.currentIndex
                                        ? Qt.rgba(1, 1, 1, 0.10)
                                        : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.fill:    parent
                                anchors.margins: 4
                                spacing:         6

                                Item {
                                    id:     thumbContainer
                                    width:  parent.width
                                    height: wallpaperGrid.thumbH - 8

                                    Rectangle {
                                        anchors.fill: parent
                                        color:        PanelColors.rowBackground
                                        radius:       8
                                        visible:      wallImg.status !== Image.Ready
                                    }

                                    Image {
                                        id:              wallImg
                                        anchors.fill:    parent
                                        anchors.margins: 2
                                        source:          "file://" + filePath
                                        sourceSize:      Qt.size(256, 256)
                                        fillMode:        Image.PreserveAspectCrop
                                        asynchronous:    true
                                        cache:           true
                                        smooth:          true
                                        mipmap:          true
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color:        "transparent"
                                        border.color: tileHover.containsMouse || index === wallpaperGrid.currentIndex
                                                          ? PanelColors.launcher
                                                          : PanelColors.border
                                        border.width: 2
                                        radius:       8
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                Text {
                                    width:               parent.width
                                    height:              wallpaperGrid.labelH
                                    text:                wallName
                                    font.pixelSize:      13
                                    font.bold:           true
                                    font.family:         "JetBrainsMono Nerd Font"
                                    color:               index === wallpaperGrid.currentIndex
                                                             ? PanelColors.launcher
                                                             : PanelColors.textMain
                                    Behavior on color    { ColorAnimation { duration: 120 } }
                                    horizontalAlignment: Text.AlignHCenter
                                    elide:               Text.ElideRight
                                    verticalAlignment:   Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                id:           tileHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked: {
                                    wallpaperSetProc.apply(filePath)
                                    root.wallpaperMode = false
                                    searchInput.text   = ""
                                    filterTimer.restart()
                                    LauncherState.hide()
                                }
                            }
                        }
                    }
                }
            }

            // ── Emoji grid ───────────────────────────────────────────────
            Item {
                width:   parent.width
                height:  400
                clip:    true
                visible: root.emojiMode
                opacity: root.emojiMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                GridView {
                    id:           emojiGrid
                    anchors.fill: parent
                    clip:         true

                    readonly property int cols:    9
                    readonly property int cellSz:  Math.floor(width / cols)
                    cellWidth:  cellSz
                    cellHeight: cellSz

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    model: root.filteredEmoji

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width:  emojiGrid.cellSz
                        height: emojiGrid.cellSz

                        Rectangle {
                            anchors { fill: parent; margins: 2 }
                            radius: 8
                            color:  emojiMouse.containsMouse || index === emojiGrid.currentIndex
                                        ? Qt.rgba(1, 1, 1, 0.10)
                                        : "transparent"
                            border.color: index === emojiGrid.currentIndex ? PanelColors.launcher : "transparent"
                            border.width: 2
                            Behavior on color        { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:             modelData.char
                                font.pixelSize:   28
                                font.family:      "Noto Color Emoji"
                            }
                        }

                        MouseArea {
                            id:           emojiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                emojiCopyProc.copyEmoji(modelData.char)
                                root.emojiMode   = false
                                searchInput.text = ""
                                LauncherState.hide()
                            }
                        }

                        ToolTip.visible:   emojiMouse.containsMouse
                        ToolTip.text:      modelData.name
                        ToolTip.delay:     500
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text:             "No emoji found"
                    font.pixelSize:   14
                    font.bold:        true
                    font.family:      "JetBrainsMono Nerd Font"
                    color:            PanelColors.textDim
                    visible:          root.filteredEmoji.length === 0 && searchInput.text !== ""
                }
            }

            // ── App area (grid + list) ────────────────────────────────────
            Item {
                width:   parent.width
                height:  root.isGridView ? 412 : 292
                clip:    true
                visible: !root.wallpaperMode && !root.clipboardMode && !root.emojiMode
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill:    parent
                    z:               0
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onWheel: (wheel) => {
                        if (!root.isGridView) return   // ListView handles its own scroll
                        if (wheel.angleDelta.y < 0) {
                            if (root.currentPage < root.totalPages - 1) root.currentPage++
                        } else {
                            if (root.currentPage > 0) root.currentPage--
                        }
                    }
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton)
                            root._openHiddenMenu()
                    }
                }

                // ── Grid view ────────────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible:      root.isGridView

                    Repeater {
                        id: appsRepeater
                        model: DesktopEntries.applications
                        onCountChanged: { if (!root.wallpaperMode && !root.clipboardMode && !root.emojiMode) filterTimer.restart() }

                        delegate: AppLauncherIcon {
                            appId:               modelData.id
                            appName:             modelData.name
                            appIcon:             modelData.icon
                            appData:             modelData
                            delegateIndex:       index
                            launcherItemsPerPage: root.itemsPerPage
                            launcherCurrentPage:  root.currentPage
                            launcherSelectedIdx:  root.selectedIndex
                            launcherIsGridView:   root.isGridView

                            onLauncherSelectedIdxChanged: {
                                if (root.selectedIndex !== launcherSelectedIdx)
                                    root.selectedIndex = launcherSelectedIdx
                            }
                        }
                    }

                    // ── Command Fallback (grid) ───────────────────────────
                    Rectangle {
                        visible: root.isGridView && root.filteredApps.length === 0 && searchInput.text.trim() !== ""
                        x: 4; y: 4
                        width:  136
                        height: 132
                        radius: 12
                        color:  Qt.rgba(1, 1, 1, 0.08)

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                implicitSize: 64
                                source: "utilities-terminal"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:                "Run: " + searchInput.text
                                font.pixelSize:      13
                                font.bold:           true
                                font.family:         "JetBrainsMono Nerd Font"
                                color:               PanelColors.textMain
                                width:               120
                                horizontalAlignment: Text.AlignHCenter
                                elide:               Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", searchInput.text])
                                LauncherState.hide()
                            }
                        }
                    }
                }

                // ── List view (scrollable) ───────────────────────────────
                ListView {
                    id:           appListView
                    anchors.fill: parent
                    clip:         true
                    spacing:      0
                    visible:      !root.isGridView

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    // Virtual model over filteredApps so ListView handles scroll
                    model: root.filteredApps.length

                    delegate: Item {
                        id: listDelegate
                        required property int index

                        readonly property int origIdx:     root.filteredApps[index] ?? -1
                        readonly property var appIconItem: origIdx >= 0 ? appsRepeater.itemAt(origIdx) : null

                        width:  appListView.width
                        height: 48

                        visible: appIconItem !== null

                        Rectangle {
                            anchors.fill:        parent
                            anchors.leftMargin:  4
                            anchors.rightMargin: 4
                            radius: 10
                            color: listRowHover.containsMouse || root.selectedIndex === listDelegate.origIdx
                                       ? Qt.rgba(1, 1, 1, 0.08)
                                       : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: 3; height: parent.height - 16; radius: 2
                                anchors {
                                    left:           parent.left
                                    leftMargin:     4
                                    verticalCenter: parent.verticalCenter
                                }
                                color:   PanelColors.launcher
                                visible: root.selectedIndex === listDelegate.origIdx
                            }

                            Row {
                                anchors {
                                    fill:         parent
                                    leftMargin:   14
                                    rightMargin:  12
                                }
                                spacing: 12

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 24
                                    source: listDelegate.appIconItem ? Quickshell.iconPath(listDelegate.appIconItem.appIcon) : ""
                                    scale: (root.selectedIndex === listDelegate.origIdx || listRowHover.containsMouse) ? 1.1 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:                listDelegate.appIconItem ? listDelegate.appIconItem.appName : ""
                                    font.pixelSize:      16
                                    font.bold:           true
                                    font.family:         "JetBrainsMono Nerd Font"
                                    color:               PanelColors.textMain
                                    width:               appListView.width - 14 - 24 - 12 - 12 - 8
                                    horizontalAlignment: Text.AlignLeft
                                    elide:               Text.ElideRight
                                }
                            }

                            MouseArea {
                                id:           listRowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:    root.selectedIndex = listDelegate.origIdx
                                onClicked: {
                                    if (listDelegate.appIconItem)
                                        listDelegate.appIconItem.executeApp()
                                }
                            }
                        }
                    }

                    // ── Command Fallback (list) ───────────────────────────
                    footer: Rectangle {
                        visible: !root.isGridView && root.filteredApps.length === 0 && searchInput.text.trim() !== ""
                        width:   appListView.width - 8
                        x:       4
                        height:  44
                        radius:  12
                        color:   Qt.rgba(1, 1, 1, 0.08)

                        Row {
                            anchors.fill:        parent
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            spacing: 12
                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 24
                                source: "utilities-terminal"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:                "Run command: " + searchInput.text
                                font.pixelSize:      16
                                font.bold:           true
                                font.family:         "JetBrainsMono Nerd Font"
                                color:               PanelColors.textMain
                                width:               parent.width - 48
                                horizontalAlignment: Text.AlignLeft
                                elide:               Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", searchInput.text])
                                LauncherState.hide()
                            }
                        }
                    }
                }
            }

            // ── Pagination dots — grid mode only ──────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                visible: root.isGridView && root.totalPages > 1 && !root.wallpaperMode && !root.clipboardMode && !root.emojiMode

                Repeater {
                    model: root.totalPages
                    Rectangle {
                        width:  8
                        height: 8
                        radius: 4
                        color:  index === root.currentPage ? PanelColors.launcher : PanelColors.border
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.currentPage = index
                        }
                    }
                }
            }
        }

        Keys.onEscapePressed: {
            if (root._hiddenMenuOpen) root._closeHiddenMenu()
            else LauncherState.hide()
        }
        focus: true
    }
}
