import QtQuick
import Quickshell
import "../../theme"

Pill {
    pillColor: PanelColors.clock

    SystemClock { id: clock; precision: SystemClock.Seconds }
    label: " " + Qt.formatTime(clock.date, "HH:mm")
}
