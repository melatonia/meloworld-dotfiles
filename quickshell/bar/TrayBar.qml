import QtQuick
import Quickshell.Services.SystemTray

Row {
    spacing: 4

    Repeater {
        model: SystemTray.items
        delegate: Item {
            required property SystemTrayItem modelData
            width: 32; height: 32

            Image {
                anchors.centerIn: parent
                source: parent.modelData.icon
                width: 28; height: 28
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton)
                        parent.modelData.display.showContextMenu(-1, -1)
                    else
                        parent.modelData.display.activate(-1, -1)
                }
            }
        }
    }
}
