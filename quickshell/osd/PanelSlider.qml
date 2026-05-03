import QtQuick
import "../theme"

Item {
    id: root
    
    // ── Public API ────────────────────────────────
    property real value: 0
    property real from: 0
    property real to: 100
    property color accentColor: Colors.teal200
    
    signal moved(real value)

    // ── Layout & Accessibility ────────────────────
    implicitWidth: 120
    implicitHeight: 24
    height: implicitHeight
    
    Accessible.role: Accessible.Slider
    Accessible.name: "Value Slider"
    Accessible.value: Math.round(value) + "%"

    // ── Internal State ────────────────────────────
    property bool dragging: mouseArea.pressed
    property real internalValue: 0
    
    Timer {
        id: wheelTimer
        interval: 400
    }

    // The raw target value (optimistic during interaction)
    readonly property real targetValue: (dragging || wheelTimer.running) ? internalValue : value

    // Helper to track if we are actively interacting (drag or scroll)
    readonly property bool activeInteraction: dragging || wheelTimer.running

    // The animated value used for ALL visual components
    property real animValue: targetValue
    Behavior on animValue {
        enabled: !root.dragging
        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
    }

    // ── Internal Helpers ──────────────────────────
    function _updateFromMouse(mouseX) {
        // Calculate value based on local width for pixel-perfect alignment
        var newVal = Math.round(Math.max(root.from, Math.min(root.to,
            root.from + (mouseX / root.width) * (root.to - root.from))))
        root.internalValue = newVal
        root.moved(newVal)
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 6; radius: 3
        
        // Neo-Brutalist matte track with hover awareness
        color: mouseArea.containsMouse ? Qt.lighter(PanelColors.trackBackground, 1.1) : Qt.rgba(PanelColors.trackBackground.r, PanelColors.trackBackground.g, PanelColors.trackBackground.b, 0.4)
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: activeTrack
            width: (root.animValue - root.from) / (root.to - root.from) * root.width
            height: parent.height; radius: parent.radius
            color: mouseArea.containsMouse ? Qt.lighter(root.accentColor, 1.15) : root.accentColor
            
            // "Ghibli Soul" breathing pulse during interaction
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

    Item {
        id: handleContainer
        width: 0; height: 0
        anchors.verticalCenter: track.verticalCenter
        x: (root.animValue - root.from) / (root.to - root.from) * track.width
        
        Rectangle {
            id: handle
            anchors.centerIn: parent
            
            // Morph: Solid circle -> clean vertical needle for precision
            width: activeInteraction ? 6 : (mouseArea.containsMouse ? 18 : 14)
            height: activeInteraction ? 24 : (mouseArea.containsMouse ? 18 : 14)
            radius: width / 2
            
            color: mouseArea.containsMouse ? Qt.lighter(root.accentColor, 1.15) : root.accentColor
            
            // Whimsical "Soft-Settle" bounce
            Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on color  { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent; hoverEnabled: true

        onPressed: (mouse) => {
            root.internalValue = root.animValue // Zero-jump initialization
            root._updateFromMouse(mouse.x)
        }
        onPositionChanged: (mouse) => { if (pressed) root._updateFromMouse(mouse.x) }
        onClicked: (mouse) => root._updateFromMouse(mouse.x)

        onWheel: (wheel) => {
            // Sensitivity math: 1 notch (120 delta) = 5% of range
            var step = (root.to - root.from) / 20
            var notches = wheel.angleDelta.y / 120
            var delta = notches * step
            
            // Maintain optimistic momentum during active scrolling
            var base = (dragging || wheelTimer.running) ? root.internalValue : root.value
            var newVal = Math.round(Math.max(root.from, Math.min(root.to, base + delta)))
            
            root.internalValue = newVal
            wheelTimer.restart()
            root.moved(newVal)
        }
    }
}
