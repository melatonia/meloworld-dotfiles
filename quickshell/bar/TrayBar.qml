import QtQuick
import Quickshell.Services.SystemTray
import "widgets"
import "../theme"

Row {
    spacing: 6

    Repeater {
        model: SystemTray.items
        delegate: Pill {
            id: trayDelegate
            required property var modelData
            pillColor: PanelColors.tray
            
            implicitWidth: 32
            // implicitHeight: 28 (default)

            Image {
                anchors.centerIn: parent
                source: trayDelegate.modelData.icon || ""
                width: 20; height: 20
                smooth: true
                mipmap: true
                visible: source != ""
            }

            mouseArea.onClicked: trayDelegate.modelData.activate()
        }
    }
}
