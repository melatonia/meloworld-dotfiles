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
