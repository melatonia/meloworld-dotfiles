pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Popups managed here are those without a dedicated singleton.
    // Audio, brightness, tray, and calendar are owned by their own singletons.
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
        BrightnessState.hide()
        TrayState.hide()
        CalendarState.hide()
    }
}
