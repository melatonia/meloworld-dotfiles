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

    Text {
        text: ""
        font.pixelSize: 16
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.pillForeground
    }

    Text {
        text: Qt.formatTime(clock.date, "HH:mm")
        font.pixelSize: 16
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.pillForeground
    }

    // Animated visualizer
    Item {
        visible: isPlaying
        width: 14
        height: 16
        anchors.verticalCenter: parent.verticalCenter

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
                    anchors.verticalCenter: parent.verticalCenter

                    // Standard Practice: Slight offsets create randomness
                    readonly property int targetHeight: index === 0 ? 14 : (index === 1 ? 10 : 16)
                    readonly property int animDuration: index === 0 ? 500 : (index === 1 ? 700 : 600)

                    SequentialAnimation on height {
                        running: isPlaying
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: bar.targetHeight
                            duration: bar.animDuration
                            easing.type: Easing.InOutSine
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
