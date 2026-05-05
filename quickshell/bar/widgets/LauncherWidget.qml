import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.launcher
    textColor: PanelColors.textAccent
    label: ""

    mouseArea.onClicked: {
        Quickshell.execDetached(["rofi", "-show", "drun"])
    }
}
