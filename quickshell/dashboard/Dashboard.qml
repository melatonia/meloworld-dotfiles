import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    property var screenObj: null
    readonly property int stateClosed: 0
    readonly property int stateOpen: 1
    readonly property int stateClosing: 2
    property int animState: stateClosed

    // Best Practice: Standardized spacing values
    readonly property int cardGap: 10
    readonly property int cardPad: 14

    screen: screenObj
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    color: "transparent"

    // External margins from the screen edge
    margins.top: cardGap
    margins.left: cardGap
    margins.bottom: cardGap

    implicitWidth: 290
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: animState !== stateClosed

    Connections {
        target: SessionState
        function onDashboardVisibleChanged() {
            root.animState = SessionState.dashboardVisible ? stateOpen : stateClosing
        }
    }

    HoverHandler { id: rootHover }
    Timer {
        interval: 3000
        running: root.animState === stateOpen && !rootHover.hovered
        onTriggered: SessionState.dashboardVisible = false
    }

    // ── DashCard ──────────────────────────────────────────────────────────────
    component DashCard: Rectangle {
        id: dashCard

        property color accent: PanelColors.launcher
        property string label: ""
        property alias header: cardHeader
        // Optional extra item injected into the header row (e.g. "clear all" button)
        property alias headerExtra: headerExtraSlot.data

        radius: 10
        color: PanelColors.popupBackground
        border.color: accent
        border.width: 2
        clip: true

        opacity: 0.0
        transform: Translate { id: dashCardTranslate; x: -24 }

        state: "closed"

        states: [
            State {
                name: "open"
                PropertyChanges { target: dashCard; opacity: 1.0 }
                PropertyChanges { target: dashCardTranslate; x: 0 }
            },
            State {
                name: "closed"
                PropertyChanges { target: dashCard; opacity: 0.0 }
                PropertyChanges { target: dashCardTranslate; x: -24 }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                ParallelAnimation {
                    NumberAnimation { target: dashCardTranslate; property: "x"; duration: 260; easing.type: Easing.OutExpo }
                    NumberAnimation { target: dashCard; property: "opacity"; duration: 200; easing.type: Easing.OutCubic }
                }
            },
            Transition {
                to: "closed"
                ParallelAnimation {
                    NumberAnimation { target: dashCardTranslate; property: "x"; duration: 200; easing.type: Easing.InCubic }
                    NumberAnimation { target: dashCard; property: "opacity"; duration: 160; easing.type: Easing.InCubic }
                }
            }
        ]

        default property alias content: inner.data

        // Left accent stripe
        Rectangle {
            width: 4; height: parent.height - 24; radius: 2
            anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
            color: dashCard.accent; opacity: 0.85
        }

        // Header: label + divider
        Column {
            id: cardHeader
            anchors {
                top: parent.top; topMargin: root.cardPad
                left: parent.left; leftMargin: 20
                right: parent.right; rightMargin: 16
            }
            spacing: 0

            Row {
                width: parent.width
                Text {
                    text: dashCard.label
                    font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: dashCard.accent
                    width: parent.width - headerExtraSlot.implicitWidth
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    id: headerExtraSlot
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Item { width: 1; height: 6 }
            Rectangle { width: parent.width; height: 2; color: PanelColors.rowBackground; opacity: 0.6 }
            Item { width: 1; height: 10 }
        }

        // Content slot
        Item {
            id: inner
            anchors {
                top: cardHeader.bottom
                bottom: parent.bottom; bottomMargin: root.cardPad
                left: parent.left; leftMargin: 20
                right: parent.right; rightMargin: 16
            }
        }
    }

    // ── Unified Layout ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: root.cardGap

        DashCard {
            id: profileCard
            accent: PanelColors.profile; label: "meloworld"
            Layout.fillWidth: true
            implicitHeight: profileCard.header.implicitHeight + profileInner.implicitHeight + (root.cardPad * 2)
            ProfileSection { id: profileInner; width: parent.width }
        }

        DashCard {
            id: togglesCard
            accent: PanelColors.audio; label: "quick settings"
            Layout.fillWidth: true
            implicitHeight: togglesCard.header.implicitHeight + togglesInner.implicitHeight + (root.cardPad * 2)
            QuickTogglesSection {
                id: togglesInner
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        DashCard {
            id: statsCard
            accent: PanelColors.system; label: "system"
            Layout.fillWidth: true
            implicitHeight: statsCard.header.implicitHeight + statsInner.implicitHeight + (root.cardPad * 2)
            SystemStatsSection {
                id: statsInner
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        DashCard {
            id: notifCard
            accent: PanelColors.network; label: "notifications"
            Layout.fillWidth: true
            Layout.preferredHeight: {
                const base = notifCard.header.implicitHeight + (root.cardPad * 2)
                const maxH = root.height - profileCard.implicitHeight - togglesCard.implicitHeight - statsCard.implicitHeight - (root.cardGap * 3)
                return Math.min(base + notifInner.totalHeight + root.cardPad, maxH)
            }

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 220; easing.type: Easing.OutExpo }
            }

            headerExtra: Text {
                text: "clear all"
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                color: clearAllMouse.containsMouse ? PanelColors.error : PanelColors.textDim
                visible: NotificationState.history.count > 0
                MouseArea {
                    id: clearAllMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationState.clearHistory()
                }
            }

            NotificationSection { id: notifInner }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    // ── Stagger Logic ────────────────────────────────────────────────────────
    SequentialAnimation {
        id: openAnim
        ScriptAction { script: profileCard.state = "open" }
        PauseAnimation { duration: 60 }
        ScriptAction { script: togglesCard.state = "open" }
        PauseAnimation { duration: 60 }
        ScriptAction { script: statsCard.state = "open" }
        PauseAnimation { duration: 60 }
        ScriptAction { script: notifCard.state = "open" }
    }

    SequentialAnimation {
        id: closeAnim
        ScriptAction {
            script: {
                profileCard.state = "closed"
                togglesCard.state = "closed"
                statsCard.state = "closed"
                notifCard.state = "closed"
            }
        }
        PauseAnimation { duration: 280 }
        ScriptAction { script: root.animState = stateClosed }
    }

    onAnimStateChanged: {
        if (animState === stateOpen) {
            closeAnim.stop()
            openAnim.start()
        } else if (animState === stateClosing) {
            openAnim.stop()
            closeAnim.start()
        }
    }
}
