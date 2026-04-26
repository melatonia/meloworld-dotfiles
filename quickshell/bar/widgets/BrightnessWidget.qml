import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.brightness

    readonly property int brightness: BrightnessState.brightness

    widestLabel: "󰃠 100%"
    label: {
        let ico = "󰃞 "
        if (brightness >= 80) ico = "󰃠 "
        else if (brightness >= 40) ico = "󰃟 "
        return ico + brightness + "%"
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
        let step = wheel.angleDelta.y > 0 ? 5 : -5
        BrightnessState.setBrightness(Math.max(0, Math.min(100, brightness + step)))
    }
}
