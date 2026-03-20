
import QtQuick
import Quickshell.Services.UPower
import "../../theme"

Pill {
    pillColor: PanelColors.battery
    property var battery: UPower.displayDevice
    property int pct: battery.ready ? Math.round(battery.percentage * 100) : 0
    property bool charging: battery.ready && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.FullyCharged
    )

    label: {
        if (!battery.ready) return "󰂑"
        var sym = ""
        if (charging) {
            if (pct >= 90) sym = "󰂋"
            else if (pct >= 80) sym = "󰂊"
            else if (pct >= 70) sym = "󰢞"
            else if (pct >= 60) sym = "󰂉"
            else if (pct >= 50) sym = "󰢝"
            else if (pct >= 40) sym = "󰂈"
            else if (pct >= 30) sym = "󰂇"
            else if (pct >= 20) sym = "󰂆"
            else if (pct >= 10) sym = "󰢜"
            else sym = "󰢟"
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
}
