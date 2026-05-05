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

    // Returns the accent color for a given PowerProfile value.
    // Used by BatteryWidget (pill) and PowerProfilePopup (border + row highlight)
    // so both always stay in sync.
    function profileColor(profile) {
        if (profile === PowerProfile.PowerSaver)  return Colors.green200
        if (profile === PowerProfile.Performance) return Colors.red200
        return Colors.orange200
    }
}
