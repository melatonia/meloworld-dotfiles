import QtQuick
import Quickshell
import "../../theme"

Pill {
    pillColor: PanelColors.date

    SystemClock { id: clock; precision: SystemClock.Minutes }
    label: "󰃭 " + Qt.formatDate(clock.date, "ddd d MMM")
}
