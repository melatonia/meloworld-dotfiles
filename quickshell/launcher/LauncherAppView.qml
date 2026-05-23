// LauncherAppView.qml
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
    property string searchText:   ""   // #5: set by AppLauncher to searchBar.text

    readonly property int itemsPerPage: isGridView ? 15 : 0

    readonly property alias appsRepeaterCount: _appsRepeater.count
    function appItemAt(i) { return _appsRepeater.itemAt(i) }

    signal appLaunched()

    // ── Navigation ────────────────────────────────────────────────────────
    function navigateGrid(colDelta, rowDelta) {
        if (root.filteredApps.length === 0) return
        var cols = root.isGridView ? 5 : 1
        var currentFidx = root.filteredApps.indexOf(root.selectedIndex)
        if (currentFidx === -1) currentFidx = 0
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
        if (root.selectedIndex === -1) return
        var item = _appsRepeater.itemAt(root.selectedIndex)
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

    // ── Sizing ────────────────────────────────────────────────────────────
    readonly property int rowH: 42   // #3: was 40

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

    // ── Right-click to open hidden menu ───────────────────────────────────
    MouseArea {
        anchors.fill:    parent
        z:               0
        acceptedButtons: Qt.RightButton
        onClicked:       root.openHiddenMenu()
    }

    // ── Grid view ─────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible:      root.isGridView

        MouseArea {
            anchors.fill: parent; z: 0
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                if (wheel.angleDelta.y < 0) {
                    if (root.currentPage < root.totalPages - 1) root.currentPage++
                } else {
                    if (root.currentPage > 0) root.currentPage--
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
                    font.pixelSize: 13; font.bold: true
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

            readonly property int  origIdx:    root.filteredApps[index] ?? -1
            readonly property var  appItem:    origIdx >= 0 ? _appsRepeater.itemAt(origIdx) : null
            readonly property bool isSelected: root.selectedIndex === origIdx

            width:   appListView.width
            height:  root.rowH
            visible: appItem !== null

            Rectangle {
                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                radius: 6
                color: listDelegate.isSelected
                           ? PanelColors.launcher
                           : rowHover.containsMouse
                               ? PanelColors.rowBackground
                               : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 12

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 22
                        source: listDelegate.appItem ? Quickshell.iconPath(listDelegate.appItem.appIcon) : ""
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:  listDelegate.appItem ? listDelegate.appItem.appName : ""
                        font.pixelSize: 16; font.bold: true
                        font.family:    "JetBrainsMono Nerd Font"
                        color: listDelegate.isSelected ? PanelColors.pillForeground : PanelColors.textMain
                        Behavior on color { ColorAnimation { duration: 120 } }
                        width: appListView.width - 14 - 22 - 12 - 12 - 8
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id:           rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onEntered:  { root.selectedIndex = listDelegate.origIdx }
                    onClicked:  { if (listDelegate.appItem) listDelegate.appItem.executeApp() }
                }
            }
        }

        // #5: Command fallback row — shown when search has text but no app matches
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
                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 22
                        source: "utilities-terminal"
                    }
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
                    id: fallbackHover
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
