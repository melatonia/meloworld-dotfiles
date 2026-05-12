import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.launcher
    textColor: PanelColors.textAccent

    SystemClock { id: clock; precision: SystemClock.Hours }

    label: {
        const h = clock.date.getHours()
        if (h >= 5 && h < 11) return ""
        if (h >= 11 && h < 17) return ""
        if (h >= 17 && h < 22) return "󰖚"
        return "󰖔"
    }

    mouseArea.onClicked: {
        if (SessionState.dashboardVisible) {
            SessionState.dashboardVisible = false
        } else {
            SessionState.dashboardVisible = true
        }
    }
}
