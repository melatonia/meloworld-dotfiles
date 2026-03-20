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

    opacity: 0
    x: 20

    Component.onCompleted: {
        opacity = 1
        x = 0
        dismissTimer.start()
        timerItem.startTime = Date.now()
    }

    Behavior on opacity { NumberAnimation { duration: 200 } }
    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

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
        x = 20
        dismissTimer.stop()
        ringTimer.running = false
        dismissDelay.start()
    }

    Timer {
        id: dismissDelay
        interval: 200
        onTriggered: notification.expire()
    }

    Column {
        id: cardContent
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        spacing: 4

        Row {
            width: parent.width

            Text {
                text: notification.appName
                font.pixelSize: 20
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.purple200
                width: parent.width - 24
                elide: Text.ElideRight
            }

            Item {
                id: timerItem
                width: 28
                height: 28
                property real startTime: Date.now()

                Canvas {
                    id: timerRing
                    anchors.fill: parent
                    property real progress: 1.0

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.strokeStyle = Colors.purple200
                        ctx.lineWidth = 3
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(14, 13, 12, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * progress), false)
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
                    text: ""
                    font.pixelSize: 20
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.grey500

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.dismiss()
                    }
                }
            }
        }

        Text {
            visible: notification.summary !== ""
            text: notification.summary
            font.pixelSize: 17
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.white
            width: parent.width
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }

        Text {
            visible: notification.body !== ""
            text: notification.body
            font.pixelSize: 16
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
