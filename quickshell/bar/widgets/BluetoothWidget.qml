import QtQuick
import Quickshell.Bluetooth
import "../../theme"

Pill {
    id: root
    hoverReveal: true
    forceReveal: SessionState.bluetoothPopupVisible
    pillColor: (adapter && adapter.enabled) ? PanelColors.bluetooth : PanelColors.rowBackground
    textColor: (adapter && adapter.enabled) ? PanelColors.pillForeground : PanelColors.textMain
    property var adapter: Bluetooth.defaultAdapter
    property var connectedDevices: Bluetooth.devices
    label: {
        if (!adapter || !adapter.enabled) return "󰂲"
        if (!connectedDevices || !connectedDevices.values) return "󰂯"
        var connected = connectedDevices.values.filter(d => d.state === BluetoothDeviceState.Connected)
        if (connected.length === 0) return "󰂯"
        return "󰂱 " + connected[0].name.substring(0, 8)
    }

    mouseArea.propagateComposedEvents: true
    mouseArea.onClicked: (mouse) => {
        if (SessionState.bluetoothPopupVisible) {
            SessionState.bluetoothPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.bluetoothPopupVisible = true
        }
        mouse.accepted = false
    }
}
