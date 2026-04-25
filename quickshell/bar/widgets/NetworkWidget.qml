import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.network
    
    // Bind to the global NetworkState
    property string ssid: NetworkState.activeSSID
    property bool connected: NetworkState.connected
    property int signal: NetworkState.activeSignal
    property bool wifiEnabled: NetworkState.wifiEnabled

    label: {
        if (!wifiEnabled && !connected) return "󰤭"
        if (!connected) return "󰤭"
        if (ssid === "") return "󰈀 ETH"
        
        if (signal >= 80) return "󰤨 " + ssid.substring(0, 10)
        else if (signal >= 60) return "󰤥 " + ssid.substring(0, 10)
        else if (signal >= 40) return "󰤢 " + ssid.substring(0, 10)
        else if (signal >= 20) return "󰤟 " + ssid.substring(0, 10)
        else return "󰤯 " + ssid.substring(0, 10)
    }
    
    mouseArea.propagateComposedEvents: true
    mouseArea.onClicked: (mouse) => {
        if (SessionState.wifiPopupVisible) {
            SessionState.wifiPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            NetworkState.refresh()
            SessionState.wifiPopupVisible = true
        }
        mouse.accepted = false
    }
}
