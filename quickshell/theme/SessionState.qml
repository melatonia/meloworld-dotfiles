pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool visible: false
    property bool powerPopupVisible: false
    property bool bluetoothPopupVisible: false
    property bool wifiPopupVisible: false
    function show() { visible = true }
    function hide() { closeAllPopups() }

    function closeAllPopups() {
        powerPopupVisible = false
        bluetoothPopupVisible = false
        wifiPopupVisible = false
        visible = false
        AudioState.hide()
    }
}
