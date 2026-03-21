import QtQuick
import Quickshell
import "../theme"

Row {
    spacing: 6

    Rectangle {
        id: launcher
        width: 28; height: 28; radius: 5
        color: PanelColors.launcher
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.centerIn: parent
            // text: ""
            text: ""
            font.pixelSize: 16
            color: Colors.white
            font.family: "JetBrainsMono Nerd Font"
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: launcher.opacity = 0.8
            onExited:  launcher.opacity = 1.0
            onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    WorkspaceBar {
        anchors.verticalCenter: parent.verticalCenter
    }
}
