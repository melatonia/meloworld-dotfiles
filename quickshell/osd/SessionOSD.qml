import QtQuick
import Quickshell
import "../theme"

PanelWindow {
    id: root
    required property var screen

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: -1
    visible: SessionState.visible

    MouseArea {
        anchors.fill: parent
        onClicked: SessionState.hide()
    }

    Rectangle {
    anchors.fill: parent
    color: "#aa000000"

    MouseArea {
        anchors.fill: parent
        onClicked: SessionState.hide()
    }

    Column {
        anchors.centerIn: parent
        spacing: 32

        MouseArea {
            width: childrenRect.width
            height: childrenRect.height
            onClicked: {}

            Column {
                spacing: 32

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Quickshell.env("USER") + "@stardust"
                    font.pixelSize: 32
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.white
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Repeater {
                        model: [
                            { label: "⏻ Shutdown", color: Colors.red200,    cmd: ["systemctl", "poweroff"] },
                            { label: " Reboot",   color: Colors.orange200, cmd: ["systemctl", "reboot"] },
                            { label: "󰍃 Logout",   color: Colors.green200,  cmd: ["mmsg", "-q"] },
                            { label: "󰒲 Suspend",  color: Colors.blue200,   cmd: ["systemctl", "suspend"] },
                            { label: " Lock",     color: Colors.yellow200, cmd: ["hyprlock"] }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: 240
                            height: 66
                            radius: 8
                            color: modelData.color

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 32
                                font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey900
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.opacity = 0.85
                                onExited:  parent.opacity = 1.0
                                onClicked: {
                                    SessionState.hide()
                                    if (modelData.cmd.length > 0)
                                        Quickshell.execDetached(modelData.cmd)
                                }
                            }

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }
}
}
