import QtQuick
import "../theme"

Item {
    id: root
    property color accent: PanelColors.launcher
    default property alias content: container.data

    width: parent ? parent.width : 0
    implicitHeight: container.implicitHeight

    Column {
        id: container
        width: parent.width
        spacing: 10
    }
}
