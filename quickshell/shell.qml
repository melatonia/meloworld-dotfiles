//@ pragma IconTheme Papirus
import QtQuick
import Quickshell
import "bar"
import "notifications"
import "osd"

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panelWin
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 55
            color: "transparent"
            exclusiveZone: implicitHeight
            Bar { id: bar; anchors.fill: parent }
            AudioPopup {
                anchor.window: panelWin
                anchor.rect.x: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.audioWidget.x + (bar.rightBar.audioWidget.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                anchor.rect.y: panelWin.height
            }
            BrightnessPopup {
                anchor.window: panelWin
                anchor.rect.x: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.brightnessWidget.x + (bar.rightBar.brightnessWidget.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                anchor.rect.y: panelWin.height
            }
            PowerProfilePopup {
                anchor.window: panelWin
                anchor.rect.x: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.batteryWidget.x + (bar.rightBar.batteryWidget.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                anchor.rect.y: panelWin.height
            }
            BluetoothPopup {
                anchor.window: panelWin
                anchor.rect.x: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.bluetoothWidget.x + (bar.rightBar.bluetoothWidget.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                anchor.rect.y: panelWin.height
            }
            WifiPopup {
                id: wifiPopup
                screenObj: modelData
                xPos: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.networkWidget.x + (bar.rightBar.networkWidget.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                yPos: panelWin.height
            }
            SessionPopup {
                anchor.window: panelWin
                anchor.rect.x: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.sessionWidget.x + (bar.rightBar.sessionWidget.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                anchor.rect.y: panelWin.height
            }
            TrayPopup {
                anchor.window: panelWin
                anchor.rect.x: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.trayBar.x + (bar.rightBar.trayBar.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                anchor.rect.y: panelWin.height
            }
            CalendarPopup {
                anchor.window: panelWin
                anchor.rect.x: Math.min(bar.rightContainer.x + bar.rightBar.x + bar.rightBar.dateWidget.x + (bar.rightBar.dateWidget.width / 2) - (implicitWidth / 2), bar.rightContainer.x + bar.rightContainer.width - implicitWidth)
                anchor.rect.y: panelWin.height
            }
        }
    }
    Variants {
        model: Quickshell.screens
        NotificationPopup {
            required property var modelData
            screen: modelData
        }
    }
}
