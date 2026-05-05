import QtQuick
import "../theme"

Item {
    id: root
    property real value: 0
    property color color: PanelColors.audio
    property string icon: ""
    property string label: ""

    implicitWidth: 80
    implicitHeight: 100

    Canvas {
        id: canvas
        width: parent.width; height: 80
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            
            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(width, height) / 2 - 8
            
            // Track
            ctx.strokeStyle = PanelColors.popupBackground
            ctx.lineWidth = 6
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
            ctx.stroke()
            
            // Progress
            ctx.strokeStyle = root.color
            ctx.lineWidth = 8
            ctx.lineCap = "round"
            ctx.beginPath()
            var startAngle = -Math.PI / 2
            var endAngle = startAngle + (2 * Math.PI * (root.value / 100))
            ctx.arc(centerX, centerY, radius, startAngle, endAngle)
            ctx.stroke()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    onValueChanged: canvas.requestPaint()

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 20
        spacing: -4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            // FIXED: Smaller icons as requested
            font.pixelSize: 20
            font.family: "JetBrainsMono Nerd Font"
            color: root.color
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.value) + "%"
            font.pixelSize: 12
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: PanelColors.textAccent
        }
    }

    Text {
        anchors {
            top: canvas.bottom
            topMargin: -2
            horizontalCenter: parent.horizontalCenter
        }
        text: root.label
        font.pixelSize: 12
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.textDim
    }
}
