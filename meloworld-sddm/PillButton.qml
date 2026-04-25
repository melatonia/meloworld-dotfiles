import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: pill
    property string label:     ""
    property color  pillColor: "#80cbc4"
    property string fontMain:  "JetBrainsMono Nerd Font"
    property int    radiusSmall: 5
    property color  clrPillFg: "#212121"
    
    signal clicked()

    implicitHeight: 28
    implicitWidth:  pillText.implicitWidth + 16
    radius: radiusSmall
    color: (ma.containsMouse || pill.activeFocus) ? Qt.lighter(pillColor, 1.15) : pillColor
    scale: (ma.containsMouse || pill.activeFocus) ? 1.03 : 1.0
    border.width: pill.activeFocus ? 2 : 0
    border.color: pill.clrPillFg

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

    Text {
        id: pillText
        anchors.centerIn: parent
        text: pill.label
        font.pixelSize: 16
        font.bold: true
        font.family: pill.fontMain
        color: pill.clrPillFg
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.clicked()
    }
}
