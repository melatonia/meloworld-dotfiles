// LauncherBase.qml
// Shared constants used by all launcher view components.
// Each view imports this as a namespace via an instance, or reads
// the readonly properties directly since they are literal constants.
import QtQuick

Item {
    // ── Signals every view exposes upward ────────────────────────────────
    signal dismissed()

    // ── Layout constants ─────────────────────────────────────────────────
    readonly property int  rowHeight:    44
    readonly property int  rowRadius:    8
    readonly property int  rowSpacing:   2
    readonly property int  fontSizeRow:  16
    readonly property int  fontSizeSmall: 13
    readonly property int  iconSize:     24
    readonly property string monoFont:  "JetBrainsMono Nerd Font"
}
