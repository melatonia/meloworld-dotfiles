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

    // True when the app grid is the active view. Used by appView, dotsRow,
    // and the filter connections so they all reference one source of truth.
    readonly property bool appModeActive: !wallpaperMode && !clipboardMode
                                          && !emojiMode && !hiddenMode

    property bool isGridView: false
    Settings {
        fileName: Quickshell.env("HOME") + "/.config/meloworld-dotfiles/settings.conf"
        category: "Launcher"
        property alias isGridView: root.isGridView
    }

    property int currentPage:  0
    property var filteredApps: []

    // Derived synchronously from filteredApps — never stale, no filterReady needed.
    readonly property int totalPages: isGridView
        ? Math.max(1, Math.ceil(filteredApps.length / 15))
        : 1

    // Controls whether the panel width animates. True only during grid↔list
    // toggle so the resize is intentional. False for all other mode switches.
    property bool animateWidth: false

    // ── Mode switching ────────────────────────────────────────────────────
    // All four flags are set in one JS call so QML batches them into a single
    // binding evaluation pass. No intermediate all-false frame ever occurs,
    // which is what caused the dots to flash when opening clipboard/emoji/wallpaper
    // while in grid mode.
    function _switchMode(wall, clip, emoji, hidden) {
        wallpaperMode = wall
        clipboardMode = clip
        emojiMode     = emoji
        hiddenMode    = hidden
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

        if (root.currentPage >= root.totalPages)
            root.currentPage = Math.max(0, root.totalPages - 1)

        root.selectedIndex    = firstMatch
        appView.selectedIndex = firstMatch
        root.animateWidth     = false
    }

    // ── Connections ───────────────────────────────────────────────────────
    Connections {
        target: LauncherState
        function onVisibleChanged() {
            root.animState = LauncherState.visible ? "open" : "closing"
            if (LauncherState.visible) {
                appView.closeHiddenMenu()
                if (root.appModeActive) filterTimer.restart()
            } else {
                appView.closeHiddenMenu()
            }
        }
    }
    Connections {
        target: LauncherHiddenApps
        function onHiddenAppsChanged() { if (root.appModeActive) filterTimer.restart() }
    }
    Connections {
        target: AppUsageTracker
        function onUsageMapChanged()   { if (root.appModeActive) filterTimer.restart() }
    }

    onAnimStateChanged: {
        if (animState === "open")   searchBar.forceActiveFocus()
        // Reset modes only after the panel has fully closed — prevents the
        // one-frame flash back to the app grid after dismissing a sub-view.
        if (animState === "closed") root._switchMode(false, false, false, false)
    }

    // ── Ctrl+G: toggle grid/list ──────────────────────────────────────────
    Shortcut {
        sequence: "Ctrl+G"
        onActivated: {
            if (!root.appModeActive) return
            root.animateWidth = true
            root.isGridView   = !root.isGridView
            filterTimer.restart()
        }
    }

    // ── IPC ───────────────────────────────────────────────────────────────
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (!LauncherState.visible) {
                root._switchMode(false, false, false, false)
                root.currentPage = 0
                searchBar.clear()
            }
            LauncherState.toggle()
        }

        function openWallpaper(): void {
            root._switchMode(true, false, false, false)
            searchBar.clear()
            LauncherState.show()
            wallpaperView.load()
            searchBar.forceActiveFocus()
        }

        function openClipboard(): void {
            root._switchMode(false, true, false, false)
            searchBar.clear()
            LauncherState.show()
            clipboardView.load()
            searchBar.forceActiveFocus()
        }

        function openEmoji(): void {
            root._switchMode(false, false, true, false)
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

        // Width only animates during intentional grid↔list toggles (animateWidth:
        // true). All other mode switches snap instantly.
        Behavior on width {
            enabled: root.animateWidth
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

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

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    root.requestActivate()
                    searchBar.forceActiveFocus()
                }
            }
        }

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
                    // Snap width and height to their current binding values
                    // before the panel becomes visible. This prevents the
                    // morph animation when reopening after a different-sized
                    // mode was last active (e.g. wallpaper 900px → normal 600px).
                    PropertyAction  { target: panel;      property: "width"   }
                    PropertyAction  { target: panel;      property: "height"  }
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
                    // animState "closed" triggers _switchMode(all false) via onAnimStateChanged,
                    // so modes are cleared only after the panel is invisible.
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

            // ── Search bar ────────────────────────────────────────────────
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
                    if (root.appModeActive)
                        return root.isGridView ? "" : ""
                    return ""
                }
                rightPillDestructive: root.clipboardMode
                rightPillDisabled:    root.clipboardMode && clipboardView.filteredClipboard.length === 0
                rightPillTooltip: {
                    if (root.clipboardMode) return "Clear all clipboard history"
                    if (root.appModeActive)
                        return root.isGridView ? "Switch to list view" : "Switch to grid view"
                    return ""
                }

                onRightPillClicked: {
                    if (root.clipboardMode) {
                        clipboardView.showDeleteAllConfirm()
                    } else {
                        root.animateWidth = true
                        root.isGridView   = !root.isGridView
                        filterTimer.restart()
                    }
                }

                onTextChanged: {
                    var t = searchBar.text
                    if (root.appModeActive) {
                        if (t === "/w") {
                            root._switchMode(true, false, false, false)
                            searchBar.clear()
                            wallpaperView.load()
                            return
                        }
                        if (t === "/h") {
                            root._switchMode(false, false, false, true)
                            searchBar.clear()
                            return
                        }
                        if (t === "/g") {
                            root.animateWidth = true
                            root.isGridView   = !root.isGridView
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
                    else if (root.hiddenMode)    hiddenAppsView.navigateUp()
                    else                         appView.navigateGrid(0, -1)
                }
                onDownPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateDown()
                    else if (root.clipboardMode) clipboardView.navigateDown()
                    else if (root.emojiMode)     emojiView.navigateDown()
                    else if (root.hiddenMode)    hiddenAppsView.navigateDown()
                    else                         appView.navigateGrid(0, +1)
                }
                onLeftPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateLeft()
                    else if (root.emojiMode)     emojiView.navigateLeft()
                    else if (root.hiddenMode && root.isGridView) hiddenAppsView.navigateLeft()
                    else if (root.isGridView)    appView.navigateGrid(-1, 0)
                }
                onRightPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateRight()
                    else if (root.emojiMode)     emojiView.navigateRight()
                    else if (root.hiddenMode && root.isGridView) hiddenAppsView.navigateRight()
                    else if (root.isGridView)    appView.navigateGrid(+1, 0)
                }
                onTabPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateTab()
                    else if (root.clipboardMode) clipboardView.navigateTab()
                    else if (root.emojiMode)     emojiView.navigateTab()
                    else if (root.hiddenMode)    hiddenAppsView.navigateTab()
                    else                         appView.navigateGrid(+1, 0)
                }
                onBacktabPressed: {
                    if      (root.wallpaperMode) wallpaperView.navigateBacktab()
                    else if (root.clipboardMode) clipboardView.navigateBacktab()
                    else if (root.emojiMode)     emojiView.navigateBacktab()
                    else if (root.hiddenMode)    hiddenAppsView.navigateBacktab()
                    else                         appView.navigateGrid(-1, 0)
                }
                onDeletePressed: {
                    if (root.clipboardMode) clipboardView.deleteSelected()
                }
                onReturnPressed: {
                    if      (root.wallpaperMode) wallpaperView.confirm()
                    else if (root.clipboardMode) clipboardView.confirm()
                    else if (root.emojiMode)     emojiView.confirm()
                    else if (root.hiddenMode)    hiddenAppsView.confirm()
                    else {
                        if (appView.selectedIndex !== -1) {
                            var item = appView.appItemAt(appView.selectedIndex)
                            if (item) item.executeApp()
                        } else if (searchBar.text.trim() !== "") {
                            Quickshell.execDetached(["bash", "-c", searchBar.text])
                            LauncherState.hide()
                        }
                    }
                }
                onEscapePressed: {
                    if (!root.appModeActive)
                        LauncherState.hide()
                    else if (appView._hiddenMenuOpen)
                        appView.closeHiddenMenu()
                    else
                        LauncherState.hide()
                }
            }

            // ── Clipboard view ────────────────────────────────────────────
            // Height snaps instantly so the panel resizes in one frame.
            // Opacity fades in/out to provide smooth visual open/close.
            // visible:height>0 prevents input stealing while collapsed.
            LauncherClipboardView {
                id:    clipboardView
                width: parent.width

                height:  root.clipboardMode ? 360 : 0
                clip:    true
                visible: height > 0
                opacity: root.clipboardMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                onDismissed: { LauncherState.hide(); searchBar.clear() }
            }

            // ── Wallpaper view ────────────────────────────────────────────
            LauncherWallpaperView {
                id:    wallpaperView
                width: parent.width

                height:  root.wallpaperMode ? 660 : 0
                clip:    true
                visible: height > 0
                opacity: root.wallpaperMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                onDismissed: { LauncherState.hide(); searchBar.clear(); filterTimer.restart() }
            }

            // ── Emoji view ────────────────────────────────────────────────
            LauncherEmojiView {
                id:    emojiView
                width: parent.width

                // Height snaps instantly — no Behavior. Animating height while
                // the GridView is simultaneously populating delegates forces a
                // full relayout every frame and causes lag. The opacity fade
                // provides sufficient open/close visual polish.
                height:  root.emojiMode ? 336 : 0
                clip:    true
                visible: height > 0
                opacity: root.emojiMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                onDismissed: { LauncherState.hide(); searchBar.clear() }
            }

            // ── Hidden apps view ──────────────────────────────────────────
            Item {
                id:    hiddenAppsView
                width: parent.width

                height:  root.hiddenMode ? (root.isGridView ? 412 : 262) : 0
                clip:    true
                visible: height > 0
                opacity: root.hiddenMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // ── Keyboard Navigation ───────────────────────────────────
                property int selectedIndex: 0

                onVisibleChanged: {
                    if (visible) selectedIndex = 0
                }

                function navigateUp()      { _move(0, -1) }
                function navigateDown()    { _move(0, +1) }
                function navigateLeft()    { _move(-1, 0) }
                function navigateRight()   { _move(+1, 0) }
                function navigateTab()     { _move(+1, 0) }
                function navigateBacktab() { _move(-1, 0) }

                function _move(colDelta, rowDelta) {
                    var count = LauncherHiddenApps.hiddenApps.length
                    if (count === 0) return

                    // Grid mode has 5 columns, List mode has 1
                    var cols = root.isGridView ? 5 : 1
                    var next = Math.max(0, Math.min(selectedIndex + colDelta + rowDelta * cols, count - 1))

                    selectedIndex = next

                    // positionViewAtIndex works for both ListView and GridView
                    if (hiddenAppsLoader.item) {
                        hiddenAppsLoader.item.positionViewAtIndex(next, ListView.Contain)
                    }
                }

                function confirm() {
                    if (selectedIndex >= 0 && selectedIndex < LauncherHiddenApps.hiddenApps.length) {
                        var app = LauncherHiddenApps.hiddenApps[selectedIndex]
                        LauncherHiddenApps.show(app.id) // This unhides the app
                        filterTimer.restart()
                    }
                }
                // ──────────────────────────────────────────────────────────

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
                    id: hiddenAppsLoader
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
                            required property int index
                            width: 136; height: 132
                            Rectangle {
                                anchors { fill: parent; margins: 8 }
                                radius: 12
                                color: gridHiddenHover.containsMouse || hiddenAppsView.selectedIndex === index
                                       ? Qt.rgba(1,1,1,0.08) : "transparent"
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
                                    onEntered: hiddenAppsView.selectedIndex = index
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
                            required property int index
                            width: ListView.view.width; height: 44
                            Rectangle {
                                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                                radius: 6
                                color: hiddenRowHover.containsMouse || hiddenAppsView.selectedIndex === index
                                       ? PanelColors.rowBackground : "transparent"
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
                                    onEntered: hiddenAppsView.selectedIndex = index
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

                // Height is 0 when any other mode is active so appView contributes
                // nothing to panelColumn.implicitHeight. The Behavior only fires
                // when appModeActive is true (switching grid↔list), so the height
                // snap to 0 is always instant and silent.
                readonly property int activeHeight: root.isGridView
                    ? 412
                    : (function() {
                        var n = Math.min(Math.max(root.filteredApps.length, searchBar.text.trim() !== "" ? 1 : 0), panelColumn.maxRows)
                        return n * panelColumn.rowH + Math.max(0, n - 1) * 2
                      }())
                height: root.appModeActive ? activeHeight : 0
                Behavior on height {
                    enabled: root.appModeActive
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                clip:    true
                opacity: root.appModeActive ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                visible: opacity > 0

                isGridView:    root.isGridView
                currentPage:   root.currentPage
                filteredApps:  root.filteredApps
                selectedIndex: root.selectedIndex

                onFilterRequested:      filterTimer.restart()
                onSelectedIndexChanged: (idx) => { root.selectedIndex = idx }
                onPageChangeRequested:  (delta) => {
                    var next = root.currentPage + delta
                    if (next >= 0 && next < root.totalPages) root.currentPage = next
                }
            }

            // ── Pagination dots (grid mode only) ──────────────────────────
            Row {
                id: dotsRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                // shouldShow is a pure binding on appModeActive + isGridView + totalPages.
                // Because _switchMode() sets all mode flags atomically in one JS call,
                // QML evaluates this binding exactly once after the call completes —
                // never seeing an intermediate all-false state that would cause a flash.
                readonly property bool shouldShow: root.appModeActive
                                                   && root.isGridView
                                                   && root.totalPages > 1

                // INSTANT LAYOUT REMOVAL FIX:
                // When switching to wallpaper/clipboard/emoji (appModeActive becomes false),
                // this instantly evaluates to false, stripping the dots from the layout
                // before the panel resizes. If we stay in app mode (e.g., switching grid to list),
                // it falls back to (opacity > 0) to allow a smooth visual fade-out.
                visible: root.appModeActive ? (opacity > 0) : false

                opacity: shouldShow ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

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
