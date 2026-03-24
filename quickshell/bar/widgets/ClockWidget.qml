import QtQuick
import Quickshell
import "../../theme"

Pill {
    pillColor: PanelColors.clock

    SystemClock { id: clock; precision: SystemClock.Minutes }
    label: " " + Qt.formatTime(clock.date, "HH:mm")
}
