import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root

    readonly property bool wifiEnabled: NetworkState.wifiEnabled
    readonly property bool connected: NetworkState.connected
    readonly property string ssid: NetworkState.activeSSID
    readonly property int signal: NetworkState.activeSignal

    function getIcon() {
        if (!wifiEnabled) return "󰤭"
        if (!connected) return "󰤯"
        
        if (signal >= 80) return "󰤨"
        if (signal >= 60) return "󰤥"
        if (signal >= 40) return "󰤢"
        if (signal >= 20) return "󰤟"
        return "󰤯"
    }

    label: {
        var ico = getIcon()
        if (!wifiEnabled && !NetworkState.ethernetConnected) return ico + " Off"
        if (NetworkState.ethernetConnected) return "󰈀 ETH"
        if (!connected) return ico + " Dis"
        
        var shortSSID = ssid.length > 8 ? ssid.substring(0, 8) + ".." : ssid
        return ico + " " + shortSSID
    }

    pillColor: (connected || NetworkState.ethernetConnected) ? PanelColors.network : PanelColors.rowBackground
    textColor: (connected || NetworkState.ethernetConnected) ? PanelColors.pillForeground : PanelColors.textMain

    mouseArea.onClicked: function(mouse) {
        if (SessionState.wifiPopupVisible) {
            SessionState.wifiPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.wifiPopupVisible = true
        }
        mouse.accepted = false
    }
}
