import QtQuick
import "../../theme"

Pill {
    id: root

    // ── Optimistic State ──────────────────────────
    // Tracks the value the user is currently scrolling to
    property int internalVolume: AudioState.volume

    // Decide when to stop "trusting" the internal value
    Timer {
        id: wheelTimer
        interval: 400
    }

    // UI properties derived from either optimistic or actual state
    readonly property int displayVolume: wheelTimer.running ? internalVolume : AudioState.volume
    readonly property bool isEffectivelyMuted: AudioState.muted || displayVolume === 0

    // ── Pill Configuration ────────────────────────
    pillColor: isEffectivelyMuted ? PanelColors.rowBackground : PanelColors.audio
    textColor: isEffectivelyMuted ? PanelColors.textMain : PanelColors.pillForeground

    widestLabel: "󰕾 100%"
    label: {
        if (isEffectivelyMuted) return "󰝟 Muted"
        let ico = "󰕿"
        if (displayVolume >= 66) ico = "󰕾"
        else if (displayVolume >= 33) ico = "󰖀"
        return ico + " " + displayVolume + "%"
    }

    mouseArea.onClicked: AudioState.popupVisible ? AudioState.hide() : AudioState.show()

    mouseArea.onWheel: (wheel) => {
        // Use the current optimistic value as the base if scrolling is active
        var base = wheelTimer.running ? internalVolume : AudioState.volume
        var newVol = wheel.angleDelta.y > 0
            ? Math.min(100, base + 5)
            : Math.max(0, base - 5)

        // Update local state immediately for a smooth UI feel
        internalVolume = newVol
        wheelTimer.restart()

        // Send update to backend
        AudioState.setVolume(newVol)
    }
}
