pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool nightLightOn: true
    property bool caffeineOn: false
    property bool dndOn: true
    property bool compositorEffectsOn: false

    function toggleNightLight() {
        nightLightOn = !nightLightOn
        if (nightLightOn) {
            Quickshell.execDetached(["/bin/bash", "-c", "~/.local/bin/nightlight.sh"])
        } else {
            Quickshell.execDetached(["killall", "wlsunset"])
        }
    }

    function toggleCaffeine() {
        caffeineOn = !caffeineOn
        if (caffeineOn) {
            Quickshell.execDetached(["killall", "hypridle"])
        } else {
            Quickshell.execDetached(["hypridle"])
        }
    }

    function toggleCompositorEffects() {
        compositorEffectsOn = !compositorEffectsOn
        // Empty toggle logic per user request
    }
}
