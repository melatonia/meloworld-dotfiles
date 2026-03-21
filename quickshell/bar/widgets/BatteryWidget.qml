import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import "../../theme"

Pill {
    id: root
    property var battery: UPower.displayDevice
    property int pct: battery.ready ? Math.round(battery.percentage * 100) : 0
    property int prevPct: 0
    property bool charging: battery.ready && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.FullyCharged
    )

    pillColor: {
        if (PowerProfiles.profile === PowerProfile.PowerSaver)  return Colors.green200
        if (PowerProfiles.profile === PowerProfile.Performance) return Colors.red200
        return Colors.orange200
    }

    onPctChanged: {
        if (prevPct >= 20 && pct < 20 && !charging) {
            PowerProfiles.profile = PowerProfile.PowerSaver
            brightnessProc.running = true
        }
        prevPct = pct
    }

    label: {
        if (!battery.ready) return "󰂑"
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

    Process {
        id: brightnessProc
        command: ["brightnessctl", "--device=amdgpu_bl1", "set", "60%"]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onClicked: (mouse) => {
            SessionState.powerPopupVisible = !SessionState.powerPopupVisible
            mouse.accepted = false
        }
    }
}
