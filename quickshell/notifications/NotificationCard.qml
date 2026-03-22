import QtQuick
import Quickshell.Services.Notifications
import "../theme"

Rectangle {
    id: root
    required property Notification notification

    width: 400
    height: cardContent.implicitHeight + 32
    radius: 10
    color: Colors.grey900
    border.color: accentColor
    border.width: 2

    readonly property color accentColor: {
        if (notification.urgency === Notification.Critical) return Colors.red300
        if (notification.hints["x-hint-color"]) return notification.hints["x-hint-color"]
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
        return colors[Math.abs(hash) % colors.length]
    }

    opacity: 0
    x: 420

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
        x = 420
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
        width: 4
        height: parent.height - 24
        radius: 2
        anchors {
            left: parent.left
            leftMargin: 7
            verticalCenter: parent.verticalCenter
        }
        color: root.accentColor
        opacity: 0.9
    }

    Column {
        id: cardContent
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 14
            bottomMargin: 14
            leftMargin: 24
            rightMargin: 16
        }
        spacing: 0

        // ── App name row — compact label ──────────
        Row {
            width: parent.width
            height: 22

            Text {
                text: notification.appName
                font.pixelSize: 16
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: root.accentColor
                width: parent.width - 32
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: timerItem
                width: 32
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
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(11, 11, 8, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * progress), false)
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
                    anchors.centerIn: timerRing
                    text: ""
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.grey500
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.dismiss()
                    }
                }
            }
        }

        // ── Thin separator between label and content
        Rectangle {
            width: parent.width
            height: 1
            color: Colors.grey800
            opacity: 0.6
            anchors.topMargin: 6
            // small gap above and below
            Item { width: 1; height: 6 }
        }

        Item { width: 1; height: 8 }

        // ── Summary ───────────────────────────────
        Text {
            visible: notification.summary !== ""
            text: notification.summary
            font.pixelSize: 18
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.grey100
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Item { width: 1; height: 4 }

        // ── Body ──────────────────────────────────
        Text {
            visible: notification.body !== ""
            text: notification.body
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.grey300
            width: parent.width
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
