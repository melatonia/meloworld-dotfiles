import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../theme"

Item {
    id: root

    property string appId:         ""
    property string appLabel:      ""
    property string iconName:      ""
    property int    instanceCount: 0

    implicitWidth:  56
    implicitHeight: 64

    HoverHandler { id: hover }

    // Hover background
    Rectangle {
        anchors.centerIn: parent
        width:  48
        height: 48
        radius: 10
        color:  hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // App icon
    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: 40
        source: Quickshell.iconPath(root.iconName)

        scale: hover.hovered ? 1.1 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            var entry = DesktopEntries.byId(root.appId)
            if (entry) {
                entry.execute()
            } else {
                Quickshell.execDetached([root.appId])
            }
        }
    }
}
