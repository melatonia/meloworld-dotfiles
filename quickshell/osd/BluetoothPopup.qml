import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../theme"

PopupWindow {
    id: root
    visible: SessionState.bluetoothPopupVisible
    implicitWidth: 240
    implicitHeight: 600
    color: "transparent"

    readonly property bool btOn: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
    readonly property bool scanning: btOn && Bluetooth.defaultAdapter.discovering
    readonly property int maxListHeight: 5 * 34 + 4 * 4

    function isMacAddress(name) {
        return /^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$/.test(name.trim())
    }

    Rectangle {
        id: innerRect
        width: parent.width
        height: column.implicitHeight + 20
        Behavior on height {
            SmoothedAnimation { velocity: 800; easing.type: Easing.OutExpo }
        }
        radius: 10
        color: Colors.grey900
        border.color: root.btOn ? Colors.lightBlue200 : Colors.grey700
        border.width: 2
        clip: true

        Column {
            id: column
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 10
            }
            spacing: 4

            // ── Adapter toggle ────────────────────────────
            Rectangle {
                width: parent.width; height: 34; radius: 6
                color: root.btOn ? Colors.lightBlue200 : Colors.grey800

                Rectangle {
                    visible: !root.btOn
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: Colors.lightBlue200
                }
                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                    spacing: 8
                    Text {
                        text: ""
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: root.btOn ? Colors.grey900 : Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.btOn ? "Bluetooth On" : "Bluetooth Off"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: root.btOn ? Colors.grey900 : Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // ── Paired devices ────────────────────────────
            Repeater {
                model: Bluetooth.devices
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.paired
                    width: parent.width; height: visible ? 34 : 0; radius: 6
                    color: modelData.connected ? Colors.lightBlue200 : Colors.grey800

                    Rectangle {
                        visible: !modelData.connected
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: Colors.lightBlue200
                    }
                    Row {
                        anchors {
                            left: parent.left; verticalCenter: parent.verticalCenter
                            leftMargin: 14; right: parent.right; rightMargin: 10
                        }
                        spacing: 8
                        Text {
                            text: modelData.connected ? "" : ""
                            font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                            color: modelData.connected ? Colors.grey900 : Colors.grey200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.name
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: modelData.connected ? Colors.grey900 : Colors.grey200
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 23 - 8
                                   - (modelData.connected && modelData.batteryAvailable ? 36 : 0)
                        }
                        Text {
                            visible: modelData.connected && modelData.batteryAvailable
                            text: visible ? modelData.battery + "%" : ""
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey900
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: if (!modelData.connected) parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: modelData.connected = !modelData.connected
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ── Divider ───────────────────────────────────
            Rectangle {
                visible: root.btOn
                width: parent.width; height: visible ? 1 : 0
                color: Colors.grey800
            }

            // ── Scan toggle ───────────────────────────────
            Rectangle {
                visible: root.btOn
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: root.scanning ? Colors.teal400 : Colors.grey800

                Rectangle {
                    visible: !root.scanning
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: Colors.teal400
                }
                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                    spacing: 8
                    Text {
                        text: root.scanning ? "" : ""
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: root.scanning ? Colors.grey900 : Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            running: root.scanning
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        text: root.scanning ? "Scanning..." : "Scan"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: root.scanning ? Colors.grey900 : Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // ── Pair with PIN ─────────────────────────────
            Rectangle {
                visible: root.scanning
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: Colors.grey800

                Rectangle {
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: Colors.grey500
                }
                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                    spacing: 8
                    Text {
                        text: ""
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: Colors.grey400
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Pair with PIN..."
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: Colors.grey400
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Process {
                    id: bluetoothctlProc
                    command: ["ghostty", "--title=bluetoothctl", "-e", "bluetoothctl"]
                    running: false
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        bluetoothctlProc.running = true
                        SessionState.bluetoothPopupVisible = false
                    }
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // ── Unpaired scan results ─────────────────────
            Item {
                visible: root.scanning
                width: parent.width
                height: visible ? root.maxListHeight : 0

                Flickable {
                    id: unpairedFlickable
                    anchors.fill: parent
                    contentHeight: unpairedColumn.implicitHeight
                    clip: true
                    interactive: contentHeight > height

                    Column {
                        id: unpairedColumn
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: Bluetooth.devices
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool show: !modelData.paired
                                    && !root.isMacAddress(modelData.name)
                                    && modelData.name.trim() !== ""
                                visible: show
                                width: unpairedColumn.width
                                height: show ? 34 : 0
                                radius: 6
                                color: modelData.pairing ? Colors.yellow600 : Colors.grey800

                                Rectangle {
                                    visible: !modelData.pairing
                                    width: 3; height: parent.height - 10; radius: 2
                                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                    color: Colors.yellow600
                                }
                                Row {
                                    anchors {
                                        left: parent.left; verticalCenter: parent.verticalCenter
                                        leftMargin: 14; right: parent.right; rightMargin: 10
                                    }
                                    spacing: 8
                                    Text {
                                        text: modelData.pairing ? "" : ""
                                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                                        color: modelData.pairing ? Colors.grey900 : Colors.grey200
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                                        color: modelData.pairing ? Colors.grey900 : Colors.grey200
                                        elide: Text.ElideRight
                                        width: parent.width - 23 - 8
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    onEntered: if (!modelData.pairing) parent.opacity = 0.8
                                    onExited: parent.opacity = 1.0
                                    onClicked: if (!modelData.pairing) modelData.pair()
                                }
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                    }
                }

                // Scroll up hint — overlay
                Rectangle {
                    visible: !unpairedFlickable.atYBeginning
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 22; radius: 6
                    color: Colors.grey800

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰁞"
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey500
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "scroll for more"
                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey500
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Scroll down hint — overlay
                Rectangle {
                    visible: !unpairedFlickable.atYEnd
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 22; radius: 6
                    color: Colors.grey800

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰁆"
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey500
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "scroll for more"
                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey500
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
