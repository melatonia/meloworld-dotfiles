// LauncherClipboardView.qml
// Self-contained clipboard history picker using cliphist.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────────
    signal dismissed()

    property var filteredClipboard: []

    function load() {
        clipboardModel.clear()
        root.filteredClipboard = []
        clipboardProc.running = false
        clipboardProc.running = true
    }

    function setFilter(query) {
        _query = query
        _applyFilter()
    }

    function navigateUp()      { _move(-1) }
    function navigateDown()    { _move(+1) }
    function navigateTab()     { _move(+1) }
    function navigateBacktab() { _move(-1) }

    function deleteSelected() {
        if (root.filteredClipboard.length > 0 && list.currentIndex >= 0) {
            actionProc.deleteItem(root.filteredClipboard[list.currentIndex].rawLine)
        }
    }

    function confirm() {
        if (list.currentIndex >= 0 && list.currentIndex < root.filteredClipboard.length) {
            actionProc.copyItem(root.filteredClipboard[list.currentIndex].rawLine)
            root.dismissed()
        }
    }

    // ── Internal ──────────────────────────────────────────────────────────
    property string _query: ""

    function _applyFilter() {
        var q = _query.toLowerCase()
        var result = []
        for (var i = 0; i < clipboardModel.count; i++) {
            var e = clipboardModel.get(i)
            if (q === "" || e.content.toLowerCase().includes(q))
                result.push({ itemId: e.itemId, content: e.content, rawLine: e.rawLine, isImage: e.isImage })
        }
        root.filteredClipboard = result
        list.currentIndex = 0
    }

    function _move(delta) {
        if (root.filteredClipboard.length === 0) return
        var next = Math.max(0, Math.min((list.currentIndex < 0 ? 0 : list.currentIndex) + delta,
                                        root.filteredClipboard.length - 1))
        list.currentIndex = next
        list.positionViewAtIndex(next, ListView.Contain)
    }

    // ── Model + processes ─────────────────────────────────────────────────
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
                        var content = parts.slice(1).join("\t")
                        var isImage = content.startsWith("[[ binary data")
                        clipboardModel.append({ itemId: parts[0], content: content, rawLine: line, isImage: isImage })
                    }
                }
                root._applyFilter()
            }
        }
    }

    Process {
        id: actionProc
        running: false
        command: ["true"]

        function copyItem(rawLine) {
            var e = rawLine.replace(/'/g, "'\\''")
            actionProc.command = ["bash", "-c", "printf '%s\n' '" + e + "' | cliphist decode | wl-copy"]
            actionProc.running = false
            actionProc.running = true
        }
        function deleteItem(rawLine) {
            var e = rawLine.replace(/'/g, "'\\''")
            actionProc.command = ["bash", "-c", "printf '%s\n' '" + e + "' | cliphist delete"]
            actionProc.running = false
            actionProc.running = true
            root.load()
        }
    }

    // ── Image decoder ─────────────────────────────────────────────────────
    // Decodes a cliphist entry to a tmp file, then signals done so the
    // Image item can reload. One shared process is enough — images decode fast.
    property string _decodingId:  ""
    property bool   _decodeReady: false

    Process {
        id: imgDecodeProc
        running: false
        command: ["true"]

        function decode(itemId, rawLine) {
            root._decodingId  = itemId
            root._decodeReady = false
            var e = rawLine.replace(/'/g, "'\\''")
            imgDecodeProc.command = ["bash", "-c",
                "printf '%s\n' '" + e + "' | cliphist decode > '/tmp/qs-clip-" + itemId + ".png'"]
            imgDecodeProc.running = false
            imgDecodeProc.running = true
        }

        onRunningChanged: {
            if (!running) root._decodeReady = true
        }
    }

    // ── List ──────────────────────────────────────────────────────────────
    ListView {
        id:           list
        anchors.fill: parent
        clip:         true
        spacing:      2

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        model: root.filteredClipboard

        readonly property int textRowH:  42
        readonly property int imageRowH: 160

        delegate: Item {
            required property var modelData
            required property int index

            readonly property bool isImg:      modelData.isImage
            readonly property bool isSelected: index === list.currentIndex
            readonly property string tmpPath:  "/tmp/qs-clip-" + modelData.itemId + ".png"

            width:  list.width
            height: isImg ? list.imageRowH : list.textRowH

            // Decode as soon as this delegate is created
            Component.onCompleted: {
                if (isImg) imgDecodeProc.decode(modelData.itemId, modelData.rawLine)
            }

            Rectangle {
                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                radius: 6
                color: isSelected
                           ? Qt.rgba(1, 1, 1, 0.10)
                           : rowHover.containsMouse
                               ? Qt.rgba(1, 1, 1, 0.06)
                               : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                // Left accent bar
                Rectangle {
                    width: 3; height: parent.height - 12; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color:   PanelColors.launcher
                    visible: isSelected
                }

                // ── Image row ─────────────────────────────────────────────
                Item {
                    visible: isImg
                    anchors {
                        top:         parent.top;    topMargin:    8
                        bottom:      parent.bottom; bottomMargin: 8
                        left:        parent.left;   leftMargin:   14
                        right:       parent.right;  rightMargin:  12
                    }

                    // Placeholder while decoding
                    Rectangle {
                        anchors.fill: parent
                        color:        PanelColors.rowBackground
                        radius:       6
                        visible:      clipImg.status !== Image.Ready
                    }

                    Image {
                        id:           clipImg
                        anchors {
                            left:   parent.left
                            top:    parent.top
                            bottom: parent.bottom
                        }
                        width:        status === Image.Ready
                                          ? Math.min(implicitWidth, parent.width)
                                          : parent.width
                        fillMode:     Image.PreserveAspectFit
                        asynchronous: true
                        cache:        false
                        smooth:       true
                        mipmap:       true
                        sourceSize:   Qt.size(480, 480)

                        Connections {
                            target: root
                            function onDecodeReadyChanged() {
                                if (root._decodeReady && root._decodingId === modelData.itemId) {
                                    clipImg.source = ""
                                    clipImg.source = "file://" + tmpPath
                                }
                            }
                        }
                    }

                    // Border overlay — same pattern as wallpaper view
                    Rectangle {
                        width:  clipImg.width
                        height: clipImg.height
                        anchors { left: parent.left; top: parent.top }
                        color:        "transparent"
                        border.color: isSelected ? PanelColors.launcher : PanelColors.border
                        border.width: 2
                        radius:       6
                        visible:      clipImg.status === Image.Ready
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }
                }

                // ── Text row ──────────────────────────────────────────────
                Text {
                    visible: !isImg
                    anchors {
                        left:           parent.left;  leftMargin:  14
                        right:          parent.right; rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text:           modelData.content
                    font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                    color:          PanelColors.textMain
                    elide:          Text.ElideRight
                }

                MouseArea {
                    id:           rowHover
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        actionProc.copyItem(modelData.rawLine)
                        root.dismissed()
                    }
                }
            }
        }
    }

    // Empty state
    Text {
        anchors.centerIn: parent
        text:             "Clipboard is empty"
        font.pixelSize:   14; font.bold: true
        font.family:      "JetBrainsMono Nerd Font"
        color:            PanelColors.textDim
        visible:          root.filteredClipboard.length === 0
    }
}
