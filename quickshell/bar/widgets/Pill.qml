import QtQuick
import "../../theme"

Rectangle {
    id: root
    property color pillColor: PanelColors.audio
    property color textColor: PanelColors.pillForeground
    property string label: ""
    property string widestLabel: ""
    property int minWidth: 0
    property alias mouseArea: mouseArea
    default property alias content: contentRow.data

    TextMetrics {
        id: widestMetric
        font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"
        text: root.widestLabel
    }

    property int effectiveMinWidth: Math.max(minWidth, widestLabel !== "" ? widestMetric.width + 16 : 0)

    implicitHeight: 28
    property real targetWidth: Math.max(effectiveMinWidth, contentRow.implicitWidth + 16)
    property bool isGrowing: targetWidth > width
    implicitWidth: targetWidth

    Behavior on targetWidth {
        NumberAnimation {
            duration: root.isGrowing ? 120 : 100
            easing.type: Easing.OutQuart
        }
    }

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

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Behavior on spacing { NumberAnimation { duration: 150 } }

        Text {
            id: pillLabel
            visible: root.label !== ""
            text: root.label
            font.pixelSize: 16
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: root.textColor
        }
    }
}
