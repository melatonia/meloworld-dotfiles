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
                width: 24; height: 24
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
                onClicked: parent.modelData.activate()
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}
