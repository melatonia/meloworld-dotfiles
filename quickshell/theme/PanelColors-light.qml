pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "."

Singleton {
    // Pill + bar surfaces — warm off-white
    readonly property color barBackground:     Colors.grey50
    readonly property color pillForeground:    Colors.grey50

    // Pastel accents
    readonly property color battery:           Colors.orange300
    readonly property color network:           Colors.purple300
    readonly property color audio:             Colors.teal300
    readonly property color clock:             Colors.blueGrey400
    readonly property color date:              Colors.green400
    readonly property color brightness:        Colors.yellow700
    readonly property color bluetooth:         Colors.lightBlue300
    readonly property color session:           Colors.red300
    readonly property color launcher:          Colors.blueGrey300

    // Surfaces
    readonly property color tray:              Colors.blueGrey200
    readonly property color workspaceActive:   Colors.blueGrey500
    readonly property color workspaceInactive: Colors.blueGrey200
    readonly property color titleBackground:   Colors.grey100
    readonly property color titleForeground:   Colors.blueGrey600

    readonly property color popupBackground:   Colors.grey50
    readonly property color rowBackground:     Colors.grey200
    readonly property color trackBackground:   Qt.rgba(0, 0, 0, 0.07)
    readonly property color border:            Colors.blueGrey200

    // Text
    readonly property color textMain:          Colors.blueGrey700
    readonly property color textDim:           Colors.blueGrey300
    readonly property color textAccent:        Colors.blueGrey600

    // Status
    readonly property color scanning:          Colors.teal300
    readonly property color networkScanning:   Colors.deepPurple200
    readonly property color pairing:           Colors.yellow500
    readonly property color error:             Colors.red400

    function profileColor(profile) {
        if (profile === PowerProfile.PowerSaver)  return Colors.green300
        if (profile === PowerProfile.Performance) return Colors.red300
        return Colors.orange300
    }
}
