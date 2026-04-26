import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../../theme"

Pill {
    id: root
    property var battery: UPower.displayDevice
    property bool hasBattery: battery && battery.ready
    property int pct: hasBattery ? Math.round(battery.percentage * 100) : 0
    property int prevPct: 0
    property bool charging: hasBattery && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.FullyCharged
    )

    pillColor: PanelColors.profileColor(PowerProfiles.profile)


    onPctChanged: {
        if (hasBattery && prevPct > 20 && pct <= 20 && !charging) {
            PowerProfiles.profile = PowerProfile.PowerSaver
            Quickshell.execDetached(["brightnessctl", "set", "50%"])
        }
        prevPct = pct
    }

    widestLabel: "󰁹 100%"
    label: {
        if (!hasBattery) return "󰚥"
        var sym = ""
        if (charging) {
            if (pct >= 90) sym = "󰂅"
            else if (pct >= 80) sym = "󰂋"
            else if (pct >= 70) sym = "󰂊"
            else if (pct >= 60) sym = "󰢞"
            else if (pct >= 50) sym = "󰂉"
            else if (pct >= 40) sym = "󰢝"
            else if (pct >= 30) sym = "󰂈"
            else if (pct >= 20) sym = "󰂇"
            else if (pct >= 10) sym = "󰂆"
            else sym = "󰢜"
        } else {
            if (pct >= 90) sym = "󰁹"
            else if (pct >= 80) sym = "󰂂"
            else if (pct >= 70) sym = "󰂁"
            else if (pct >= 60) sym = "󰂀"
            else if (pct >= 50) sym = "󰁿"
            else if (pct >= 40) sym = "󰁾"
            else if (pct >= 30) sym = "󰁽"
            else if (pct >= 20) sym = "󰁼"
            else if (pct >= 10) sym = "󰁻"
            else sym = "󰁺"
        }
        return sym + " " + pct + "%"
    }

    mouseArea.propagateComposedEvents: true
    mouseArea.onClicked: (mouse) => {
        if (SessionState.powerPopupVisible) {
            SessionState.powerPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.powerPopupVisible = true
        }
        mouse.accepted = false
    }
}
