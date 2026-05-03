import QtQuick
import Quickshell.Services.Notifications
import "../theme"

Rectangle {
    id: root
    required property Notification notification

    // ── Dimensions ────────────────────────────────
    readonly property int cardWidth:   400
    readonly property int dismissMs:   4000

    width:  cardWidth
    height: cardContent.implicitHeight + 32
    radius: 10
    color:  PanelColors.popupBackground
    border.color: accentColor
    border.width: 2
    clip: true
    layer.enabled: true

    // ── Accent color ──────────────────────────────
    readonly property color accentColor: {
        if (notification.urgency === Notification.Critical) return PanelColors.error
        if (notification.hints["x-hint-color"])             return notification.hints["x-hint-color"]
        return hashColor(notification.appName)
    }

    function hashColor(str) {
        var hash = 0
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }
        var colors = [
            Colors.teal200, Colors.lightBlue200, Colors.green200,
            Colors.purple200, Colors.orange200, Colors.pink200,
            Colors.yellow200, Colors.cyan200, Colors.deepPurple200,
            Colors.blueGrey300,
        ]
        return colors[Math.abs(hash) % colors.length]
    }

    // ── Entry animation ───────────────────────────
    Component.onCompleted: {
        dismissTimer.start()
        timerItem.startTime = Date.now()
    }

    // ── Dismiss logic ─────────────────────────────
    function dismiss() {
        dismissTimer.stop()
        ringTimer.running = false
        exitAnim.start()
    }

    SequentialAnimation {
        id: exitAnim
        NumberAnimation {
            target: root
            property: "x"
            to: cardWidth + 20
            duration: 250
            easing.type: Easing.InExpo
        }
        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 200
        }
        ScriptAction { script: notification.expire() }
    }

    Timer {
        id: dismissTimer
        interval: root.dismissMs
        onTriggered: root.dismiss()
    }

    // ── Hover: pause/resume dismiss ───────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        SequentialAnimation {
            id: hoverEnterAnim
            ScriptAction { script: {
                dismissTimer.stop()
                ringTimer.stop()
            }}
            NumberAnimation { target: timerRing; property: "progress"; to: 1.0; duration: 200 }
            PauseAnimation { duration: 100 }
            NumberAnimation { target: timerRing; property: "opacity"; to: 0.0; duration: 200 }
        }

        NumberAnimation {
            id: ringFadeInAnim
            target: timerRing
            property: "opacity"
            to: 1.0
            duration: 150
        }

        onEntered: {
            ringFadeInAnim.stop()
            hoverEnterAnim.start()
        }

        onExited: {
            hoverEnterAnim.stop()
            ringFadeInAnim.start()
            
            // Resume timer from current progress
            timerItem.startTime = Date.now() - (1.0 - timerRing.progress) * root.dismissMs
            dismissTimer.interval = timerRing.progress * root.dismissMs
            
            dismissTimer.restart()
            ringTimer.start()
        }
        onClicked: root.dismiss()
    }

    // ── Left accent stripe ────────────────────────
    Rectangle {
        width:  4
        height: parent.height - 24
        radius: 2
        anchors {
            left: parent.left
            leftMargin: 7
            verticalCenter: parent.verticalCenter
        }
        color:   root.accentColor
        opacity: 0.9
    }

    // ── Content ───────────────────────────────────
    Column {
        id: cardContent
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            topMargin:   14
            leftMargin:  24
            rightMargin: 16
        }
        spacing: 0

        // App name + timer ring row
        Row {
            width:  parent.width
            height: 22

            Text {
                text:  notification.appName
                font.pixelSize: 16
                font.bold:      true
                font.family:    "JetBrainsMono Nerd Font"
                color: root.accentColor
                width: parent.width - timerItem.width
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: timerItem
                width:  32
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                property real startTime: Date.now()

                Canvas {
                    id: timerRing
                    width: 22; height: 22
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
                            -Math.PI / 2 + (2 * Math.PI * progress),
                            false)
                        ctx.stroke()
                    }

                    onProgressChanged: requestPaint()
                }

                Timer {
                    id: ringTimer
                    interval: 50
                    running:  true
                    repeat:   true
                    onTriggered: {
                        timerRing.progress = Math.max(
                            0,
                            (root.dismissMs - (Date.now() - timerItem.startTime)) / root.dismissMs
                        )
                    }
                }
            }
        }

        // Separator
        Rectangle {
            width:   parent.width
            height:  2
            color:   PanelColors.rowBackground
            opacity: 0.6
        }

        Item { width: 1; height: 8 }

                // Summary
                Text {
                    visible: notification.summary !== ""
                    text:    notification.summary
                    font.pixelSize: 18
                    font.bold:      true
                    font.family:    "JetBrainsMono Nerd Font"
                    color: PanelColors.textAccent
                    width: parent.width
                    wrapMode:        Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

        Item { width: 1; height: 4 }

                // Body
                Text {
                    visible: notification.body !== ""
                    text:    notification.body
                    font.pixelSize: 14
                    font.family:    "JetBrainsMono Nerd Font"
                    color: PanelColors.textMain
                    width: parent.width
                    wrapMode:        Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
    }
}
