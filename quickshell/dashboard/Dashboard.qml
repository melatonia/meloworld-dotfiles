import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    property var screenObj: null
    property int barHeight: 55
    property string animState: "closed"

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
    visible: animState !== "closed"

    Connections {
        target: SessionState
        function onDashboardVisibleChanged() {
            root.animState = SessionState.dashboardVisible ? "open" : "closing"
        }
    }

    HoverHandler { id: rootHover }
    Timer {
        interval: 3000
        running: root.animState === "open" && !rootHover.hovered
        onTriggered: SessionState.dashboardVisible = false
    }

    // ── DashCard ──────────────────────────────────────────────────────────────
    component DashCard: Rectangle {
        id: dashCard

        property int staggerMs: 0
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

        property real slide: -24
        property real fade: 0.0
        opacity: fade
        transform: Translate { x: dashCard.slide }

        function animIn() { slideIn.start(); fadeIn.start() }
        function animOut() { slideOut.start(); fadeOut.start() }

        NumberAnimation { id: slideIn;  target: dashCard; property: "slide"; to: 0;   duration: 260; easing.type: Easing.OutExpo }
        NumberAnimation { id: slideOut; target: dashCard; property: "slide"; to: -24; duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { id: fadeIn;   target: dashCard; property: "fade";  to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { id: fadeOut;  target: dashCard; property: "fade";  to: 0.0; duration: 160; easing.type: Easing.InCubic }

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
    Column {
        anchors.fill: parent
        spacing: root.cardGap

        // Top section with fixed heights
        Column {
            id: topCards
            width: parent.width
            spacing: root.cardGap

            DashCard {
                id: profileCard
                accent: PanelColors.profile; label: "meloworld"; staggerMs: 0
                width: parent.width
                // Account for top AND bottom margins:
                height: profileCard.header.implicitHeight + profileInner.implicitHeight + (root.cardPad * 2)
                ProfileSection { id: profileInner; width: parent.width }
            }

            DashCard {
                id: mediaCard
                accent: PanelColors.audio; label: "now playing"; staggerMs: 60
                width: parent.width
                // Account for top AND bottom margins:
                height: mediaCard.header.implicitHeight + mediaInner.implicitHeight + (root.cardPad * 2)
                visible: mediaInner.hasContent
                MediaPlayerSection { id: mediaInner; width: parent.width }
            }

            DashCard {
                id: statsCard
                accent: PanelColors.system; label: "system"; staggerMs: 120
                width: parent.width
                // Account for top AND bottom margins:
                height: statsCard.header.implicitHeight + statsInner.implicitHeight + (root.cardPad * 2)
                SystemStatsSection {
                    id: statsInner
                    anchors.left: parent.left
                    anchors.right: parent.right
                }
            }
        }

        // Bottom section: shrinks when empty, fills when content present
        DashCard {
            id: notifCard
            accent: PanelColors.network; label: "notifications"; staggerMs: 180
            width: parent.width
            height: {
                const base = notifCard.header.implicitHeight + (root.cardPad * 2)
                const maxH = root.height - topCards.height - root.cardGap
                return Math.min(base + notifInner.totalHeight + root.cardPad, maxH)
            }

            Behavior on height {
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
    }

    // ── Stagger Logic ────────────────────────────────────────────────────────
    readonly property var allCards: [profileCard, mediaCard, statsCard, notifCard]

    onAnimStateChanged: {
        if (animState === "open") {
            for (let i = 0; i < allCards.length; i++)
                staggerFactory.createObject(root, { card: allCards[i], delay: allCards[i].staggerMs })
        } else if (animState === "closing") {
            for (let i = 0; i < allCards.length; i++) allCards[i].animOut()
            closingTimer.restart()
        }
    }

    Timer { id: closingTimer; interval: 280; onTriggered: root.animState = "closed" }

    Component {
        id: staggerFactory
        Timer {
            property var card: null; property int delay: 0
            interval: delay; running: true; repeat: false
            onTriggered: { if (card) card.animIn(); destroy() }
        }
    }
}
