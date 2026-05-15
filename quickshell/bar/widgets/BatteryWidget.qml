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
    property bool charging: hasBattery && (
        battery.state === UPowerDeviceState.Charging ||
        battery.state === UPowerDeviceState.FullyCharged
    )
    property int prevPct: 0

    pillColor: PanelColors.profileColor(PowerProfiles.profile)

    property int brightnessTarget: BrightnessState.brightness
    property bool isInternalChange: false

    Timer {
        id: brightnessTimer
        interval: 30
        repeat: true
        onTriggered: {
            if (BrightnessState.brightness === root.brightnessTarget) {
                stop()
                return
            }
            var next = BrightnessState.brightness > root.brightnessTarget
                ? Math.max(BrightnessState.brightness - 5, root.brightnessTarget)
                : Math.min(BrightnessState.brightness + 5, root.brightnessTarget)
            root.isInternalChange = true
            BrightnessState.setBrightness(next)
        }
    }

    function transitionBrightness(targetPct) {
        root.brightnessTarget = targetPct
        brightnessTimer.restart()
    }

    Connections {
        target: BrightnessState
        function onBrightnessChanged() {
            if (!root.isInternalChange && SystemTogglesState.isBatterySaverActive) {
                SystemTogglesState.wasManuallyOverridden = true
            }
            SystemTogglesState.lastBrightness = BrightnessState.brightness
            root.isInternalChange = false
        }
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            if (!root.isInternalChange && SystemTogglesState.isBatterySaverActive) {
                SystemTogglesState.wasManuallyOverridden = true
            }
            root.isInternalChange = false
        }
    }

    onPctChanged: {
        if (hasBattery) {
            // Entering Battery Saver
            if (prevPct > 20 && pct <= 20 && !charging && !SystemTogglesState.isBatterySaverActive) {
                SystemTogglesState.preSaverBrightness = BrightnessState.brightness
                SystemTogglesState.preSaverProfile = PowerProfiles.profile
                SystemTogglesState.isBatterySaverActive = true
                SystemTogglesState.wasManuallyOverridden = false

                root.isInternalChange = true
                transitionBrightness(60)
                PowerProfiles.profile = PowerProfile.PowerSaver
            }
        }
        prevPct = pct
    }

    onChargingChanged: {
        // Exiting Battery Saver when plugged in
        if (charging && SystemTogglesState.isBatterySaverActive) {
            if (!SystemTogglesState.wasManuallyOverridden) {
                root.isInternalChange = true
                transitionBrightness(SystemTogglesState.preSaverBrightness)
                PowerProfiles.profile = SystemTogglesState.preSaverProfile
            }
            SystemTogglesState.isBatterySaverActive = false
        }
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
