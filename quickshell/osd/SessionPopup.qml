import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

PopupWindow {
    id: root
    visible: animState !== "closed"
    implicitWidth: 180
    implicitHeight: 600
    color: "transparent"

    property string animState: "closed"
    property string menuState: "menu" // "menu", "confirm_shutdown", "confirm_reboot", "confirm_logout"

    Connections {
        target: SessionState
        function onVisibleChanged() {
            if (SessionState.visible) {
                animState = "open"
                menuState = "menu"
            } else {
                animState = "closing"
            }
        }
    }

    Rectangle {
        id: innerRect
        width: parent.width
        height: contentArea.implicitHeight + 20
        Behavior on height {
            SmoothedAnimation { velocity: 800; easing.type: Easing.OutExpo }
        }

        y: 0
        opacity: 1.0

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: innerRect; y: 0; opacity: 1.0 }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: innerRect; y: -20; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                SequentialAnimation {
                    PropertyAction { target: innerRect; property: "y"; value: -20 }
                    PropertyAction { target: innerRect; property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y"; to: 0; duration: 250; easing.type: Easing.OutExpo }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y"; to: -20; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        radius: 10
        color: Colors.grey900
        border.color: PanelColors.session
        border.width: 2
        clip: true

        Item {
            id: contentArea
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
            implicitHeight: root.menuState === "menu" ? menuColumn.implicitHeight : confirmColumn.implicitHeight

            Column {
                id: menuColumn
                width: parent.width
                spacing: 4
                visible: root.menuState === "menu"
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Repeater {
                    model: [
                        { label: "Shutdown", icon: "⏻", action: "confirm_shutdown" },
                        { label: "Reboot",   icon: "", action: "confirm_reboot" },
                        { label: "Logout",   icon: "󰍃", action: "confirm_logout" },
                        { label: "Suspend",  icon: "󰒲", action: "suspend" },
                        { label: "Lock",     icon: "", action: "lock" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 34; radius: 6
                        color: Colors.grey800

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
                                color: Colors.grey200; anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.label
                                font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey200; anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: parent.opacity = 0.8
                            onExited: parent.opacity = 1.0
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
                        color: Colors.white
                    }
                }

                Row {
                    width: parent.width
                    spacing: 4
                    Rectangle {
                        width: (parent.width - 4) / 2; height: 34; radius: 6
                        color: Colors.grey800
                        Text {
                            anchors.centerIn: parent
                            text: "No"
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey200
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: parent.opacity = 0.8
                            onExited: parent.opacity = 1.0
                            onClicked: root.menuState = "menu"
                        }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Rectangle {
                        width: (parent.width - 4) / 2; height: 34; radius: 6
                        color: PanelColors.session
                        Text {
                            anchors.centerIn: parent
                            text: "Yes"
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey900
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: parent.opacity = 0.8
                            onExited: parent.opacity = 1.0
                            onClicked: {
                                SessionState.hide()
                                if (root.menuState === "confirm_shutdown") {
                                    Quickshell.execDetached(["systemctl", "poweroff"])
                                } else if (root.menuState === "confirm_reboot") {
                                    Quickshell.execDetached(["systemctl", "reboot"])
                                } else if (root.menuState === "confirm_logout") {
                                    Quickshell.execDetached(["mmsg", "-q"])
                                }
                            }
                        }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
