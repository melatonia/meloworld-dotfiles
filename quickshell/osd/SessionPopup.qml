import QtQuick
import Quickshell
import "../theme"

PopupBase {
    id: root
    implicitWidth:  180
    borderColor:    PanelColors.session
    clipContent:    true
    contentHeight:  contentArea.implicitHeight

    property string menuState: "menu" // "menu" | "confirm_shutdown" | "confirm_reboot" | "confirm_logout"

    Connections {
        target: SessionState
        function onVisibleChanged() {
            if (SessionState.visible) {
                root.animState = "open"
                root.menuState = "menu"
            } else {
                root.animState = "closing"
            }
        }
    }

    // ── Content ───────────────────────────────────
    Item {
        id: contentArea
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
        implicitHeight: root.menuState === "menu" ? menuColumn.implicitHeight : confirmColumn.implicitHeight

        // ── Main menu ─────────────────────────────
        Column {
            id: menuColumn
            width: parent.width
            spacing: 4
            visible: root.menuState === "menu"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Repeater {
                model: [
                    { label: "Shutdown", icon: "󰐥", action: "confirm_shutdown" },
                    { label: "Reboot",   icon: "", action: "confirm_reboot"   },
                    { label: "Logout",   icon: "󰍃", action: "confirm_logout"  },
                    { label: "Suspend",  icon: "󰒲", action: "suspend"         },
                    { label: "Lock",     icon: "", action: "lock"             }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width; height: 34; radius: 6
                    color: PanelColors.rowBackground

                    Rectangle {
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: PanelColors.session
                    }
                    Row {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                        spacing: 8
                        Text {
                            text: modelData.icon
                            font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textMain; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textMain; anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.opacity = 0.8
                        onExited:  parent.opacity = 1.0
                        onClicked: {
                            if (modelData.action.startsWith("confirm_")) {
                                root.menuState = modelData.action
                            } else if (modelData.action === "suspend") {
                                SessionState.hide()
                                Quickshell.execDetached(["hyprlock"])
                                Quickshell.execDetached(["systemctl", "suspend"])
                            } else if (modelData.action === "lock") {
                                SessionState.hide()
                                Quickshell.execDetached(["hyprlock"])
                            }
                        }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        // ── Confirm dialog ────────────────────────
        Column {
            id: confirmColumn
            width: parent.width
            spacing: 4
            visible: root.menuState !== "menu"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Rectangle {
                width: parent.width; height: 34; color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "Are you sure?"
                    font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textAccent
                }
            }

            Row {
                width: parent.width
                spacing: 4

                // No
                Rectangle {
                    width: (parent.width - 4) / 2; height: 34; radius: 6
                    color: PanelColors.rowBackground
                    Text {
                        anchors.centerIn: parent
                        text: "No"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textMain
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.opacity = 0.8
                        onExited:  parent.opacity = 1.0
                        onClicked: root.menuState = "menu"
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Yes
                Rectangle {
                    width: (parent.width - 4) / 2; height: 34; radius: 6
                    color: PanelColors.session
                    Text {
                        anchors.centerIn: parent
                        text: "Yes"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.opacity = 0.8
                        onExited:  parent.opacity = 1.0
                        onClicked: {
                            SessionState.hide()
                            if      (root.menuState === "confirm_shutdown") Quickshell.execDetached(["systemctl", "poweroff"])
                            else if (root.menuState === "confirm_reboot")   Quickshell.execDetached(["systemctl", "reboot"])
                            else if (root.menuState === "confirm_logout")   Quickshell.execDetached(["mmsg", "-q"])
                        }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
