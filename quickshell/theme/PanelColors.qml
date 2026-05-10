pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "."

Singleton {
    readonly property color barBackground:     Colors.grey900
    readonly property color pillForeground:    Colors.grey900
    readonly property color battery:           Colors.orange200
    readonly property color network:           Colors.purple200
    readonly property color audio:             Colors.teal200
    readonly property color clock:             Colors.white
    readonly property color date:              Colors.green200
    readonly property color brightness:        Colors.yellow200
    readonly property color bluetooth:         Colors.lightBlue200
    readonly property color session:           Colors.red200
    readonly property color launcher:          Colors.blueGrey700
    readonly property color tray:              Colors.grey800
    readonly property color workspaceActive:   Colors.white
    readonly property color workspaceInactive: Colors.grey800
    readonly property color titleBackground:   Colors.grey800
    readonly property color titleForeground:   Colors.white

    readonly property color popupBackground:   Colors.grey900
    readonly property color rowBackground:     Colors.grey800
    readonly property color trackBackground:   Qt.rgba(1, 1, 1, 0.15)
    readonly property color border:            Colors.grey700

    readonly property color textMain:          Colors.grey200
    readonly property color textDim:           Colors.grey500
    readonly property color textAccent:        Colors.white

    readonly property color scanning:          Colors.teal400
    readonly property color networkScanning:   Colors.deepPurple200
    readonly property color pairing:           Colors.yellow600
    readonly property color error:             Colors.red200

    // Dashboard specific
    readonly property color dashboardBackground: Qt.rgba(0.08, 0.08, 0.09, 0.98)
    readonly property color dashboardCard:       Colors.grey800
    readonly property color dashboardAccent:     Colors.lightBlue200
    readonly property color dashboardStripe:     Colors.blueGrey700

    readonly property color profile:           Colors.green200
    readonly property color system:            Colors.blue200

    readonly property color cpuRing:           Colors.red200
    readonly property color ramRing:           Colors.blue200
    readonly property color gpuRing:           Colors.green200


    // Returns the accent color for a given PowerProfile value.
    // Used by BatteryWidget (pill) and PowerProfilePopup (border + row highlight)
    // so both always stay in sync.
    function profileColor(profile) {
        if (profile === PowerProfile.PowerSaver)  return Colors.green200
        if (profile === PowerProfile.Performance) return Colors.red200
        return Colors.orange200
    }

    property var _hashCache: ({})
    function hashColor(str) {
        if (!str || str === "") return Colors.blueGrey300
        if (_hashCache[str]) return _hashCache[str]
        
        var hash = 0
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }
        var palette = [ Colors.teal200, Colors.lightBlue200, Colors.green200,
                        Colors.purple200, Colors.orange200, Colors.pink200,
                        Colors.yellow200, Colors.cyan200, Colors.deepPurple200,
                        Colors.blueGrey300 ]
        var result = palette[Math.abs(hash) % palette.length]
        _hashCache[str] = result
        return result
    }
}
