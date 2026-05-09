//@ pragma IconTheme Papirus
import QtQuick
import Quickshell
import "bar"
import "notifications"
import "osd"
import "dashboard"

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

            // Returns the X anchor for a right-bar popup centred under its trigger widget.
            // Pass the trigger widget and the popup's own implicitWidth.
            function popupX(widget, pWidth) {
                return Math.min(
                    bar.rightContainer.x + bar.rightBar.x + widget.x + widget.width / 2 - pWidth / 2,
                    bar.rightContainer.x + bar.rightContainer.width - pWidth
                )
            }

            function centerPopupX(pWidth) {
                return Math.round(panelWin.screen.width / 2 - pWidth / 2)
            }

            AudioPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.popupX(bar.rightBar.audioWidget, implicitWidth)
                anchor.rect.y: panelWin.height
            }
            BrightnessPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.popupX(bar.rightBar.brightnessWidget, implicitWidth)
                anchor.rect.y: panelWin.height
            }
            PowerProfilePopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.popupX(bar.rightBar.batteryWidget, implicitWidth)
                anchor.rect.y: panelWin.height
            }
            BluetoothPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.popupX(bar.rightBar.bluetoothWidget, implicitWidth)
                anchor.rect.y: panelWin.height
            }
            WifiPopup {
                screenObj: modelData
                xPos: panelWin.popupX(bar.rightBar.networkWidget, implicitWidth)
                anchorWindow: panelWin
            }
            SessionPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.popupX(bar.rightBar.sessionWidget, implicitWidth)
                anchor.rect.y: panelWin.height
            }
            TrayPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.popupX(bar.rightBar.trayBar, implicitWidth)
                anchor.rect.y: panelWin.height
            }
            CalendarPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.popupX(bar.rightBar.dateWidget, implicitWidth)
                anchor.rect.y: panelWin.height
            }

            MediaPopup {
                anchor.window: panelWin
                anchor.rect.x: panelWin.centerPopupX(implicitWidth)
                anchor.rect.y: panelWin.height
            }

            Dashboard {
                screenObj: modelData
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
    Variants {
        model: Quickshell.screens
        OsdWindow {
            required property var modelData
            screen: modelData
        }
    }
}
