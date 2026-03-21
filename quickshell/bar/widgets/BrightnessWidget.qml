import QtQuick
import Quickshell.Io
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.brightness
    property int brightness: 0
    property int maxBrightness: 0
    property int rawBrightness: 0

    function updateBrightness() {
        if (maxBrightness > 0 && rawBrightness > 0)
            brightness = Math.round((rawBrightness / maxBrightness) * 100)
    }

    label: {
        if (brightness >= 80) return "󰃠 " + brightness + "%"
        else if (brightness >= 40) return "󰃟 " + brightness + "%"
        else return "󰃞 " + brightness + "%"
    }

    FileView {
        id: maxFile
        path: "/sys/class/backlight/amdgpu_bl1/max_brightness"
        onLoaded: {
            const v = parseInt(text())
            if (!isNaN(v) && v > 0) {
                root.maxBrightness = v
                root.updateBrightness()
            }
        }
    }

    FileView {
        id: brightnessFile
        path: "/sys/class/backlight/amdgpu_bl1/brightness"
        watchChanges: true
        onLoaded: {
            const raw = parseInt(text())
            if (!isNaN(raw)) {
                root.rawBrightness = raw
                root.updateBrightness()
            }
        }
        onFileChanged: reload()
    }

    Process {
        id: setProc
        property string step: ""
        command: ["brightnessctl", "--device=amdgpu_bl1", "set", step]
        running: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.opacity = 0.85
        onExited: root.opacity = 1.0
        onWheel: (wheel) => {
            setProc.step = wheel.angleDelta.y > 0 ? "+5%" : "5%-"
            setProc.running = true
        }
    }
}
