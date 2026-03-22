import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../theme"

PopupWindow {
    id: root
    visible: SessionState.bluetoothPopupVisible
    implicitWidth: 240
    implicitHeight: column.implicitHeight + 20
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.grey900
        border.color: Colors.grey800
        border.width: 2

        Column {
            id: column
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 4

            Rectangle {
                width: parent.width
                height: 32
                radius: 6
                color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                    ? Colors.lightBlue200 : Colors.grey800

                Row {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    spacing: 8
                    Text {
                        text: "󰂯"
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                        color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                            ? Colors.grey900 : Colors.lightBlue200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                            ? "Bluetooth On" : "Bluetooth Off"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                            ? Colors.grey900 : Colors.lightBlue200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        if (Bluetooth.defaultAdapter)
                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                    }
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Repeater {
                model: Bluetooth.devices
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.paired
                    width: parent.width
                    height: visible ? 32 : 0
                    radius: 6
                    color: modelData.connected ? Colors.lightBlue200 : Colors.grey800

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                            right: parent.right
                            rightMargin: 10
                        }
                        spacing: 8
                        Text {
                            text: modelData.connected ? "󰂱" : "󰂯"
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            color: modelData.connected ? Colors.grey900 : Colors.lightBlue200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.name.substring(0, 16)
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            color: modelData.connected ? Colors.grey900 : Colors.lightBlue200
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: modelData.connected && modelData.batteryAvailable
                            text: visible ? Math.round(modelData.battery * 100) + "%" : ""
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            color: modelData.connected ? Colors.grey900 : Colors.lightBlue200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: if (!modelData.connected) parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: modelData.connected = !modelData.connected
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
