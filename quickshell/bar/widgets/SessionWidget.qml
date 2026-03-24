import QtQuick
import "../../theme"

Pill {
    pillColor: PanelColors.session
    label: "⏻"

    mouseArea.onClicked: SessionState.show()
}
