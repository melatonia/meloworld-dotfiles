import QtQuick
import Quickshell.Bluetooth
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.bluetooth
    property var adapter: Bluetooth.defaultAdapter
    property var connectedDevices: Bluetooth.devices
    label: {
        if (!adapter || !adapter.enabled) return "󰂲"
        var connected = connectedDevices.values.filter(d => d.state === BluetoothDeviceState.Connected)
        if (connected.length === 0) return "󰂯"
        return "󰂱 " + connected[0].name.substring(0, 8)
    }
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onClicked: (mouse) => {
            SessionState.bluetoothPopupVisible = !SessionState.bluetoothPopupVisible
            mouse.accepted = false
        }
    }
}
