import QtQuick
import "../theme"

Item {
    id: root
    height: 24
    property real value: 0
    property real from: 0
    property real to: 100
    property color accentColor: Colors.teal200
    signal moved(real value)

    property bool dragging: mouseArea.pressed

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: dragging ? 8 : 6
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.15)
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        Rectangle {
            width: (root.value - root.from) / (root.to - root.from) * parent.width
            height: parent.height
            radius: height / 2
            color: root.accentColor
            Behavior on width { NumberAnimation { duration: 80 } }
        }
    }

    Rectangle {
        id: handle
        property real targetX: (root.value - root.from) / (root.to - root.from) * (track.width - 16)
        width: dragging ? 22 : 16
        height: dragging ? 22 : 16
        radius: width / 2
        color: root.accentColor
        anchors.verticalCenter: track.verticalCenter
        x: targetX - (width - 16) / 2
        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 80 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPositionChanged: (mouse) => {
            if (pressed) {
                var newVal = Math.round(Math.max(root.from, Math.min(root.to,
                    root.from + (mouse.x / width) * (root.to - root.from))))
                root.value = newVal
                root.moved(newVal)
            }
        }
        onClicked: (mouse) => {
            var newVal = Math.round(Math.max(root.from, Math.min(root.to,
                root.from + (mouse.x / width) * (root.to - root.from))))
            root.value = newVal
            root.moved(newVal)
        }
    }
}
