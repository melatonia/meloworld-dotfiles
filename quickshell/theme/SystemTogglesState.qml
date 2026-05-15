pragma Singleton
import QtQuick
import Qt.labs.settings
import Quickshell

Singleton {
    id: root
    property bool nightLightOn: true
    property bool compositorEffectsOn: false

    Settings {
        fileName: Quickshell.env("HOME") + "/.config/meloworld-dotfiles/settings.conf"
        category: "System"
        property alias nightLightOn: root.nightLightOn
    }

    Component.onCompleted: {
        // Apply night light state on startup
        if (nightLightOn) {
            Quickshell.execDetached(["/bin/bash", "-c", "~/.local/bin/nightlight.sh"])
        }
    }

    readonly property var caffeineModes: [0, 5, 10, 30, -1]
    property int caffeineModeIndex: 0
    property int caffeineMinutes: caffeineModes[caffeineModeIndex]
    property bool caffeineOn: caffeineMinutes !== 0

    property var _caffeineTimer: Timer {
        id: caffeineTimer
        interval: 1000
        repeat: true
        running: caffeineOn && caffeineMinutes > 0
        property int remainingSeconds: 0

        onRunningChanged: {
            if (running) remainingSeconds = caffeineMinutes * 60
        }
        onTriggered: {
            remainingSeconds -= 1
            if (remainingSeconds <= 0) SystemTogglesState.disableCaffeine()
        }
    }

    readonly property string caffeineCountdown: {
        if (caffeineMinutes === -1) return "∞"
        if (!caffeineOn) return ""
        const s = _caffeineTimer.remainingSeconds
        const m = Math.floor(s / 60)
        const sec = s % 60
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    function cycleCaffeine() {
        caffeineModeIndex = (caffeineModeIndex + 1) % caffeineModes.length
        if (caffeineOn && caffeineMinutes > 0)
            _caffeineTimer.remainingSeconds = caffeineMinutes * 60
    }

    function disableCaffeine() {
        caffeineModeIndex = 0
    }

    function toggleNightLight() {
        nightLightOn = !nightLightOn
        if (nightLightOn) {
            Quickshell.execDetached(["/bin/bash", "-c", "~/.local/bin/nightlight.sh"])
        } else {
            Quickshell.execDetached(["killall", "wlsunset"])
        }
    }

    function toggleCompositorEffects() {
        compositorEffectsOn = !compositorEffectsOn
    }
}
