import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../theme"

PopupBase {
    id: root
    implicitWidth:  240
    borderColor:    root.btOn ? PanelColors.bluetooth : PanelColors.border
    clipContent:    true
    contentHeight:  column.implicitHeight

    Connections {
        target: SessionState
        function onBluetoothPopupVisibleChanged() {
            root.animState = SessionState.bluetoothPopupVisible ? "open" : "closing"
        }
    }

    readonly property bool btOn:          Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
    readonly property bool scanning:      btOn && Bluetooth.defaultAdapter.discovering
    readonly property int  maxListHeight: 5 * 34 + 4 * 4

    // ── Shared animation component ─────────────────────────────────────
    component SpinnerIcon: Text {
        id: spinnerIcon
        required property bool active
        font.pixelSize: 15
        font.family:    "JetBrainsMono Nerd Font"
        SequentialAnimation on opacity {
            running:  spinnerIcon.active
            loops:    Animation.Infinite
            NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
        onActiveChanged: if (!active) opacity = 1.0
    }

    // ── Shared row button component ────────────────────────────────────
    // accent: active fill color | active: filled vs outlined state
    component RowButton: Rectangle {
        id: btn
        required property color accent
        required property bool  active
        required property bool  busy        // spinner / in-progress state
        property alias  label:  labelText.text
        property alias  icon:   iconText.text

        width: parent.width; height: 34; radius: 6
        color: {
            let base = btn.active ? btn.accent : PanelColors.rowBackground
            return btnMouse.containsMouse && !btn.active && !btn.busy
                ? Qt.lighter(base, 1.15) : base
        }
        Behavior on color { ColorAnimation { duration: 150 } }

        // Left accent bar (shown when inactive)
        Rectangle {
            visible: !btn.active
            width: 3; height: parent.height - 10; radius: 2
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            color: btn.accent
        }

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
            spacing: 8

            SpinnerIcon {
                id: iconText
                active: btn.busy
                color:  btn.active ? PanelColors.pillForeground : PanelColors.textMain
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: labelText
                font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                color: btn.active ? PanelColors.pillForeground : PanelColors.textMain
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        property alias mouseArea: btnMouse
        MouseArea {
            id: btnMouse
            anchors.fill: parent; hoverEnabled: true
        }
    }

    // ── Content ────────────────────────────────────────────────────────
    Column {
        id: column
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
        spacing: 4

        // ── Adapter toggle ─────────────────────────────────────────────
        RowButton {
            accent: PanelColors.bluetooth
            active: root.btOn
            busy:   false
            icon:   root.btOn ? "󰂯" : "󰂲"
            label:  root.btOn ? "Bluetooth On" : "Bluetooth Off"
            mouseArea.onClicked: {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
        }

        // ── Paired devices ─────────────────────────────────────────────
        Repeater {
            model: Bluetooth.devices
            delegate: Item {
                required property var modelData
                visible: modelData.paired
                width:   parent.width
                height:  visible ? 34 : 0

                readonly property bool isConnected:    modelData.state === BluetoothDeviceState.Connected
                readonly property bool isConnecting:   modelData.state === BluetoothDeviceState.Connecting
                readonly property bool isDisconnecting: modelData.state === BluetoothDeviceState.Disconnecting
                readonly property bool isTransitioning: isConnecting || isDisconnecting

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: {
                        let base = isConnected ? PanelColors.bluetooth : PanelColors.rowBackground
                        return pairedMouse.containsMouse && !isConnected && !isTransitioning
                            ? Qt.lighter(base, 1.15) : base
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    // Left accent bar (shown when disconnected)
                    Rectangle {
                        visible: !isConnected
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: PanelColors.bluetooth
                    }

                    Row {
                        anchors {
                            left: parent.left; verticalCenter: parent.verticalCenter
                            leftMargin: 14; right: parent.right; rightMargin: 10
                        }
                        spacing: 8

                        // Icon — spins while connecting / disconnecting
                        SpinnerIcon {
                            active: isTransitioning
                            text: {
                                if (isConnected)     return "󰂱"
                                if (isTransitioning) return "󰑐"
                                return "󰂯"
                            }
                            color: isConnected ? PanelColors.pillForeground : PanelColors.textMain
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: isConnected ? PanelColors.pillForeground : PanelColors.textMain
                            elide: Text.ElideRight
                            width: parent.width - 23 - 8
                                   - (isConnected && modelData.batteryAvailable ? 36 : 0)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: isConnected && modelData.batteryAvailable
                            text:    visible ? Math.round(modelData.battery * 100) + "%" : ""
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.pillForeground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: pairedMouse
                        anchors.fill: parent; hoverEnabled: true
                        // Guard against clicks during transitioning states
                        onClicked: {
                            if (isTransitioning) return
                            if (isConnected) modelData.disconnect()
                            else             modelData.connect()
                        }
                    }
                }
            }
        }

        // ── Divider ────────────────────────────────────────────────────
        Rectangle {
            visible: root.btOn
            width: parent.width; height: visible ? 2 : 0
            color: PanelColors.rowBackground
        }

        // ── Scan toggle ────────────────────────────────────────────────
        RowButton {
            visible: root.btOn
            height:  visible ? 34 : 0
            accent:  PanelColors.scanning
            active:  root.scanning
            busy:    root.scanning
            icon:    "󰑐"
            label:   root.scanning ? "Scanning..." : "Scan"
            mouseArea.onClicked: {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
            }
        }

        // ── Pair with PIN ──────────────────────────────────────────────
        Rectangle {
            visible: root.scanning
            width: parent.width; height: visible ? 34 : 0; radius: 6
            color: pinMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 3; height: parent.height - 10; radius: 2
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                color: PanelColors.textDim
            }

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                spacing: 8
                Text {
                    text: "󰌆"
                    font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Pair with PIN..."
                    font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Process {
                id: bluetoothctlProc
                command: ["kitty", "--title=bluetoothctl", "-e", "bluetoothctl"]
                running: false
            }

            MouseArea {
                id: pinMouse
                anchors.fill: parent; hoverEnabled: true
                onClicked: {
                    bluetoothctlProc.running = true
                    SessionState.bluetoothPopupVisible = false
                }
            }
        }

        // ── Unpaired scan results ──────────────────────────────────────
        Item {
            visible: root.scanning
            width:   parent.width
            height:  visible ? root.maxListHeight : 0

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
                        delegate: Item {
                            required property var modelData
                            readonly property bool show: !modelData.paired
                                && modelData.name.trim() !== ""
                                && !/^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$/.test(modelData.name.trim())

                            visible: show
                            width:   unpairedColumn.width
                            height:  show ? 34 : 0

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: {
                                    let base = modelData.pairing ? PanelColors.pairing : PanelColors.rowBackground
                                    return unpMouse.containsMouse && !modelData.pairing
                                        ? Qt.lighter(base, 1.15) : base
                                }
                                Behavior on color { ColorAnimation { duration: 150 } }

                                // Left accent bar
                                Rectangle {
                                    visible: !modelData.pairing
                                    width: 3; height: parent.height - 10; radius: 2
                                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                    color: PanelColors.pairing
                                }

                                Row {
                                    anchors {
                                        left: parent.left; verticalCenter: parent.verticalCenter
                                        leftMargin: 14; right: parent.right; rightMargin: 10
                                    }
                                    spacing: 8

                                    SpinnerIcon {
                                        active: modelData.pairing
                                        text:   modelData.pairing ? "󰑐" : "󰂯"
                                        color:  modelData.pairing ? PanelColors.pillForeground : PanelColors.textMain
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                                        color: modelData.pairing ? PanelColors.pillForeground : PanelColors.textMain
                                        elide: Text.ElideRight
                                        width: parent.width - 23 - 8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: unpMouse
                                    anchors.fill: parent; hoverEnabled: true
                                    onClicked: if (!modelData.pairing) modelData.pair()
                                }
                            }
                        }
                    }
                }
            }

            // ── Scroll hints ───────────────────────────────────────────
            Rectangle {
                visible: !unpairedFlickable.atYBeginning
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 22; radius: 6
                color: PanelColors.rowBackground
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: "󰁞"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "scroll up"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Rectangle {
                visible: !unpairedFlickable.atYEnd
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 22; radius: 6
                color: PanelColors.rowBackground
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: "󰁆"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "scroll for more"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
