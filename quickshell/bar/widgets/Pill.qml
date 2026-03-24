import QtQuick
import "../../theme"

Rectangle {
    id: root
    property color pillColor: PanelColors.audio
    property string label: ""
    property alias mouseArea: mouseArea

    implicitHeight: 28
    implicitWidth: pillLabel.implicitWidth + 16
    radius: 5
    color: mouseArea.containsMouse ? Qt.lighter(pillColor, 1.15) : pillColor
    scale: mouseArea.containsMouse ? 1.03 : 1.0

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
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
}
