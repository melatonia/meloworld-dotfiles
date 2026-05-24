// Self-contained emoji picker. Loads emoji.json once, then filters in-memory.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────────
    signal dismissed()

    property var filteredEmoji: []

    function load() {
        if (_allEmoji.length > 0) {
            _applyFilter()
            return
        }
        loaderProc.running = false
        loaderProc.running = true
    }

    function setFilter(query) {
        _query = query
        _applyFilter()
    }

    function navigateUp()      { _move(0,  -1) }
    function navigateDown()    { _move(0,  +1) }
    function navigateLeft()    { _move(-1,  0) }
    function navigateRight()   { _move(+1,  0) }
    function navigateTab()     { _move(+1,  0) }
    function navigateBacktab() { _move(-1,  0) }

    function confirm() {
        if (grid.currentIndex >= 0 && grid.currentIndex < root.filteredEmoji.length) {
            copyProc.copyEmoji(root.filteredEmoji[grid.currentIndex].char)
            root.dismissed()
        }
    }

    // ── Internal ──────────────────────────────────────────────────────────
    property var    _allEmoji: []
    property string _query:    ""

    // Debounce filter so rapid keystrokes don't thrash the model assignment.
    Timer {
        id: filterDebounce
        interval: 40
        onTriggered: root._doApplyFilter()
    }

    function _applyFilter() {
        filterDebounce.restart()
    }

    function _doApplyFilter() {
        var q = _query.toLowerCase()
        root.filteredEmoji = q === "" ? _allEmoji : _allEmoji.filter(function(e) { return e.name.includes(q) })
        grid.currentIndex = 0
    }

    function _move(colDelta, rowDelta) {
        if (root.filteredEmoji.length === 0) return
        var cols   = grid.cols
        var maxIdx = root.filteredEmoji.length - 1
        var cur    = grid.currentIndex < 0 ? 0 : grid.currentIndex
        var next   = Math.max(0, Math.min(cur + colDelta + rowDelta * cols, maxIdx))
        grid.currentIndex = next
        grid.positionViewAtIndex(next, GridView.Contain)
    }

    // ── JSON loader (runs once) ───────────────────────────────────────────
    Process {
        id: loaderProc
        command: ["cat", Quickshell.configDir + "/assets/emoji.json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root._allEmoji = JSON.parse(this.text)
                    root._doApplyFilter()
                } catch (e) {
                    console.warn("LauncherEmojiView: failed to parse emoji.json:", e)
                }
            }
        }
    }

    // ── Copy process ──────────────────────────────────────────────────────
    Process {
        id: copyProc
        running: false
        command: ["true"]
        function copyEmoji(ch) {
            copyProc.command = ["bash", "-c", "printf '%s' '" + ch + "' | wl-copy"]
            copyProc.running = false
            copyProc.running = true
        }
    }

    // ── Grid ─────────────────────────────────────────────────────────────
    GridView {
        id:           grid
        anchors.fill: parent
        clip:         true

        readonly property int cols:   9
        readonly property int cellSz: Math.floor(width / cols)
        cellWidth:  cellSz
        cellHeight: cellSz

        // Pre-render one row above and below the viewport so scrolling
        // doesn't cause sudden delegate creation mid-scroll.
        cacheBuffer: cellSz * 2

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        model: root.filteredEmoji

        // Shared font object — avoids re-evaluating font properties per delegate.
        readonly property font emojiFont: Qt.font({ family: "Noto Color Emoji", pixelSize: 28 })

        delegate: Item {
            required property var modelData
            required property int index

            width:  grid.cellSz
            height: grid.cellSz

            Rectangle {
                anchors { fill: parent; margins: 2 }
                radius: 8
                // No Behavior here — animating color on 50+ cells simultaneously
                // (during scroll or keyboard navigation) causes significant frame drops.
                color:        emojiMouse.containsMouse || index === grid.currentIndex
                                  ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                border.color: index === grid.currentIndex ? PanelColors.launcher : "transparent"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text:             modelData.char
                    font:             grid.emojiFont
                }
            }

            MouseArea {
                id:           emojiMouse
                anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    copyProc.copyEmoji(modelData.char)
                    root.dismissed()
                }
                onContainsMouseChanged: {
                    if (containsMouse) {
                        sharedTooltip.text    = modelData.name
                        sharedTooltip.visible = true
                    } else {
                        sharedTooltip.visible = false
                    }
                }
            }
        }
    }

    // Single shared ToolTip instead of one per delegate (avoids creating
    // hundreds of QQuickToolTip objects for every emoji in the model).
    ToolTip {
        id:      sharedTooltip
        delay:   500
        timeout: 3000
    }

    // Empty state
    Text {
        anchors.centerIn: parent
        text:             "No emoji found"
        font.pixelSize:   14; font.bold: true
        font.family:      "JetBrainsMono Nerd Font"
        color:            PanelColors.textDim
        visible:          root.filteredEmoji.length === 0 && root._query !== ""
    }
}
