pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    property bool visible: false
    property var activeItem: null   // the SystemTrayItem whose menu is open
    property int popupX: 0
    property int popupY: 0

    function show(item, x, y) {
        activeItem = item
        popupX = x
        popupY = y
        visible = true
    }

    function hide() {
        visible = false
        activeItem = null
    }
}
