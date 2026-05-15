pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "."

Singleton {
    readonly property bool isDark: ThemeState.isDark
    readonly property int transitionDuration: 250

    // Light theme definitions (Clean & Neutral, No Pure White)
    readonly property color lightBarBackground:    Colors.grey100
    readonly property color lightPopupBackground:  Colors.grey50
    readonly property color lightRowBackground:    Colors.grey200
    readonly property color lightTrackBackground:  Colors.grey300
    readonly property color lightBorder:           Colors.blueGrey100
    readonly property color lightTextMain:         Colors.blueGrey900
    readonly property color lightTextAccent:       Colors.blueGrey800
    readonly property color lightTextDim:          Colors.blueGrey400

    // Surfaces
    readonly property color barBackground:     isDark ? Colors.grey900 : lightBarBackground
    readonly property color pillForeground:    isDark ? Colors.grey900 : Colors.blueGrey900

    // Accents
// Accents
    readonly property color battery:           isDark ? Colors.orange200 : Colors.orange200
    readonly property color network:           isDark ? Colors.purple200 : Colors.purple200
    readonly property color audio:             isDark ? Colors.teal200 : Colors.teal200
    readonly property color clock:             isDark ? Colors.white : Colors.white
    readonly property color date:              isDark ? Colors.green200 : Colors.green200
    readonly property color brightness:        isDark ? Colors.yellow200 : Colors.yellow200
    readonly property color bluetooth:         isDark ? Colors.lightBlue200 : Colors.lightBlue200
    readonly property color session:           isDark ? Colors.red200 : Colors.red200
    readonly property color launcher:          isDark ? Colors.blueGrey700 : Colors.grey200

    readonly property color tray:              isDark ? Colors.grey800 : Colors.grey100
    readonly property color workspaceActive:   isDark ? Colors.white : Colors.teal200
    readonly property color workspaceInactive: isDark ? Colors.grey800 : Colors.grey200
    readonly property color titleBackground:   isDark ? Colors.grey800 : Colors.grey100
    readonly property color titleForeground:   isDark ? Colors.white : Colors.blueGrey700

    readonly property color popupBackground:   isDark ? Colors.grey900 : lightPopupBackground
    readonly property color rowBackground:     isDark ? Colors.grey800 : lightRowBackground
    readonly property color trackBackground:   isDark ? Colors.grey800 : lightTrackBackground
    readonly property color border:            isDark ? Colors.grey700 : lightBorder

    // Text
    readonly property color textMain:          isDark ? Colors.grey200 : lightTextMain
    readonly property color textDim:           isDark ? Colors.grey500 : lightTextDim
    readonly property color textAccent:        isDark ? Colors.white : lightTextAccent

    // Status
    readonly property color scanning:          isDark ? Colors.teal400 : Colors.teal400
    readonly property color networkScanning:   isDark ? Colors.deepPurple200 : Colors.deepPurple200
    readonly property color pairing:           isDark ? Colors.yellow600 : Colors.yellow600
    readonly property color error:             isDark ? Colors.red200 : Colors.red200

    // Dashboard specific
    readonly property color dashboardBackground: isDark ? Qt.rgba(0.08, 0.08, 0.09, 0.98) : Qt.rgba(0.95, 0.95, 0.96, 0.98)
    readonly property color dashboardCard:       isDark ? Colors.grey800 : Colors.grey200
    readonly property color dashboardAccent:     isDark ? Colors.lightBlue200 : Colors.lightBlue200
    readonly property color dashboardStripe:     isDark ? Colors.blueGrey700 : Colors.blueGrey200

    readonly property color profile:           isDark ? Colors.green200 : Colors.green200
    readonly property color system:            isDark ? Colors.blue200 : Colors.blue200

    readonly property color cpuRing:           isDark ? Colors.red200 : Colors.red200
    readonly property color ramRing:           isDark ? Colors.blue200 : Colors.blue200
    readonly property color gpuRing:           isDark ? Colors.green200 : Colors.green200

    // Functions
    function profileColor(profile) {
        if (profile === PowerProfile.PowerSaver)  return Colors.green200
        if (profile === PowerProfile.Performance) return Colors.red200
        return Colors.orange200
    }

    property var _hashCache: ({})
    function hashColor(str) {
        if (!str || str === "") return isDark ? Colors.blueGrey300 : Colors.blueGrey400
        if (_hashCache[str + isDark]) return _hashCache[str + isDark]

        var hash = 0
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }

        var palette = isDark ? [
            Colors.teal200, Colors.lightBlue200, Colors.green200,
            Colors.purple200, Colors.orange200, Colors.pink200,
            Colors.yellow200, Colors.cyan200, Colors.deepPurple200,
            Colors.blueGrey300
        ] : [
            Colors.teal300, Colors.lightBlue300, Colors.green400,
            Colors.purple300, Colors.orange300, Colors.pink300,
            Colors.yellow700, Colors.cyan300, Colors.deepPurple300,
            Colors.blueGrey400
        ]

        var result = palette[Math.abs(hash) % palette.length]
        _hashCache[str + isDark] = result
        return result
    }
}
