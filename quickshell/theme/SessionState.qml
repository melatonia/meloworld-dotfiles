pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool visible: false
    property bool powerPopupVisible: false
    property bool bluetoothPopupVisible: false
    property bool wifiPopupVisible: false
    property bool trayBarVisible: false
    property bool calendarVisible: false
    function show() { visible = true }
    function hide() { closeAllPopups() }

    function closeAllPopups() {
        powerPopupVisible = false
        bluetoothPopupVisible = false
        wifiPopupVisible = false
        trayBarVisible = false
        calendarVisible = false
        visible = false
        AudioState.hide()
        BrightnessState.hide()
        TrayState.hide()
        CalendarState.hide()
    }
}
