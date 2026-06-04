import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../theme"
import "../dock"

Item {
    id: root

    // ── API ───────────────────────────────────────────────────────────────
    property bool   isGridView:   false
    property int    selectedIndex: -1
    property int    currentPage:  0
    property int    totalPages:   1
    property var    filteredApps: []
    property string searchText:   ""

    readonly property int itemsPerPage: isGridView ? 15 : 0

    readonly property alias appsRepeaterCount: _appsRepeater.count
    function appItemAt(i) { return _appsRepeater.itemAt(i) }

    signal appLaunched()
    signal pageChangeRequested(int delta)

    // ── Navigation ────────────────────────────────────────────────────────
    function navigateGrid(colDelta, rowDelta) {
        if (root.filteredApps.length === 0) return
        var cols = root.isGridView ? 5 : 1
        var currentFidx = root.filteredApps.indexOf(root.selectedIndex)
        if (currentFidx === -1) {
            root.selectedIndex = root.filteredApps[0]
            return
        }
        var delta = root.isGridView ? (colDelta + rowDelta * cols) : (colDelta + rowDelta)
        var nextFidx = Math.max(0, Math.min(currentFidx + delta, root.filteredApps.length - 1))
        if (nextFidx === currentFidx) return
        root.selectedIndex = root.filteredApps[nextFidx]
        if (root.isGridView) {
            var newPage = Math.floor(nextFidx / root.itemsPerPage)
            if (newPage !== root.currentPage) root.currentPage = newPage
        } else {
            appListView.positionViewAtIndex(nextFidx, ListView.Contain)
        }
    }

    function confirmSelection() {
        var fidx = root.filteredApps.indexOf(root.selectedIndex)
        var targetIdx = (fidx === -1)
            ? (root.filteredApps.length > 0 ? root.filteredApps[0] : -1)
            : root.selectedIndex
        if (targetIdx < 0) return
        var item = _appsRepeater.itemAt(targetIdx)
        if (item) item.executeApp()
    }

    // ── Hidden menu API ───────────────────────────────────────────────────
    property bool _hiddenMenuOpen: false

    function openHiddenMenu() {
        if (_hiddenMenuOpen) { closeHiddenMenu(); return }
        _hiddenMenuOpen         = true
        hiddenMenuInner.y       = 14
        hiddenMenuInner.opacity = 0.0
        hiddenMenuPopup.visible = true
        hiddenOpenAnim.restart()
        hiddenDismissTimer.restart()
    }
    function closeHiddenMenu() {
        if (!_hiddenMenuOpen) return
        _hiddenMenuOpen = false
        hiddenOpenAnim.stop()
        hiddenCloseAnim.restart()
    }

    // ── Context menu tracker ──────────────────────────────────────────────
    property int openMenuDelegateIndex: -1

    function notifyMenuOpened(idx) {
        openMenuDelegateIndex = idx
    }

    // ── Sizing ────────────────────────────────────────────────────────────
    readonly property int rowH: 42

    // ── Hidden-apps dismiss timer ─────────────────────────────────────────
    Timer {
        id: hiddenDismissTimer
        interval: 3000
        running:  root._hiddenMenuOpen
        onTriggered: root.closeHiddenMenu()
    }

    Connections {
        target: LauncherState
        function onVisibleChanged() {
            if (!LauncherState.visible && root._hiddenMenuOpen)
                root.closeHiddenMenu()
        }
    }

    // ── Hidden-apps popup ─────────────────────────────────────────────────
    PopupWindow {
        id: hiddenMenuPopup

        anchor.item:           root
        anchor.edges:          Edges.Top
        anchor.gravity:        Edges.Top
        anchor.margins.bottom: 8

        color:          "transparent"
        implicitWidth:  220
        implicitHeight: hiddenMenuInner.implicitHeight
        visible:        false

        SequentialAnimation {
            id: hiddenOpenAnim
            ParallelAnimation {
                NumberAnimation { target: hiddenMenuInner; property: "y";       to: 0;   duration: 220; easing.type: Easing.OutExpo  }
                NumberAnimation { target: hiddenMenuInner; property: "opacity"; to: 1.0; duration: 170; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            id: hiddenCloseAnim
            ParallelAnimation {
                NumberAnimation { target: hiddenMenuInner; property: "y";       to: 14;  duration: 160; easing.type: Easing.InCubic }
                NumberAnimation { target: hiddenMenuInner; property: "opacity"; to: 0.0; duration: 130; easing.type: Easing.InCubic }
            }
            ScriptAction { script: hiddenMenuPopup.visible = false }
        }

        mask: Region { item: hiddenMenuInner }

        Rectangle {
            id: hiddenMenuInner
            width:          parent.width
            implicitHeight: hiddenMenuCol.implicitHeight + 24
            height:         implicitHeight
            radius:         10
            color:          PanelColors.popupBackground
            border.color:   PanelColors.border
            border.width:   2
            clip:           true
            Behavior on color        { ColorAnimation { duration: PanelColors.transitionDuration } }
            Behavior on border.color { ColorAnimation { duration: PanelColors.transitionDuration } }

            HoverHandler { onHoveredChanged: { if (hovered) hiddenDismissTimer.restart() } }

            Column {
                id: hiddenMenuCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
                spacing: 4

                Text {
                    width: parent.width; text: "Hidden Apps"
                    font.pixelSize: 13; font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim; bottomPadding: 4
                }
                Rectangle { width: parent.width; height: 2; color: PanelColors.border }
                Text {
                    width: parent.width; text: "No hidden apps"
                    font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                    visible: LauncherHiddenApps.hiddenApps.length === 0
                    topPadding: 4; bottomPadding: 4
                    horizontalAlignment: Text.AlignHCenter
                }
                Repeater {
                    model: LauncherHiddenApps.hiddenApps
                    delegate: Item {
                        required property var modelData
                        width: hiddenMenuCol.width; height: 34
                        Rectangle {
                            anchors.fill: parent; radius: 6
                            color: hRow.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Rectangle {
                                width: 3; height: parent.height - 10; radius: 2
                                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                color: PanelColors.textDim
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                text: modelData.name; font.pixelSize: 13; font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                                color: PanelColors.textMain; elide: Text.ElideRight
                            }
                            MouseArea {
                                id: hRow; anchors.fill: parent; hoverEnabled: true
                                onContainsMouseChanged: { if (containsMouse) hiddenDismissTimer.restart() }
                                onClicked: { LauncherHiddenApps.show(modelData.id); root.closeHiddenMenu() }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Grid view ─────────────────────────────────────────────────────────
    Item {
        id: gridContainer
        anchors.fill: parent
        visible:      root.isGridView

        // Wheel handler at item level — sits above app icons so it always fires
        WheelHandler {
            id:               gridWheelHandler
            acceptedDevices:  PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                if (event.angleDelta.y < 0) {
                    root.pageChangeRequested(+1)
                } else {
                    root.pageChangeRequested(-1)
                }
            }
        }

        Repeater {
            id: _appsRepeater
            model: DesktopEntries.applications
            onCountChanged: filterRequested()

            delegate: AppLauncherIcon {
                appId:                modelData.id
                appName:              modelData.name
                appIcon:              modelData.icon
                appData:              modelData
                delegateIndex:        index
                launcherItemsPerPage: root.itemsPerPage
                launcherCurrentPage:  root.currentPage
                launcherSelectedIdx:  root.selectedIndex
                launcherIsGridView:   root.isGridView
                launcherView:         root
                launcherOpenMenuIdx:  root.openMenuDelegateIndex
            }
        }

        // Command fallback — grid
        Rectangle {
            visible: root.filteredApps.length === 0 && root.searchText.trim() !== ""
            x: 4; y: 4; width: 136; height: 132; radius: 12
            color: Qt.rgba(1, 1, 1, 0.08)
            Column {
                anchors.centerIn: parent; spacing: 8
                IconImage { anchors.horizontalCenter: parent.horizontalCenter; implicitSize: 64; source: "utilities-terminal" }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Run: " + root.searchText
                    font.pixelSize: 14; font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textMain; width: 120
                    horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                }
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: { Quickshell.execDetached(["bash", "-c", root.searchText]); LauncherState.hide() }
            }
        }
    }

    // ── List view ─────────────────────────────────────────────────────────
    ListView {
        id:           appListView
        anchors.fill: parent
        clip:         true
        spacing:      2
        visible:      !root.isGridView

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        model: root.filteredApps.length

        delegate: Item {
            id:   listDelegate
            required property int index

            readonly property int origIdx: root.filteredApps[index] ?? -1

            // ── Core fix ──────────────────────────────────────────────────
            // .values[i] is the reactive ObjectModel accessor — updates its
            // binding on any model change, unlike bracket indexing or
            // _appsRepeater.itemAt() which both go null during model resets.
            readonly property var  entry:      origIdx >= 0 ? DesktopEntries.applications.values[origIdx] : null

            // The grid icon is always live: gridContainer uses visible:false,
            // not a Loader, so Qt never destroys its children. We use it as
            // the authority for all action logic (launch, GPU, pin, hide)
            // since it has already parsed execName, resolvedSteamId, etc.
            // Display data (name, icon) comes from entry directly — that is
            // what was going null and causing the blank rows.
            readonly property var  gridIcon:   origIdx >= 0 ? _appsRepeater.itemAt(origIdx) : null
            readonly property bool isSelected: root.selectedIndex === origIdx

            width:   appListView.width
            height:  root.rowH
            // Guard on entry (DesktopEntry from ObjectModel) — this never
            // goes null due to Repeater churn, so rows never disappear.
            visible: entry !== null

            Rectangle {
                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                radius: 6
                color: listDelegate.isSelected
                           ? PanelColors.launcher
                           : listRowHover.containsMouse
                               ? PanelColors.rowBackground
                               : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 12

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 22
                        // entry.icon is stable — from ObjectModel, never null
                        source: listDelegate.entry ? Quickshell.iconPath(listDelegate.entry.icon) : ""
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:  listDelegate.entry ? listDelegate.entry.name : ""
                        font.pixelSize: 17
                        font.bold: true
                        font.family:    "JetBrainsMono Nerd Font"
                        color: listDelegate.isSelected ? PanelColors.pillForeground : PanelColors.textMain
                        Behavior on color { ColorAnimation { duration: 120 } }
                        width: appListView.width - 14 - 22 - 12 - 12 - 8
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id:              listRowHover
                    anchors.fill:    parent
                    hoverEnabled:    true
                    cursorShape:     Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onEntered:  { root.selectedIndex = listDelegate.origIdx }
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            if (listCtxMenu.isOpen) listCtxMenu.closeMenu()
                            else                    listCtxMenu.openMenu()
                        } else {
                            // Proxy to executeApp() so terminal/Steam/GPU
                            // launch logic and AppUsageTracker stay in one place
                            if (listDelegate.gridIcon) listDelegate.gridIcon.executeApp()
                        }
                    }
                }
            }

            // ── Context menu popup for list rows ──────────────────────────
            PopupWindow {
                id: listCtxMenu

                anchor.item:           listDelegate
                anchor.edges:          Edges.Top
                anchor.gravity:        Edges.Top
                anchor.margins.bottom: 4

                color:          "transparent"
                implicitWidth:  200
                implicitHeight: listCtxInner.implicitHeight
                visible:        false

                property bool isOpen: false

                Connections {
                    target: root
                    function onOpenMenuDelegateIndexChanged() {
                        if (root.openMenuDelegateIndex !== listDelegate.origIdx && listCtxMenu.isOpen)
                            listCtxMenu.closeMenu()
                    }
                }

                function openMenu() {
                    if (!listDelegate.gridIcon) return
                    root.notifyMenuOpened(listDelegate.origIdx)
                    // _buildMenuModel() lives in AppLauncherIcon and already
                    // handles Steam, GPU, and pin/unpin correctly
                    listCtxRepeater.model = listDelegate.gridIcon._buildMenuModel()
                    listCtxInner.y        = 14
                    listCtxInner.opacity  = 0.0
                    visible               = true
                    isOpen                = true
                    listCtxOpenAnim.restart()
                    listCtxDismiss.restart()
                }
                function closeMenu() {
                    if (!isOpen) return
                    isOpen = false
                    listCtxOpenAnim.stop()
                    listCtxCloseAnim.restart()
                }

                Timer {
                    id:          listCtxDismiss
                    interval:    3000
                    running:     listCtxMenu.isOpen
                    onTriggered: listCtxMenu.closeMenu()
                }

                SequentialAnimation {
                    id: listCtxOpenAnim
                    ParallelAnimation {
                        NumberAnimation { target: listCtxInner; property: "y";       to: 0;   duration: 220; easing.type: Easing.OutExpo  }
                        NumberAnimation { target: listCtxInner; property: "opacity"; to: 1.0; duration: 170; easing.type: Easing.OutCubic }
                    }
                }
                SequentialAnimation {
                    id: listCtxCloseAnim
                    ParallelAnimation {
                        NumberAnimation { target: listCtxInner; property: "y";       to: 14;  duration: 160; easing.type: Easing.InCubic }
                        NumberAnimation { target: listCtxInner; property: "opacity"; to: 0.0; duration: 130; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: listCtxMenu.visible = false }
                }

                mask: Region { item: listCtxInner }

                Rectangle {
                    id: listCtxInner
                    width:          parent.width
                    implicitHeight: listCtxCol.implicitHeight + padding * 2
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
                        onHoveredChanged: { if (hovered) listCtxDismiss.restart() }
                    }

                    Column {
                        id: listCtxCol
                        anchors {
                            top:     parent.top
                            left:    parent.left
                            right:   parent.right
                            margins: listCtxInner.padding
                        }
                        spacing: 4

                        Text {
                            width:          parent.width
                            text:           listDelegate.entry ? listDelegate.entry.name : ""
                            font.pixelSize: 12
                            font.bold: true
                            font.family:    "JetBrainsMono Nerd Font"
                            color:          PanelColors.textDim
                            bottomPadding:  4
                            elide:          Text.ElideRight
                        }

                        Rectangle { width: parent.width; height: 2; color: PanelColors.border }

                        Repeater {
                            id: listCtxRepeater
                            model: []

                            delegate: Item {
                                required property var modelData
                                width:  listCtxCol.width
                                height: 34

                                Rectangle {
                                    anchors.fill: parent
                                    radius:       6
                                    color: listCtxRowMouse.containsMouse
                                        ? Qt.lighter(PanelColors.rowBackground, 1.15)
                                        : PanelColors.rowBackground
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Rectangle {
                                        width: 3; height: parent.height - 10; radius: 2
                                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                        color: PanelColors.textDim
                                    }

                                    Text {
                                        anchors {
                                            left: parent.left; leftMargin: 14
                                            right: parent.right; rightMargin: 10
                                            verticalCenter: parent.verticalCenter
                                        }
                                        text:           modelData.label
                                        font.pixelSize: 13; font.bold: true
                                        font.family:    "JetBrainsMono Nerd Font"
                                        color:          PanelColors.textMain
                                        elide:          Text.ElideRight
                                    }

                                    MouseArea {
                                        id:           listCtxRowMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onContainsMouseChanged: { if (containsMouse) listCtxDismiss.restart() }
                                        onClicked: {
                                            listCtxMenu.closeMenu()
                                            // All action logic proxied to gridIcon — it owns
                                            // execName, resolvedSteamId, isTerminal, GPU index,
                                            // AppUsageTracker, and the correct PinnedApps call
                                            // signature with execName and resolvedSteamId.
                                            var icon = listDelegate.gridIcon
                                            if (!icon) return
                                            var action = modelData.action
                                            if (action === "launch") {
                                                icon._launchDefault()
                                            } else if (action === "gpu") {
                                                icon._launchOnGpu(modelData.gpuIndex)
                                            } else if (action === "pin") {
                                                PinnedApps.pinApp(icon.appId, icon.appName, icon.appIcon, icon.execName, icon.resolvedSteamId)
                                            } else if (action === "unpin") {
                                                PinnedApps.unpinApp(icon.appId)
                                            } else if (action === "hide") {
                                                LauncherHiddenApps.hide(icon.appId, icon.appName, icon.appIcon)
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

        footer: Item {
            width:   appListView.width
            height:  root.filteredApps.length === 0 && root.searchText.trim() !== "" ? root.rowH : 0
            visible: height > 0

            Rectangle {
                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                radius: 6
                color: fallbackHover.containsMouse ? PanelColors.rowBackground : Qt.rgba(1, 1, 1, 0.08)
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 12
                    IconImage { anchors.verticalCenter: parent.verticalCenter; implicitSize: 22; source: "utilities-terminal" }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Run: " + root.searchText
                        font.pixelSize: 16; font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textMain
                        width: appListView.width - 14 - 22 - 12 - 12 - 8
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id:           fallbackHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", root.searchText])
                        LauncherState.hide()
                    }
                }
            }
        }
    }

    // ── Filter request signal ─────────────────────────────────────────────
    signal filterRequested()
}
