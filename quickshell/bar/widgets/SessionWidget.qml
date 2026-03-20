import QtQuick
import "../../theme"

Pill {
    pillColor: PanelColors.session
    label: "⏻"

    MouseArea {
        anchors.fill: parent
        onClicked: SessionState.show()
    }
}
