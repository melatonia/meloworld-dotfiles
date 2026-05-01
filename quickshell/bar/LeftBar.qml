import QtQuick
import Quickshell
import "../theme"

Row {
    spacing: 6

    Rectangle {
        id: launcher
        width: 28; height: 28; radius: 5
        color: lmouseArea.containsMouse ? Qt.lighter(PanelColors.launcher, 1.15) : PanelColors.launcher
        scale: lmouseArea.containsMouse ? 1.03 : 1.0
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

        Text {
            anchors.centerIn: parent
            text: ""
            font.pixelSize: 16
            color: PanelColors.textAccent
            font.family: "JetBrainsMono Nerd Font"
        }
        MouseArea {
            id: lmouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Quickshell.execDetached(["rofi", "-show", "drun"])
            }
        }
    }

    WorkspaceBar {
        anchors.verticalCenter: parent.verticalCenter
    }
}
