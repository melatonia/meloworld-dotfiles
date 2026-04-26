import QtQuick
import "../../theme"

Pill {
    id: root
    pillColor: (AudioState.muted || AudioState.volume === 0) ? PanelColors.rowBackground : PanelColors.audio
    textColor: (AudioState.muted || AudioState.volume === 0) ? PanelColors.textMain : PanelColors.pillForeground

    widestLabel: "󰕾 100%"
    label: (AudioState.muted || AudioState.volume === 0) ? "󰝟 Muted" : "󰕾 " + AudioState.volume + "%"

    mouseArea.onClicked: AudioState.popupVisible ? AudioState.hide() : AudioState.show()
    mouseArea.onWheel: (wheel) => {
        var newVol = wheel.angleDelta.y > 0
            ? Math.min(100, AudioState.volume + 5)
            : Math.max(0, AudioState.volume - 5)
        AudioState.setVolume(newVol)
    }
}
