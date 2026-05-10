import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: root
    required property Notification notification

    // ─── Public constants ────────────────────────────────────────────────────
    readonly property int cardWidth:          400
    readonly property int dismissMs:          4000
    readonly property int collapsedBodyLines: 3

    readonly property int enterDuration:    460
    readonly property int exitDuration:     340
    readonly property int expandDuration:   220
    readonly property int textFadeDuration: 300

    // ─── State ──────────────────────────────────────────────────────────────
    property bool expanded:      false
    property bool isExiting:     false
    property bool dismissing:    false
    property var  pendingAction: null

    // ─── Sizing ─────────────────────────────────────────────────────────────
    width:          cardWidth
    implicitHeight: cardRect.height
    visible:        notification !== null

    // ─── Accent colour ──────────────────────────────────────────────────────
    readonly property color accentColor: {
        if (!notification)                                   return Colors.blueGrey300
        if (notification.urgency === Notification.Critical)  return PanelColors.error
        if (notification.hints["x-hint-color"])              return notification.hints["x-hint-color"]
        return hashColor(notification.appName)
    }

    function hashColor(str) {
        if (!str || str === "") return Colors.blueGrey300
        var hash = 0
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }
        var palette = [
            Colors.teal200,    Colors.lightBlue200, Colors.green200,
            Colors.purple200,  Colors.orange200,    Colors.pink200,
            Colors.yellow200,  Colors.cyan200,      Colors.deepPurple200,
            Colors.blueGrey300,
        ]
        return palette[Math.abs(hash) % palette.length]
    }

    readonly property bool bodyIsLong: {
        if (!notification) return false
        var body = notification.body ?? ""
        if (body === "") return false
        return body.length > 120 || body.split("\n").length > 3
    }

    // ─── Dismiss / expire helpers ────────────────────────────────────────────
    function pauseDismiss() {
        dismissTimer.stop()
        ringTimer.stop()
        hoverPauseAnim.start()
    }

    function resumeDismiss() {
        hoverPauseAnim.stop()
        ringFadeInAnim.start()
        timerItem.startTime   = Date.now() - (1.0 - timerRing.progress) * root.dismissMs
        dismissTimer.interval = Math.max(50, timerRing.progress * root.dismissMs)
        dismissTimer.restart()
        ringTimer.start()
    }

    function dismiss() {
        if (root.dismissing) return
        root.dismissing = true
        dismissTimer.stop()
        ringTimer.running = false
        exitAnim.start()
    }

    function expire() {
        if (root.dismissing) return
        root.dismissing = true
        dismissTimer.stop()
        ringTimer.running = false
        exitAnim.start()
    }

    function invokeAction(action) {
        if (root.dismissing) return
        root.dismissing = true
        dismissTimer.stop()
        ringTimer.running = false
        root.pendingAction = action
        exitAnim.start()
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────
    Component.onCompleted: {
        cardRect.x       = cardWidth + 40
        cardRect.opacity = 0
        enterAnim.start()
        dismissTimer.start()
        timerItem.startTime = Date.now()
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CARD VISUAL
    // ═══════════════════════════════════════════════════════════════════════
    Rectangle {
        id:    cardRect
        width: root.cardWidth

        // ── Height ────────────────────────────────────────────────────────
        // Live binding — always correct. bodyTextContainer has its own
        // matching Behavior so both animate together at the same duration
        // and easing, staying perfectly in sync with no double-animation.
        height: cardContent.implicitHeight + 28 + (expandButton.visible ? 36 : 0)

        Behavior on height {
            NumberAnimation { duration: root.expandDuration; easing.type: Easing.OutQuart }
        }

        x:             0
        opacity:       1
        radius:        10
        color:         PanelColors.popupBackground
        border.color:  root.accentColor
        border.width:  2
        clip:          true
        layer.enabled: true

        // ─── Enter ────────────────────────────────────────────────────────
        ParallelAnimation {
            id: enterAnim
            NumberAnimation {
                target: cardRect; property: "opacity"
                from: 0; to: 1
                duration: root.enterDuration * 0.85; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: cardRect; property: "x"
                from: root.cardWidth + 40; to: 0
                duration: root.enterDuration; easing.type: Easing.OutExpo
            }
        }

        // ─── Exit ─────────────────────────────────────────────────────────
        SequentialAnimation {
            id: exitAnim
            ParallelAnimation {
                NumberAnimation {
                    target: cardRect; property: "x"
                    to: root.cardWidth + 24
                    duration: root.exitDuration; easing.type: Easing.InExpo
                }
                NumberAnimation {
                    target: cardRect; property: "opacity"; to: 0
                    duration: root.exitDuration * 0.75; easing.type: Easing.InCubic
                }
            }
            ScriptAction   { script: { root.isExiting = true } }
            PauseAnimation { duration: 60 }
            ScriptAction   {
                script: {
                    if (root.pendingAction) {
                        root.pendingAction.invoke()
                        root.pendingAction = null
                    } else {
                        notification.dismiss()
                    }
                }
            }
        }

        // ─── Left accent strip ────────────────────────────────────────────
        Rectangle {
            width:  4
            height: parent.height - 24
            radius: 2
            anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
            color:   root.accentColor
            opacity: 0.9
        }

        // ─── Hover-only overlay ───────────────────────────────────────────
        // acceptedButtons: Qt.NoButton means this MouseArea NEVER intercepts
        // any click — it exists purely to track containsMouse over the full
        // card so pauseDismiss / resumeDismiss work everywhere including over
        // body text. All child MouseAreas receive clicks unobstructed.
        MouseArea {
            id:              hoverOverlay
            anchors.fill:    parent
            hoverEnabled:    true
            acceptedButtons: Qt.NoButton
            onEntered:       root.pauseDismiss()
            onExited:        root.resumeDismiss()
        }

        // ─── Card content ─────────────────────────────────────────────────
        Column {
            id: cardContent
            anchors {
                top: parent.top; topMargin: 14
                left: parent.left; leftMargin: 24
                right: parent.right; rightMargin: 16
            }
            spacing: 0

            // ── Header (clicking here dismisses) ──────────────────────────
            Item {
                width:  parent.width
                height: 22

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.dismiss()
                }

                Row {
                    anchors.fill: parent
                    spacing:      8

                    Image {
                        id:      appIconImg
                        visible: (notification?.appIcon ?? "") !== "" && status === Image.Ready
                        source:  visible ? "image://icon/" + notification.appIcon : ""
                        width:   18; height: 18
                        anchors.verticalCenter: parent.verticalCenter
                        fillMode: Image.PreserveAspectFit
                        smooth:   true
                    }

                    Text {
                        text:           notification?.appName ?? ""
                        font.pixelSize: 13
                        font.bold:      true
                        font.family:    "JetBrainsMono Nerd Font"
                        color:          root.accentColor
                        elide:          Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                              - timerItem.width
                              - (appIconImg.visible ? appIconImg.width + parent.spacing : 0)
                              - parent.spacing
                    }

                    Item {
                        id:     timerItem
                        width:  32; height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        property real startTime: Date.now()

                        Canvas {
                            id:            timerRing
                            width:         22; height: 22
                            anchors.right: parent.right
                            property real progress: 1.0
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.strokeStyle = root.accentColor
                                ctx.lineWidth   = 2
                                ctx.lineCap     = "round"
                                ctx.beginPath()
                                ctx.arc(11, 11, 8,
                                    -Math.PI / 2,
                                    -Math.PI / 2 + 2 * Math.PI * progress, false)
                                ctx.stroke()
                            }
                            onProgressChanged: requestPaint()
                        }

                        Timer {
                            id: ringTimer; interval: 50; running: true; repeat: true
                            onTriggered: {
                                timerRing.progress = Math.max(0,
                                    (root.dismissMs - (Date.now() - timerItem.startTime))
                                    / root.dismissMs)
                            }
                        }
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────────
            Rectangle {
                width: parent.width; height: 1
                color: PanelColors.rowBackground; opacity: 0.6
            }

            Item { width: 1; height: 8 }

            // ── Body row ─────────────────────────────────────────────────
            Row {
                width: parent.width; spacing: 10

                Column {
                    width:   notifImageFrame.visible
                             ? parent.width - notifImageFrame.width - parent.spacing
                             : parent.width
                    spacing: 4

                    // Summary — clicking dismisses
                    Text {
                        visible:          (notification?.summary ?? "") !== ""
                        text:             notification?.summary ?? ""
                        font.pixelSize:   18
                        font.bold:        true
                        font.family:      "JetBrainsMono Nerd Font"
                        color:            PanelColors.textAccent
                        width:            parent.width
                        wrapMode:         Text.WordWrap
                        maximumLineCount: 2
                        elide:            Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.dismiss()
                        }
                    }

                    // ── Body text container ───────────────────────────────
                    Item {
                        id:      bodyTextContainer
                        visible: (notification?.body ?? "") !== ""
                        width:   parent.width
                        clip:    true

                        readonly property real collapsedH: collapsedText.implicitHeight
                        readonly property real expandedH:  expandedText.implicitHeight

                        height: root.expanded ? expandedH : collapsedH

                        // Same duration + easing as cardRect so they move together
                        Behavior on height {
                            NumberAnimation { duration: root.expandDuration; easing.type: Easing.OutQuart }
                        }

                        // Collapsed (capped lines)
                        Text {
                            id:               collapsedText
                            text:             notification?.body ?? ""
                            font.pixelSize:   14
                            font.family:      "JetBrainsMono Nerd Font"
                            color:            PanelColors.textMain
                            width:            parent.width
                            wrapMode:         Text.WordWrap
                            maximumLineCount: root.collapsedBodyLines
                            elide:            Text.ElideRight
                            textFormat:       Text.PlainText
                            opacity:          root.expanded ? 0 : 1
                            Behavior on opacity {
                                NumberAnimation { duration: root.textFadeDuration; easing.type: Easing.InOutCubic }
                            }
                        }

                        // Expanded (full, overlaid)
                        Text {
                            id:             expandedText
                            text:           notification?.body ?? ""
                            font.pixelSize: 14
                            font.family:    "JetBrainsMono Nerd Font"
                            color:          PanelColors.textMain
                            width:          parent.width
                            wrapMode:       Text.WordWrap
                            textFormat:     Text.PlainText
                            opacity:        root.expanded ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: root.textFadeDuration; easing.type: Easing.InOutCubic }
                            }
                        }

                        // Clicking body text dismisses
                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.dismiss()
                        }
                    }
                }

                // Thumbnail
                Rectangle {
                    id:           notifImageFrame
                    visible:      (notification?.image ?? "") !== "" && notifImageInner.status === Image.Ready
                    width:        visible ? 60 : 0
                    height:       60
                    radius:       8
                    color:        "transparent"
                    border.color: root.accentColor
                    border.width: 3
                    clip:         true

                    Image {
                        id:           notifImageInner
                        anchors.fill: parent; anchors.margins: 3
                        fillMode:     Image.PreserveAspectCrop
                        source:       notification?.image ?? ""
                        smooth:       true
                    }
                }
            }

            Item {
                width:  1
                height: actionArea.visible ? 10 : 0
            }

            // ── Action buttons ────────────────────────────────────────────
            Item {
                id:      actionArea
                visible: (notification?.actions?.length ?? 0) > 0
                width:   parent.width
                height:  visible ? actionsRow.implicitHeight + 12 : 0

                Rectangle {
                    width: parent.width; height: 1
                    color: root.accentColor; opacity: 0.25
                    anchors.top: parent.top
                }

                Row {
                    id: actionsRow
                    anchors {
                        top: parent.top; topMargin: 12
                        left: parent.left; right: parent.right
                    }
                    spacing: 8

                    Repeater {
                        model: notification?.actions ?? []

                        Rectangle {
                            required property var modelData
                            height: 30
                            width:  actionLabel.implicitWidth + 24
                            radius: 6
                            color:  Qt.lighter(root.accentColor, actionMouse.containsMouse ? 1.15 : 1.0)
                            scale:  actionMouse.containsMouse ? 1.03 : 1.0
                            Behavior on color { ColorAnimation  { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

                            Text {
                                id:               actionLabel
                                text:             modelData.text
                                font.pixelSize:   13
                                font.bold:        true
                                font.family:      "JetBrainsMono Nerd Font"
                                color:            PanelColors.popupBackground
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id:           actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    root.invokeAction(modelData)
                            }
                        }
                    }
                }
            }

        } // Column cardContent

        // ── Expand / collapse button — pinned to bottom, outside Column ───
        Item {
            id:      expandButton
            visible: root.bodyIsLong
            width:   parent.width
            height:  36
            anchors.bottom: parent.bottom

            Rectangle {
                width: parent.width; height: 1
                color: PanelColors.rowBackground; opacity: 0.6
                anchors.top: parent.top
            }

            Row {
                anchors.centerIn: parent
                spacing:          6

                Text {
                    text:           root.expanded ? "󰅃" : "󰅀"
                    font.pixelSize: 17
                    font.family:    "JetBrainsMono Nerd Font"
                    color:          root.accentColor
                    opacity:        expandButtonMouse.containsMouse ? 1.0 : 0.65
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Text {
                    text:           root.expanded ? "Collapse" : "Show more"
                    font.pixelSize: 15
                    font.bold:      true
                    font.family:    "JetBrainsMono Nerd Font"
                    color:          root.accentColor
                    opacity:        expandButtonMouse.containsMouse ? 1.0 : 0.65
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
            }

            MouseArea {
                id:           expandButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.expanded = !root.expanded
            }
        }

    } // Rectangle cardRect

    // ─── Animations ───────────────────────────────────────────────────────────
    SequentialAnimation {
        id: hoverPauseAnim
        NumberAnimation { target: timerRing; property: "progress"; to: 1.0; duration: 200 }
        PauseAnimation  { duration: 100 }
        NumberAnimation { target: timerRing; property: "opacity"; to: 0.0; duration: 200 }
    }

    NumberAnimation {
        id: ringFadeInAnim; target: timerRing; property: "opacity"; to: 1.0; duration: 150
    }

    Timer {
        id: dismissTimer; interval: root.dismissMs; onTriggered: root.expire()
    }
}
