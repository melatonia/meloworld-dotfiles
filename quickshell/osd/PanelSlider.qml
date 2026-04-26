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
    property real internalValue: 0

    // The raw target value (either from system or user drag)
    readonly property real targetValue: dragging ? internalValue : value

    // The animated value used for ALL visual components
    property real animValue: targetValue
    Behavior on animValue {
        enabled: !root.dragging
        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: dragging ? 8 : 6
        radius: height / 2
        color: PanelColors.trackBackground
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        Rectangle {
            width: (root.animValue - root.from) / (root.to - root.from) * parent.width
            height: parent.height
            radius: height / 2
            color: root.accentColor
        }
    }

    Rectangle {
        id: handle
        width: dragging ? 22 : 16
        height: dragging ? 22 : 16
        radius: width / 2
        color: root.accentColor
        anchors.verticalCenter: track.verticalCenter
        x: (root.animValue - root.from) / (root.to - root.from) * (track.width) - (width / 2)
        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onPressed: root.internalValue = root.value
        onPositionChanged: (mouse) => {
            if (pressed) {
                var newVal = Math.round(Math.max(root.from, Math.min(root.to,
                    root.from + (mouse.x / width) * (root.to - root.from))))
                root.internalValue = newVal
                root.moved(newVal)
            }
        }
        onClicked: (mouse) => {
            var newVal = Math.round(Math.max(root.from, Math.min(root.to,
                root.from + (mouse.x / width) * (root.to - root.from))))
            root.internalValue = newVal
            root.moved(newVal)
        }
        onWheel: (wheel) => {
            var step = (root.to - root.from) / 20 // 5% steps
            var delta = wheel.angleDelta.y > 0 ? step : -step
            var newVal = Math.round(Math.max(root.from, Math.min(root.to, root.value + delta)))
            root.moved(newVal)
        }
    }
}
