import QtQuick
import Quickshell.Services.SystemTray
import "widgets"
import "../theme"

Row {
    spacing: 6

    Repeater {
        model: SystemTray.items
        delegate: Rectangle {
            id: trayDelegate
            required property SystemTrayItem modelData

            implicitWidth: 32
            implicitHeight: 28
            radius: 5
            color: trayMouse.containsMouse ? Qt.lighter(PanelColors.tray, 1.15) : PanelColors.tray
            scale: trayMouse.containsMouse ? 1.03 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

            Image {
                anchors.centerIn: parent
                source: trayDelegate.modelData.icon || ""
                width: 20; height: 20
                smooth: true; mipmap: true
                visible: source !== ""
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (trayDelegate.modelData.hasMenu) {
                            if (TrayState.visible && TrayState.activeItem === trayDelegate.modelData) {
                                TrayState.hide()
                                return
                            }
                            SessionState.closeAllPopups()
                            const pos = trayDelegate.mapToItem(null, 0, 0)
                            TrayState.show(trayDelegate.modelData, pos.x, pos.y)
                        }
                    } else {
                        if (trayDelegate.modelData.onlyMenu) {
                            if (TrayState.visible && TrayState.activeItem === trayDelegate.modelData) {
                                TrayState.hide()
                                return
                            }
                            SessionState.closeAllPopups()
                            const pos = trayDelegate.mapToItem(null, 0, 0)
                            TrayState.show(trayDelegate.modelData, pos.x, pos.y)
                        } else {
                            trayDelegate.modelData.activate()
                        }
                    }
                }

                onWheel: (wheel) => {
                    trayDelegate.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
