import QtQuick
import Quickshell.Services.Notifications
import "../theme"

Rectangle {
    id: root
    required property Notification notification

    width: 320
    height: cardContent.implicitHeight + 24
    radius: 10
    color: Colors.grey900
    border.color: accentColor
    border.width: 2

    // Derive accent color from hint or app name hash
    readonly property color accentColor: {
        // Use app-provided hint color if available
        var hint = notification.hints["image-data"] ? "" : ""
        var hintColor = notification.hints["x-canonical-private-synchronous"]
        // Check for urgency-based coloring first
        if (notification.urgency === Notification.Critical) return Colors.red300
        // Try hint color
        if (notification.hints["x-hint-color"]) return notification.hints["x-hint-color"]
        // Hash the app name to a stable color from our palette
        return hashColor(notification.appName)
    }

    function hashColor(str) {
        var hash = 0
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }
        var colors = [
            Colors.teal200,
            Colors.lightBlue200,
            Colors.green200,
            Colors.purple200,
            Colors.orange200,
            Colors.pink200,
            Colors.yellow200,
            Colors.cyan200,
            Colors.deepPurple200,
            Colors.blueGrey300,
        ]
        var idx = Math.abs(hash) % colors.length
        return colors[idx]
    }

    // Start off-screen to the right
    opacity: 0
    x: 340

    Component.onCompleted: {
        opacity = 1
        x = 0
        dismissTimer.start()
        timerItem.startTime = Date.now()
    }

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on x {
        SmoothedAnimation { velocity: 1400; easing.type: Easing.OutExpo }
    }

    Timer {
        id: dismissTimer
        interval: 4000
        onTriggered: root.dismiss()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            dismissTimer.stop()
            ringTimer.running = false
            timerRing.progress = 1.0
            timerRing.requestPaint()
        }
        onExited: {
            dismissTimer.interval = 4000
            dismissTimer.restart()
            ringTimer.running = true
            timerItem.startTime = Date.now()
        }
        onClicked: root.dismiss()
    }

    function dismiss() {
        opacity = 0
        x = 340
        dismissTimer.stop()
        ringTimer.running = false
        dismissDelay.start()
    }

    Timer {
        id: dismissDelay
        interval: 250
        onTriggered: notification.expire()
    }

    // ── Left accent stripe ────────────────────────
    Rectangle {
        width: 3
        height: parent.height - 20
        radius: 2
        anchors {
            left: parent.left
            leftMargin: 6
            verticalCenter: parent.verticalCenter
        }
        color: root.accentColor
        opacity: 0.8
    }

    Column {
        id: cardContent
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
            leftMargin: 18
        }
        spacing: 4

        // ── Header: app name + timer ring ────────
        Row {
            width: parent.width

            Text {
                text: notification.appName
                font.pixelSize: 12
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: root.accentColor
                width: parent.width - 28
                elide: Text.ElideRight
            }

            Item {
                id: timerItem
                width: 24
                height: 24
                property real startTime: Date.now()

                Canvas {
                    id: timerRing
                    anchors.fill: parent
                    property real progress: 1.0

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.strokeStyle = root.accentColor
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(12, 12, 9, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * progress), false)
                        ctx.stroke()
                    }

                    onProgressChanged: requestPaint()
                }

                Timer {
                    id: ringTimer
                    interval: 50
                    running: true
                    repeat: true
                    onTriggered: {
                        timerRing.progress = Math.max(0, (4000 - (Date.now() - timerItem.startTime)) / 4000)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.grey500
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.dismiss()
                    }
                }
            }
        }

        // ── Summary ───────────────────────────────
        Text {
            visible: notification.summary !== ""
            text: notification.summary
            font.pixelSize: 14
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.grey100
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // ── Body ──────────────────────────────────
        Text {
            visible: notification.body !== ""
            text: notification.body
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.grey400
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
