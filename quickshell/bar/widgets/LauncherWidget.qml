import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.launcher
    textColor: PanelColors.textAccent
    label: ""

    mouseArea.onClicked: {
        if (SessionState.dashboardVisible) {
            SessionState.dashboardVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.dashboardVisible = true
        }
    }
}
