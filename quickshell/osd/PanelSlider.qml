import QtQuick
import "../theme"

Item {
    id: root

    // ── Public API ────────────────────────────────
    property real value: 0
    property real from: 0
    property real to: 100
    property color accentColor: Colors.teal200
    property bool clickable: false
    property string label: ""

    signal moved(real value)

    // ── Layout & Accessibility ────────────────────
    implicitWidth: 120
    implicitHeight: clickable ? 34 : 24
    height: implicitHeight

    Accessible.role: Accessible.Slider
    Accessible.name: "Value Slider"

    // ── Internal State ────────────────────────────
    property bool dragging: mouseArea.pressed
    property real internalValue: 0

    Timer {
        id: wheelTimer
        interval: 400
    }

    readonly property real targetValue: (dragging || wheelTimer.running) ? internalValue : value
    readonly property bool activeInteraction: dragging || wheelTimer.running
    readonly property bool hovered: mouseArea.containsMouse || mouseArea.pressed

    property real animValue: targetValue
    Behavior on animValue {
        enabled: !root.dragging
        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
    }

    // ── Background (only when clickable) ─────────
    Rectangle {
        visible: root.clickable
        anchors.fill: parent
        radius: 6
        color: PanelColors.rowBackground
    }

    // ── Internal Helpers ──────────────────────────
    function _updateFromMouse(mouseX) {
        var localX = mouseX - track.x
        var newVal = Math.round(Math.max(root.from, Math.min(root.to,
            root.from + (localX / track.width) * (root.to - root.from))))
        root.internalValue = newVal
        root.moved(newVal)
    }

    // ── Track ─────────────────────────────────────
    Rectangle {
        id: track
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: labelText.visible ? labelText.left : parent.right
            leftMargin: root.clickable ? 10 : 0
            rightMargin: root.clickable ? 8 : 0
        }
        height: 6; radius: 3

        color: root.hovered
            ? Qt.rgba(PanelColors.trackBackground.r, PanelColors.trackBackground.g, PanelColors.trackBackground.b, 0.4)
            : Qt.lighter(PanelColors.trackBackground, 1.1)
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: activeTrack
            width: (root.animValue - root.from) / (root.to - root.from) * track.width
            height: parent.height; radius: parent.radius
            color: root.hovered ? Qt.lighter(root.accentColor, 1.15) : root.accentColor

            property real pulse: 1.0
            opacity: activeInteraction ? pulse : 1.0
            SequentialAnimation on pulse {
                loops: Animation.Infinite
                running: root.activeInteraction
                NumberAnimation { to: 0.7; duration: 1000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
            }

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // ── Inline label (only when clickable and label is set) ──
    Text {
        id: labelText
        visible: root.clickable && root.label !== ""
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        text: root.label
        width: 32
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.textMain
        horizontalAlignment: Text.AlignRight
    }

    // ── Handle ────────────────────────────────────
    Item {
        id: handleContainer
        width: 0; height: 0
        anchors.verticalCenter: track.verticalCenter
        x: track.x + (root.animValue - root.from) / (root.to - root.from) * track.width

        Rectangle {
            id: handle
            anchors.centerIn: parent

            width: activeInteraction ? 6 : (root.hovered ? 18 : 14)
            height: activeInteraction ? 24 : (root.hovered ? 18 : 14)
            radius: width / 2

            color: root.hovered ? Qt.lighter(root.accentColor, 1.15) : root.accentColor

            Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on color  { ColorAnimation { duration: 150 } }
        }
    }

    // ── Input ─────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onPressed: (mouse) => {
            root.internalValue = root.animValue
            root._updateFromMouse(mouse.x)
        }
        onPositionChanged: (mouse) => { if (pressed) root._updateFromMouse(mouse.x) }
        onClicked: (mouse) => root._updateFromMouse(mouse.x)

        onWheel: (wheel) => {
            var step = (root.to - root.from) / 20
            var notches = wheel.angleDelta.y / 120
            var delta = notches * step

            var base = (dragging || wheelTimer.running) ? root.internalValue : root.value
            var newVal = Math.round(Math.max(root.from, Math.min(root.to, base + delta)))

            root.internalValue = newVal
            wheelTimer.restart()
            root.moved(newVal)
        }
    }
}
