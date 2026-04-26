import QtQuick
import "../../theme"

Pill {
    pillColor: PanelColors.session
    label: ""

    mouseArea.onClicked: {
        if (SessionState.visible) {
            SessionState.hide()
        } else {
            SessionState.closeAllPopups()
            SessionState.show()
        }
    }
}
