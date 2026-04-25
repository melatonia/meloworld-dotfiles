import QtQuick
import Quickshell
import "../theme"

PanelWindow {
    id: root
    
    anchors { bottom: true; left: true; right: true }
    exclusiveZone: 0 // Do not reserve any space, float above windows
    color: "transparent"

    // Set implicit dimensions for the PanelWindow
    implicitHeight: 64

    HoverHandler {
        id: hoverHandler
    }

    property bool isHovered: hoverHandler.hovered

    // Hiding logic:
    // When hidden, we set the bottom margin to negative height + 4px so a tiny invisible strip remains on screen to catch the mouse.
    margins.bottom: isHovered ? 12 : -implicitHeight + 4

    Behavior on margins.bottom {
        NumberAnimation { duration: 200; easing.type: Easing.OutExpo }
    }

    // Your list of pinned applications!
    // Simply edit this list to add, remove, or modify your dock items.
    property var apps: [
        { name: "Terminal", icon: "utilities-terminal", command: ["ghostty"] },
        { name: "Browser",  icon: "firefox", command: ["firefox"] },
        { name: "Files",    icon: "system-file-manager", command: ["thunar"] },
        { name: "Discord",  icon: "discord", command: ["discord"] },
        { name: "Spotify",  icon: "spotify", command: ["spotify"] }
    ]

    // HoverHandler passively catches hover events without blocking child clicks

    // The actual visible dock container
    Rectangle {
        id: dockRect
        anchors.centerIn: parent
        height: 64
        width: row.implicitWidth + 20
        
        radius: 12
        color: PanelColors.barBackground
        border.color: Colors.grey800
        border.width: 3

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            
            Repeater {
                model: root.apps
                delegate: DockItem {}
            }
        }
    }
}
