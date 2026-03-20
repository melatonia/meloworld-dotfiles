import QtQuick
import "../theme"

Item {
    id: root
    height: 20
    property real value: 0
    property real from: 0
    property real to: 100
    property color accentColor: Colors.purple200

    signal moved(real value)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Colors.grey700

        Rectangle {
            width: (root.value - root.from) / (root.to - root.from) * parent.width
            height: parent.height
            radius: 2
            color: root.accentColor

            Behavior on width { NumberAnimation { duration: 80 } }
        }
    }

    Rectangle {
        id: handle
        width: 14
        height: 14
        radius: 7
        color: root.accentColor
        anchors.verticalCenter: track.verticalCenter
        x: (root.value - root.from) / (root.to - root.from) * (track.width - width)

        Behavior on x { NumberAnimation { duration: 80 } }
    }

    MouseArea {
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
