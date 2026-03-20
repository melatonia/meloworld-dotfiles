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
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 55
            color: "transparent"
            exclusiveZone: implicitHeight
            Bar { anchors.fill: parent }
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

        SessionOSD {
            required property var modelData
            screen: modelData
        }
    }
}
