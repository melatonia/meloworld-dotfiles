import QtQuick
import Quickshell
import "../../theme"

Pill {
    pillColor: PanelColors.date

    SystemClock { id: clock; precision: SystemClock.Minutes }
    label: "󰃭 " + Qt.formatDate(clock.date, "MMM d")
    mouseArea.propagateComposedEvents: true
    mouseArea.onClicked: (mouse) => {
        if (CalendarState.visible) {
            CalendarState.hide()
        } else {
            SessionState.closeAllPopups()
            CalendarState.show()
        }
        mouse.accepted = false
    }
}
