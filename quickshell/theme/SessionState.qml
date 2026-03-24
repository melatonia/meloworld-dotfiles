pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool visible: false
    property bool powerPopupVisible: false
    property bool bluetoothPopupVisible: false
    function show() { visible = true }
    function hide() { visible = false }

    function closeAllPopups() {
        powerPopupVisible = false
        bluetoothPopupVisible = false
        visible = false
        AudioState.hide()
    }
}
