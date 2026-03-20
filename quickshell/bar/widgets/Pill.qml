import QtQuick
import "../../theme"

Rectangle {
    id: root
    property color pillColor: PanelColors.audio
    property string label: ""

    implicitHeight: 28
    implicitWidth: pillLabel.implicitWidth + 16
    radius: 5
    color: pillColor

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.opacity = 0.85
        onExited:  root.opacity = 1.0
    }

    Text {
        id: pillLabel
        anchors.centerIn: parent
        text: root.label
        font.pixelSize: 16
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.pillForeground
    }

    Behavior on opacity { NumberAnimation { duration: 150 } }
}
