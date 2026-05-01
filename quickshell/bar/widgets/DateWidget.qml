import QtQuick
import Quickshell
import "../../theme"

Pill {
    pillColor: PanelColors.date

    SystemClock { id: clock; precision: SystemClock.Minutes }
    label: "󰃭 " + Qt.formatDate(clock.date, "ddd d MMM")
    mouseArea.propagateComposedEvents: true
    mouseArea.onClicked: (mouse) => {
        if (SessionState.calendarVisible) {
            SessionState.calendarVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.calendarVisible = true
        }
        mouse.accepted = false
    }
}
