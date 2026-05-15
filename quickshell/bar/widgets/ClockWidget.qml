import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../theme"
import "../../osd"

Pill {
    pillColor: PanelColors.clock

    readonly property bool isPlaying: {
        const vals = Mpris.players.values
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (p && p.playbackState === MprisPlaybackState.Playing && (p.trackTitle ?? "") !== "")
               return true
        }
        return false
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Canvas {
        id: clockCanvas
        width: 16
        height: 16
        antialiasing: true
        anchors.verticalCenter: parent.verticalCenter

        property var timeDate: clock.date
        onTimeDateChanged: requestPaint()

        readonly property color fgColor: PanelColors.pillForeground
        onFgColorChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var cx = width / 2
            var cy = height / 2
            var r = width / 2 - 1

            // Outline
            ctx.strokeStyle = PanelColors.pillForeground
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            var h = timeDate.getHours() % 12
            var m = timeDate.getMinutes()

            // Minute hand
            var mAngle = m * (Math.PI * 2 / 60) - Math.PI / 2
            ctx.beginPath()
            ctx.lineWidth = 1.5
            ctx.lineCap = "round"
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + Math.cos(mAngle) * (r - 2.5), cy + Math.sin(mAngle) * (r - 2.5))
            ctx.stroke()

            // Hour hand
            var hAngle = (h + m / 60) * (Math.PI * 2 / 12) - Math.PI / 2
            ctx.beginPath()
            ctx.lineWidth = 1.75
            ctx.lineCap = "round"
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + Math.cos(hAngle) * (r - 4.0), cy + Math.sin(hAngle) * (r - 4.0))
            ctx.stroke()
        }
    }

    Text {
        text: Qt.formatTime(clock.date, "HH:mm")
        font.pixelSize: 16
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.pillForeground
        Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
    }

    // Smooth Expanding Visualizer
    Item {
        id: visualizerContainer
        width: isPlaying ? 14 : 0
        height: 16
        clip: true
        anchors.verticalCenter: parent.verticalCenter

        Behavior on width {
            // Match the new Pill.qml speed
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        opacity: isPlaying ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Row {
            spacing: 2
            anchors.centerIn: parent

            Repeater {
                model: 3
                Rectangle {
                    id: bar
                    width: 2.2
                    radius: width / 2
                    color: PanelColors.pillForeground
                    Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property int targetHeight: index === 0 ? 14 : (index === 1 ? 10 : 16)
                    readonly property int animDuration: index === 0 ? 350 : (index === 1 ? 500 : 420)

                    SequentialAnimation on height {
                        running: isPlaying && visualizerContainer.opacity > 0.1
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: bar.targetHeight
                            duration: bar.animDuration
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            to: 4
                            duration: bar.animDuration
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }
    }

    mouseArea.onClicked: SessionState.mediaPopupVisible = !SessionState.mediaPopupVisible
}
