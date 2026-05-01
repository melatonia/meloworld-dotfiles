pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property bool visible: false
    function show()   { visible = true  }
    function hide()   { visible = false }
    function toggle() { visible ? hide() : show() }
}
