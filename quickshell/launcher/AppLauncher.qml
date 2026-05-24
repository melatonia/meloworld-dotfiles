import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Qt.labs.settings
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

    // ── State ─────────────────────────────────────────────────────────────
    property string animState:     "closed"
    property int    selectedIndex: -1

    property bool wallpaperMode: false
    property bool clipboardMode: false
    property bool emojiMode:     false
    property bool hiddenMode:    false

    property bool isGridView: false
    Settings {
        fileName: Quickshell.env("HOME") + "/.config/meloworld-dotfiles/settings.conf"
        category: "Launcher"
        property alias isGridView: root.isGridView
    }

    property int  currentPage:  0
    property int  totalPages:   1
    property var  filteredApps: []
    readonly property int itemsPerPage: isGridView ? 15 : 0

    // ── Mode helpers ──────────────────────────────────────────────────────
    function _resetModes() {
        wallpaperMode = false
        clipboardMode = false
        emojiMode     = false
        hiddenMode    = false
    }

    function _pillText() {
        if (wallpaperMode) return "󰸉 Wallpaper"
        if (clipboardMode) return "󰅌 Clipboard"
        if (emojiMode)     return "󰞅 Emoji"
        if (hiddenMode)    return " Hidden"
        return ""
    }

    function _placeholder() {
        if (wallpaperMode) return "Search wallpapers..."
        if (clipboardMode) return "Search clipboard..."
        if (emojiMode)     return "Search emoji..."
        if (hiddenMode)    return "Hidden apps..."
        return "Search..."
    }

    // ── Panel width ───────────────────────────────────────────────────────
    readonly property int panelWidth: {
        if (wallpaperMode) return 900
        if (clipboardMode) return 600
        if (emojiMode)     return 400
        if (hiddenMode)    return isGridView ? 740 : 600
        return isGridView  ? 740 : 600
    }

    // ── App filter ────────────────────────────────────────────────────────
    Timer {
        id: filterTimer
        interval: 10
        onTriggered: _updateFilter()
    }

    function _updateFilter() {
        var firstMatch = -1
        var items = []
        var q = searchBar.text.toLowerCase()

        for (var i = 0; i < appView.appsRepeaterCount; i++) {
            var item = appView.appItemAt(i)
            if (!item) continue

            var hidden    = LauncherHiddenApps.isHidden(item.appId)
            var nameMatch = q === "" ||
                item.appName.toLowerCase().includes(q) ||
                (item.appData && item.appData.genericName && String(item.appData.genericName).toLowerCase().includes(q)) ||
                (item.appData && item.appData.comment    && String(item.appData.comment).toLowerCase().includes(q))    ||
                (item.appData && item.appData.keywords   && String(item.appData.keywords).toLowerCase().includes(q))

            var isMatch = !hidden && nameMatch
            item.isMatch = isMatch

            if (isMatch) {
                items.push({ item: item, origIndex: i,
                             usage: AppUsageTracker.getUsage(item.appId),
                             name:  item.appName.toLowerCase() })
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

        root.filteredApps    = mapped
        appView.filteredApps = mapped
        root.totalPages      = Math.max(1, Math.ceil(items.length / (root.isGridView ? 15 : 1)))
        if (root.currentPage >= root.totalPages)
            root.currentPage = Math.max(0, root.totalPages - 1)
        root.selectedIndex    = firstMatch
        appView.selectedIndex = firstMatch
    }

    // ── Connections ───────────────────────────────────────────────────────
    Connections {
        target: LauncherState
        function onVisibleChanged() {
            root.animState = LauncherState.visible ? "open" : "closing"
            if (LauncherState.visible) {
                appView.closeHiddenMenu()
                if (!wallpaperMode && !clipboardMode && !emojiMode && !hiddenMode)
                    filterTimer.restart()
            } else {
                appView.closeHiddenMenu()
            }
        }
    }
    Connections {
        target: LauncherHiddenApps
        function onHiddenAppsChanged() { if (!wallpaperMode && !clipboardMode && !emojiMode && !hiddenMode) filterTimer.restart() }
    }
    Connections {
        target: AppUsageTracker
        function onUsageMapChanged()   { if (!wallpaperMode && !clipboardMode && !emojiMode && !hiddenMode) filterTimer.restart() }
    }

    onAnimStateChanged: {
        if (animState === "open") searchBar.forceActiveFocus()
    }

    // ── Ctrl+G: toggle grid/list ──────────────────────────────────────────
    Shortcut {
        sequence: "Ctrl+G"
        onActivated: {
            if (wallpaperMode || clipboardMode || emojiMode || hiddenMode) return
            root.isGridView    = !root.isGridView
            appView.isGridView = root.isGridView
            filterTimer.restart()
        }
    }

    // ── IPC ───────────────────────────────────────────────────────────────
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (!LauncherState.visible) {
                root._resetModes()
                root.currentPage = 0
                searchBar.clear()
            }
            LauncherState.toggle()
        }

        function openWallpaper(): void {
            root._resetModes()
            root.wallpaperMode = true
            searchBar.clear()
            LauncherState.show()
            wallpaperView.load()
            searchBar.forceActiveFocus()
        }

        function openClipboard(): void {
            root._resetModes()
            root.clipboardMode = true
            searchBar.clear()
            LauncherState.show()
            clipboardView.load()
            searchBar.forceActiveFocus()
        }

        function openEmoji(): void {
            root._resetModes()
            root.emojiMode = true
            searchBar.clear()
            LauncherState.show()
            emojiView.load()
            searchBar.forceActiveFocus()
        }
    }

    // ── Panel ─────────────────────────────────────────────────────────────
    Rectangle {
        id: panel

        width:  root.panelWidth
        height: panelColumn.implicitHeight + 28

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

        opacity:   0.0
        transform: Translate { id: panelSlide; y: 28 }

        HoverHandler { onHoveredChanged: { if (hovered) panel.forceActiveFocus() } }

        states: [
            State {
                name: "open";    when: root.animState === "open"
                PropertyChanges { target: panel;      opacity: 1.0 }
                PropertyChanges { target: panelSlide; y: 0         }
            },
            State {
                name: "closing"; when: root.animState === "closing"
                PropertyChanges { target: panel;      opacity: 0.0 }
                PropertyChanges { target: panelSlide; y: 28        }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                SequentialAnimation {
                    PropertyAction  { target: panelSlide; property: "y";       value: 28  }
                    PropertyAction  { target: panel;      property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation { target: panelSlide; property: "y";       to: 0;   duration: 280; easing.type: Easing.OutExpo  }
                        NumberAnimation { target: panel;      property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: panelSlide; property: "y";       to: 28;  duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { target: panel;      property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        Column {
            id: panelColumn
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 14; leftMargin: 10; rightMargin: 10; bottomMargin: 10 }
            spacing: 8

            readonly property int rowH:    42
            readonly property int maxRows: 6

            // ── Search bar row ────────────────────────────────────────────
            LauncherSearchBar {
                id: searchBar
                width: parent.width
                anchors.left:        parent.left
                anchors.right:       parent.right
                anchors.leftMargin:  4
                anchors.rightMargin: 4


                pillText:    root._pillText()
                placeholder: root._placeholder()

                rightPillText: {
                    if (root.clipboardMode) return "󰩺"
                    if (!root.wallpaperMode && !root.emojiMode && !root.hiddenMode)
                        return root.isGridView ? "" : "󱗼"
                    return ""
                }
                rightPillDestructive: root.clipboardMode
                rightPillTooltip: {
                    if (root.clipboardMode) return "Clear all clipboard history"
                    if (!root.wallpaperMode && !root.emojiMode && !root.hiddenMode)
                        return root.isGridView ? "Switch to list view" : "Switch to grid view"
                    return ""
                }

                onRightPillClicked: {
                    if (root.clipboardMode) {
                        clipboardView.showDeleteAllConfirm()
                    } else {
                        root.isGridView    = !root.isGridView
                        appView.isGridView = root.isGridView
                        filterTimer.restart()
                    }
                }

                onTextChanged: {
                    var t = searchBar.text
                    if (!root.wallpaperMode && !root.clipboardMode && !root.emojiMode && !root.hiddenMode) {
                        if (t === "/w") {
                            root._resetModes()
                            root.wallpaperMode = true
                            searchBar.clear()
                            wallpaperView.load()
                            return
                        }
                        if (t === "/h") {
                            root._resetModes()
                            root.hiddenMode = true
                            searchBar.clear()
                            return
                        }
                        if (t === "/g") {
                            root.isGridView    = !root.isGridView
                            appView.isGridView = root.isGridView
                            searchBar.clear()
                            filterTimer.restart()
                            return
                        }
                    }
                    if (root.wallpaperMode)      wallpaperView.setFilter(t)
                    else if (root.clipboardMode) clipboardView.setFilter(t)
                    else if (root.emojiMode)     emojiView.setFilter(t)
                    else if (!root.hiddenMode)   filterTimer.restart()
                }

                onUpPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateUp()
                    else if (root.clipboardMode) clipboardView.navigateUp()
                    else if (root.emojiMode)     emojiView.navigateUp()
                    else                         appView.navigateGrid(0, -1)
                }
                onDownPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateDown()
                    else if (root.clipboardMode) clipboardView.navigateDown()
                    else if (root.emojiMode)     emojiView.navigateDown()
                    else                         appView.navigateGrid(0, +1)
                }
                onLeftPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateLeft()
                    else if (root.emojiMode)     emojiView.navigateLeft()
                    else if (root.isGridView)    appView.navigateGrid(-1, 0)
                }
                onRightPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateRight()
                    else if (root.emojiMode)     emojiView.navigateRight()
                    else if (root.isGridView)    appView.navigateGrid(+1, 0)
                }
                onTabPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateTab()
                    else if (root.clipboardMode) clipboardView.navigateTab()
                    else if (root.emojiMode)     emojiView.navigateTab()
                    else                         appView.navigateGrid(+1, 0)
                }
                onBacktabPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateBacktab()
                    else if (root.clipboardMode) clipboardView.navigateBacktab()
                    else if (root.emojiMode)     emojiView.navigateBacktab()
                    else                         appView.navigateGrid(-1, 0)
                }
                onDeletePressed: {
                    if (root.clipboardMode) clipboardView.deleteSelected()
                }
                onReturnPressed: {
                    if      (root.wallpaperMode) wallpaperView.confirm()
                    else if (root.clipboardMode) clipboardView.confirm()
                    else if (root.emojiMode)     emojiView.confirm()
                    else if (!root.hiddenMode) {
                        if (root.selectedIndex !== -1) {
                            var item = appView.appItemAt(root.selectedIndex)
                            if (item) item.executeApp()
                        } else if (searchBar.text.trim() !== "") {
                            Quickshell.execDetached(["bash", "-c", searchBar.text])
                            LauncherState.hide()
                        }
                    }
                }
                onEscapePressed: {
                    if (root.wallpaperMode || root.clipboardMode || root.emojiMode || root.hiddenMode)
                        LauncherState.hide()
                    else if (appView._hiddenMenuOpen)
                        appView.closeHiddenMenu()
                    else
                        LauncherState.hide()
                }
            }

            // ── Clipboard view ────────────────────────────────────────────
            LauncherClipboardView {
                id:      clipboardView
                width:   parent.width
                height:  260
                visible: root.clipboardMode
                clip:    true
                opacity: root.clipboardMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                onDismissed: { LauncherState.hide(); root._resetModes(); searchBar.clear() }
            }

            // ── Wallpaper view ────────────────────────────────────────────
            LauncherWallpaperView {
                id:      wallpaperView
                width:   parent.width
                height:  660
                visible: root.wallpaperMode
                clip:    true
                opacity: root.wallpaperMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                onDismissed: { LauncherState.hide(); root._resetModes(); searchBar.clear(); filterTimer.restart() }
            }

            // ── Emoji view ────────────────────────────────────────────────
            LauncherEmojiView {
                id:      emojiView
                width:   parent.width
                height:  336
                visible: root.emojiMode
                clip:    true
                opacity: root.emojiMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                onDismissed: { LauncherState.hide(); root._resetModes(); searchBar.clear() }
            }

            // ── Hidden apps view ──────────────────────────────────────────
            Item {
                id:      hiddenAppsView
                width:   parent.width
                height:  root.isGridView ? 412 : 262
                visible: root.hiddenMode
                clip:    true
                opacity: root.hiddenMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text:             "No hidden apps"
                    font.pixelSize:   14
                    font.bold:        true
                    font.family:      "JetBrainsMono Nerd Font"
                    color:            PanelColors.textDim
                    visible:          LauncherHiddenApps.hiddenApps.length === 0
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: root.isGridView ? hiddenGridComp : hiddenListComp
                }

                Component {
                    id: hiddenGridComp
                    GridView {
                        anchors.fill: parent
                        clip: true
                        cellWidth:  136
                        cellHeight: 132
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        model: LauncherHiddenApps.hiddenApps
                        delegate: Item {
                            required property var modelData
                            width: 136; height: 132
                            Rectangle {
                                anchors { fill: parent; margins: 8 }
                                radius: 12
                                color: gridHiddenHover.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    x:     4
                                    width: parent.width - 8
                                    IconImage {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        implicitSize: 64
                                        source: Quickshell.iconPath(modelData.icon)
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.name
                                        font.pixelSize: 14; font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textMain
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        maximumLineCount: 2; elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: gridHiddenHover
                                    anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        LauncherHiddenApps.show(modelData.id)
                                        filterTimer.restart()
                                    }
                                }
                            }
                        }
                    }
                }

                Component {
                    id: hiddenListComp
                    ListView {
                        anchors.fill: parent
                        clip: true; spacing: 2
                        model: LauncherHiddenApps.hiddenApps
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        delegate: Item {
                            id: hiddenDelegate
                            required property var modelData
                            width: ListView.view.width; height: 44
                            Rectangle {
                                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                                radius: 6
                                color: hiddenRowHover.containsMouse ? PanelColors.rowBackground : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Row {
                                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                    spacing: 12
                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitSize: 22
                                        source: Quickshell.iconPath(modelData.icon)
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        font.pixelSize: 16; font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textMain
                                        width: hiddenAppsView.width - 14 - 22 - 12 - 12 - 8
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: hiddenRowHover
                                    anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        LauncherHiddenApps.show(modelData.id)
                                        filterTimer.restart()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── App view ──────────────────────────────────────────────────
            LauncherAppView {
                id:           appView
                width:        parent.width
                searchText:   searchBar.text
                height:       root.isGridView
                                  ? 412
                                  : (function() { var n = Math.min(Math.max(root.filteredApps.length, searchBar.text.trim() !== "" ? 1 : 0), panelColumn.maxRows); return n * panelColumn.rowH + Math.max(0, n - 1) * 2 }())
                clip:         true
                visible:      !root.wallpaperMode && !root.clipboardMode && !root.emojiMode && !root.hiddenMode
                isGridView:   root.isGridView
                currentPage:  root.currentPage
                filteredApps: root.filteredApps
                selectedIndex: root.selectedIndex

                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                onFilterRequested:      filterTimer.restart()
                onSelectedIndexChanged: (idx) => { root.selectedIndex = idx }
                onPageChangeRequested:  (delta) => {
                    var next = root.currentPage + delta
                    if (next >= 0 && next < root.totalPages) root.currentPage = next
                }
            }

            // ── Pagination dots (grid mode only) ──────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                visible: root.isGridView && root.totalPages > 1
                         && !root.wallpaperMode && !root.clipboardMode && !root.emojiMode && !root.hiddenMode

                Repeater {
                    model: root.totalPages
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: index === root.currentPage ? PanelColors.launcher : PanelColors.border
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = index
                        }
                    }
                }
            }
        }

        Keys.onEscapePressed: {
            if (appView._hiddenMenuOpen) appView.closeHiddenMenu()
            else LauncherState.hide()
        }
        focus: true
    }
}
