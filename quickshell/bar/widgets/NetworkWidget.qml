import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    hoverReveal: true
    forceReveal: SessionState.wifiPopupVisible

    readonly property bool wifiEnabled: NetworkState.wifiEnabled
    readonly property bool connected: NetworkState.connected
    readonly property string ssid: NetworkState.activeSSID
    readonly property int signal: NetworkState.activeSignal

    readonly property string iconText: {
        if (!wifiEnabled) return "󰤭"
        if (!connected) return "󰤯"
        
        if (signal >= 80) return "󰤨"
        if (signal >= 60) return "󰤥"
        if (signal >= 40) return "󰤢"
        if (signal >= 20) return "󰤟"
        return "󰤯"
    }

    label: {
        if (!wifiEnabled && !NetworkState.ethernetConnected) return iconText + " Off"
        if (NetworkState.ethernetConnected) return "󰈀 ETH"
        if (!connected) return iconText + " Dis"
        
        var shortSSID = ssid.length > 8 ? ssid.substring(0, 8) + ".." : ssid
        return iconText + " " + shortSSID
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
