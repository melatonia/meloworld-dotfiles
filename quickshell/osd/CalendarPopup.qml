import QtQuick
import "../theme"

PopupBase {
    id: root
    implicitWidth:  240
    borderColor:    PanelColors.date
    clipContent:    false
    contentHeight:  contentCol.implicitHeight
    autoDismiss:    false  // user actively browses months; don't auto-close

    // ── State ─────────────────────────────────────
    property int _viewYear:  new Date().getFullYear()
    property int _viewMonth: new Date().getMonth()
    property int _selectedDay: -1

    // Tracks "today" — updated on open to stay accurate over long sessions.
    property int _todayDay:   new Date().getDate()
    property int _todayMonth: new Date().getMonth()
    property int _todayYear:  new Date().getFullYear()

    Connections {
        target: CalendarState
        function onVisibleChanged() {
            if (CalendarState.visible) {
                var now = new Date()
                root._todayDay   = now.getDate()
                root._todayMonth = now.getMonth()
                root._todayYear  = now.getFullYear()

                root._selectedDay = -1
                root._viewYear  = root._todayYear
                root._viewMonth = root._todayMonth
                root.animState  = "open"
            } else {
                root.animState = "closing"
            }
        }
    }

    function updateMonth(delta) {
        monthAnim.direction = delta
        monthAnim.restart()
    }

    SequentialAnimation {
        id: monthAnim
        property int direction: 0
        ParallelAnimation {
            NumberAnimation { target: dayGrid; property: "opacity"; to: 0; duration: 80; easing.type: Easing.OutCubic }
            NumberAnimation { target: gridTrans; property: "x"; to: monthAnim.direction > 0 ? -30 : 30; duration: 80; easing.type: Easing.OutCubic }
        }
        ScriptAction {
            script: {
                root._selectedDay = -1
                if (monthAnim.direction > 0) {
                    if (root._viewMonth === 11) { root._viewMonth = 0; root._viewYear++ }
                    else root._viewMonth++
                } else {
                    if (root._viewMonth === 0) { root._viewMonth = 11; root._viewYear-- }
                    else root._viewMonth--
                }
            }
        }
        PropertyAction { target: gridTrans; property: "x"; value: monthAnim.direction > 0 ? 30 : -30 }
        ParallelAnimation {
            NumberAnimation { target: dayGrid; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutExpo }
            NumberAnimation { target: gridTrans; property: "x"; to: 0; duration: 200; easing.type: Easing.OutExpo }
        }
    }

    function _monthName(m) {
        return ["January","February","March","April","May","June",
                "July","August","September","October","November","December"][m]
    }
    function _daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
    function _firstWeekday(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7 }

    // ── Content ───────────────────────────────────
    Column {
        id: contentCol
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
        spacing: 6

        // ── Month nav row ─────────────────────────
        Item {
            width: parent.width
            height: 28

            // Prev
            Rectangle {
                id: prevBtn
                width: 24; height: 24; radius: 5
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                color: prevArea.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                    color: prevArea.containsMouse ? PanelColors.textAccent : PanelColors.textDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: prevArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: root.updateMonth(-1)
                }
            }

            // Month + Year
            Text {
                anchors.centerIn: parent
                text: root._monthName(root._viewMonth) + " " + root._viewYear
                font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                color: PanelColors.textAccent
            }

            // Next
            Rectangle {
                id: nextBtn
                width: 24; height: 24; radius: 5
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                color: nextArea.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                    color: nextArea.containsMouse ? PanelColors.textAccent : PanelColors.textDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: nextArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: root.updateMonth(1)
                }
            }
        }

        // ── Day-of-week headers ───────────────────
        Row {
            width: parent.width
            Repeater {
                model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                delegate: Text {
                    width: contentCol.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: index >= 5 ? PanelColors.date : PanelColors.textDim
                }
            }
        }

        // ── Divider ───────────────────────────────
        Rectangle {
            width: parent.width; height: 2
            color: PanelColors.border
        }

        // ── Day grid ─────────────────────────────
        Column {
            id: dayGrid
            width: parent.width
            spacing: 2
            transform: Translate { id: gridTrans; x: 0 }

            Repeater {
                model: Math.ceil((_firstWeekday(root._viewYear, root._viewMonth)
                        + _daysInMonth(root._viewYear, root._viewMonth)) / 7)

                delegate: Rectangle {
                    required property int index
                    readonly property int weekIndex: index

                    readonly property bool isCurrentWeek: {
                        var todayTotal = root._todayDay + _firstWeekday(root._todayYear, root._todayMonth) - 1
                        return root._viewMonth === root._todayMonth
                            && root._viewYear  === root._todayYear
                            && Math.floor(todayTotal / 7) === weekIndex
                    }

                    width: parent.width
                    height: 28
                    radius: 6
                    color: isCurrentWeek ? PanelColors.rowBackground : "transparent"

                    // Left strip — only on current week
                    Rectangle {
                        visible: isCurrentWeek
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 0; verticalCenter: parent.verticalCenter }
                        color: PanelColors.date
                    }

                    Row {
                        anchors.fill: parent

                        Repeater {
                            model: 7
                            delegate: Item {
                                required property int index
                                readonly property int cellIndex: weekIndex * 7 + index
                                readonly property int dayNum:    cellIndex - _firstWeekday(root._viewYear, root._viewMonth) + 1
                                readonly property bool isEmpty:  dayNum < 1 || dayNum > _daysInMonth(root._viewYear, root._viewMonth)
                                readonly property bool isToday:  !isEmpty
                                                                && dayNum === root._todayDay
                                                                && root._viewMonth === root._todayMonth
                                                                && root._viewYear  === root._todayYear
                                readonly property bool isSelected: !isEmpty && dayNum === root._selectedDay

                                width:  contentCol.width / 7
                                height: parent.height

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 24; height: 24; radius: 6
                                    color: {
                                        if (isEmpty) return "transparent"
                                        let base = isToday ? PanelColors.date : (isSelected ? PanelColors.border : "transparent")
                                        if (dayArea.containsMouse) {
                                            let hoverRef = isToday ? PanelColors.date : (isSelected ? PanelColors.border : PanelColors.rowBackground)
                                            return Qt.lighter(hoverRef, 1.15)
                                        }
                                        return base
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: isEmpty ? "" : dayNum
                                        font.pixelSize: 13; font.bold: isToday || isSelected; font.family: "JetBrainsMono Nerd Font"
                                        color: isToday ? PanelColors.pillForeground : (isSelected ? PanelColors.textAccent : PanelColors.textMain)
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    id: dayArea
                                    anchors.fill: parent
                                    hoverEnabled: !isEmpty
                                    cursorShape: !isEmpty ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (!isEmpty) root._selectedDay = dayNum
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
