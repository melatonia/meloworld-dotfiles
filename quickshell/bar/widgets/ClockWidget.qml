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

    Text {
        visible: isPlaying
        text: "󰝚"
        font.pixelSize: 16
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.pillForeground
    }

    mouseArea.onClicked: SessionState.mediaPopupVisible = !SessionState.mediaPopupVisible
}
