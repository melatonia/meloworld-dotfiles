import QtQuick
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.audio

    label: (AudioState.muted || AudioState.volume === 0) ? "󰝟" : "󰕾 " + AudioState.volume + "%"

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.opacity = 0.85
        onExited:  root.opacity = 1.0
        onClicked: AudioState.popupVisible ? AudioState.hide() : AudioState.show()
        onWheel: (wheel) => {
            var newVol = wheel.angleDelta.y > 0
                ? Math.min(100, AudioState.volume + 5)
                : Math.max(0, AudioState.volume - 5)
            AudioState.setVolume(newVol)
        }
    }
}
