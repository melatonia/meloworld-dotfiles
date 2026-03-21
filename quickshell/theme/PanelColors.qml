pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    readonly property color barBackground:     Colors.grey900
    readonly property color pillForeground:    Colors.grey900
    // readonly property color battery:           Colors.purple200
    readonly property color battery:           Colors.orange200
    // readonly property color network:           Colors.red200
    readonly property color network:           Colors.purple200
    readonly property color audio:             Colors.teal200
    readonly property color clock:             Colors.white
    readonly property color date:              Colors.green200
    readonly property color brightness:        Colors.yellow200
    readonly property color bluetooth:         Colors.lightBlue200
    readonly property color session:           Colors.pink200
    readonly property color launcher:          Colors.blueGrey700
    readonly property color workspaceActive:   Colors.white
    readonly property color workspaceInactive: Colors.grey800
    readonly property color titleBackground:   Colors.grey800
    readonly property color titleForeground:   Colors.white
}
