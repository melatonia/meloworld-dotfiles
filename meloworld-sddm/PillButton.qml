import QtQuick

Rectangle {
    id: pill
    property string label:        ""
    property color  pillColor:    "#80cbc4"
    property color  textColor:    "#212121"
    property string fontMain:     "JetBrainsMono Nerd Font"
    property bool   disableSpace: false

    signal clicked()

    implicitHeight: 28
    implicitWidth:  pillText.implicitWidth + 16
    radius: 5
    activeFocusOnTab: true

    color: (ma.containsMouse || pill.activeFocus) ? Qt.lighter(pill.pillColor, 1.15) : pill.pillColor
    scale: (ma.containsMouse || pill.activeFocus) ? 1.03 : 1.0
    transformOrigin: Item.Center
    antialiasing: true

    border.width: pill.activeFocus ? 3 : 0
    border.color: Qt.lighter(pill.pillColor, 1.3)

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

    Text {
        id: pillText
        anchors.centerIn: parent
        text: pill.label
        font.pixelSize: 16
        font.bold: true
        font.family: pill.fontMain
        color: pill.textColor
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.clicked()
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            pill.clicked()
            event.accepted = true
        } else if (event.key === Qt.Key_Space && !pill.disableSpace) {
            pill.clicked()
            event.accepted = true
        }
    }
}