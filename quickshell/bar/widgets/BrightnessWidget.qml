import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.brightness

    // -- Optimistic State Logic --
    // Tracks the value the user is currently scrolling toward
    property int internalBrightness: BrightnessState.brightness

    // Define the window of time we "trust" user input over the backend
    Timer {
        id: wheelTimer
        interval: 400
    }

    // UI property: use the internal value if the user is actively scrolling
    readonly property int displayBrightness: wheelTimer.running ? internalBrightness : BrightnessState.brightness

    widestLabel: "󰃠 100%"
    label: {
        let ico = "󰃞 "
        if (displayBrightness >= 80) ico = "󰃠 "
        else if (displayBrightness >= 40) ico = "󰃟 "
        return ico + displayBrightness + "%"
    }

    mouseArea.onClicked: (mouse) => {
        if (BrightnessState.popupVisible) {
            BrightnessState.hide()
        } else {
            SessionState.closeAllPopups()
            BrightnessState.show()
        }
        mouse.accepted = false
    }

    mouseArea.onWheel: (wheel) => {
        // Calculate the next step based on our current optimistic value
        let base = wheelTimer.running ? internalBrightness : BrightnessState.brightness
        let step = wheel.angleDelta.y > 0 ? 5 : -5
        let newLevel = Math.max(0, Math.min(100, base + step))

        // Update local state immediately for instant UI feedback
        internalBrightness = newLevel
        wheelTimer.restart()

        // Push the update to the backend
        BrightnessState.setBrightness(newLevel)
    }
}
