// LauncherClipboardView.qml
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

    function showDeleteAllConfirm() {
        if (root.filteredClipboard.length === 0) return
        confirmPopup.opacity = 1
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
        if (list.currentIndex >= result.length) {
            list.currentIndex = Math.max(0, result.length - 1)
        }
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

        property bool isDeleteOp: false

        function copyItem(rawLine) {
            isDeleteOp = false
            var e = rawLine.replace(/'/g, "'\\''")
            actionProc.command = ["bash", "-c", "printf '%s\n' '" + e + "' | cliphist decode | wl-copy"]
            actionProc.running = false
            actionProc.running = true
        }
        function deleteItem(rawLine) {
            isDeleteOp = true
            var e = rawLine.replace(/'/g, "'\\''")
            actionProc.command = ["bash", "-c", "printf '%s\n' '" + e + "' | cliphist delete"]
            actionProc.running = false
            actionProc.running = true
        }
        function deleteAll() {
            isDeleteOp = true
            actionProc.command = ["bash", "-c", "cliphist wipe"]
            actionProc.running = false
            actionProc.running = true
        }

        onRunningChanged: {
            if (!running && isDeleteOp) {
                isDeleteOp = false
                root.load()
            }
        }
    }

    // ── Image decoder (queued) ────────────────────────────────────────────
    // A single Process is reused; jobs are serialised through _decodeQueue
    // so each file is fully written before the next decode begins.
    property var    _decodeQueue: []
    property string decodingId:   ""
    property bool   decodeReady:  false

    function _enqueueImage(itemId, rawLine) {
        // Avoid queueing the same item twice (e.g. panel re-opened)
        for (var i = 0; i < _decodeQueue.length; i++) {
            if (_decodeQueue[i].itemId === itemId) return
        }
        _decodeQueue.push({ itemId: itemId, rawLine: rawLine })
        // Kick off immediately if the decoder is idle
        if (!imgDecodeProc.running && decodingId === "")
            _processNextImage()
    }

    function _processNextImage() {
        if (_decodeQueue.length === 0) {
            decodingId = ""
            return
        }
        var job = _decodeQueue.shift()
        decodingId  = job.itemId
        decodeReady = false
        var e = job.rawLine.replace(/'/g, "'\\''")
        imgDecodeProc.command = ["bash", "-c",
            "printf '%s\n' '" + e + "' | cliphist decode > '/tmp/qs-clip-" + job.itemId + ".png'"]
        imgDecodeProc.running = false
        imgDecodeProc.running = true
    }

    Process {
        id: imgDecodeProc
        running: false
        command: ["true"]

        onRunningChanged: {
            if (!running) {
                root.decodeReady = true
                root._processNextImage()
            }
        }
    }

    // ── Dim overlay ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        PanelColors.barBackground
        opacity:      confirmPopup.opacity * 0.45
        visible:      opacity > 0
        z:            9
    }

    // ── Delete-all confirmation popup ─────────────────────────────────────
    Rectangle {
        id: confirmPopup
        visible: opacity > 0
        opacity: 0
        z: 10
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        anchors.centerIn: parent
        width:  320
        height: confirmCol.implicitHeight + 32
        radius: 10
        color:  PanelColors.popupBackground
        border.color: PanelColors.border
        border.width: 2

        Column {
            id: confirmCol
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   16
                leftMargin:  16
                rightMargin: 16
            }
            spacing: 12

            Text {
                width:               parent.width
                text:                "Clear clipboard history?"
                font.pixelSize:      15
                font.bold:           true
                font.family:         "JetBrainsMono Nerd Font"
                color:               PanelColors.textMain
                horizontalAlignment: Text.AlignHCenter
                wrapMode:            Text.WordWrap
            }

            Text {
                width:               parent.width
                text:                "This will permanently delete all clipboard entries."
                font.pixelSize:      13
                font.family:         "JetBrainsMono Nerd Font"
                color:               PanelColors.textDim
                horizontalAlignment: Text.AlignHCenter
                wrapMode:            Text.WordWrap
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                // Cancel
                Rectangle {
                    width:  130
                    height: 34
                    radius: 6
                    color:  cancelMouse.containsMouse
                                ? Qt.lighter(PanelColors.rowBackground, 1.15)
                                : PanelColors.rowBackground
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text:             "Cancel"
                        font.pixelSize:   13
                        font.bold:        true
                        font.family:      "JetBrainsMono Nerd Font"
                        color:            PanelColors.textMain
                    }

                    MouseArea {
                        id:           cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    confirmPopup.opacity = 0
                    }
                }

                // Delete All
                Rectangle {
                    width:  130
                    height: 34
                    radius: 6
                    color:  deleteAllMouse.containsMouse
                                ? PanelColors.error
                                : PanelColors.rowBackground
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text:             "Delete All"
                        font.pixelSize:   13
                        font.bold:        true
                        font.family:      "JetBrainsMono Nerd Font"
                        color:            deleteAllMouse.containsMouse
                                              ? PanelColors.pillForeground
                                              : PanelColors.error
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id:           deleteAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            confirmPopup.opacity = 0
                            actionProc.deleteAll()
                        }
                    }
                }
            }
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

        readonly property int imageRowH: 160

        delegate: Item {
            required property var modelData
            required property int index

            readonly property bool isImg:      modelData.isImage
            readonly property bool isSelected: index === list.currentIndex
            readonly property string tmpPath:  "/tmp/qs-clip-" + modelData.itemId + ".png"

            width:  list.width
            height: isImg ? list.imageRowH : rowText.implicitHeight + 20

            Component.onCompleted: {
                if (isImg) root._enqueueImage(modelData.itemId, modelData.rawLine)
            }

            Rectangle {
                id: rowRect
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

                    Rectangle {
                        anchors.fill: parent
                        color:        PanelColors.rowBackground
                        radius:       6
                        visible:      clipImg.status !== Image.Ready
                    }

                    Image {
                        id:           clipImg
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
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
                                if (root.decodeReady && root.decodingId === modelData.itemId) {
                                    clipImg.source = ""
                                    clipImg.source = "file://" + tmpPath
                                }
                            }
                        }
                    }

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
                    id:      rowText
                    visible: !isImg
                    width:   parent.width - 14 - 8 - deleteBtn.width - 12
                    anchors {
                        left:           parent.left; leftMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    text:           modelData.content
                    font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                    color:          PanelColors.textMain
                    maximumLineCount: 2
                    wrapMode:         Text.WordWrap
                    elide:            Text.ElideRight
                }

                // ── Per-item delete (X) — shown on hover ──────────────────
                Rectangle {
                    id:      deleteBtn
                    z:       2
                    visible: rowHover.containsMouse || deleteBtnMouse.containsMouse
                    width:   26
                    height:  26
                    radius:  6
                    anchors {
                        right:          parent.right
                        rightMargin:    6
                        top:       parent.top
                        topMargin: 8
                    }
                    color: deleteBtnMouse.containsMouse
                        ? PanelColors.error
                        : PanelColors.rowBackground
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text:             ""
                        font.pixelSize:   12
                        font.bold:        true
                        font.family:      "JetBrainsMono Nerd Font"
                        color:            deleteBtnMouse.containsMouse ? PanelColors.pillForeground : PanelColors.textDim
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id:           deleteBtnMouse
                        anchors.fill: parent
                        z:            3
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            mouse.accepted = true
                            actionProc.deleteItem(modelData.rawLine)
                        }
                    }
                }

                // Row hover — sits below the X button via z ordering
                MouseArea {
                    id:           rowHover
                    anchors.fill: parent
                    z:            1
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onEntered:    list.currentIndex = index
                    onClicked: (mouse) => {
                        if (deleteBtnMouse.containsMouse) return
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
        text:             "󰺝 clipboard is empty.."
        font.pixelSize:   14; font.bold: true
        font.family:      "JetBrainsMono Nerd Font"
        color:            PanelColors.textDim
        visible:          root.filteredClipboard.length === 0 && !clipboardProc.running
    }
}
