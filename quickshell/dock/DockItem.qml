import QtQuick
import Quickshell
import "../theme"

Rectangle {
    id: root
    required property var modelData

    width: 44
    height: 44
    radius: 8
    color: hoverArea.containsMouse ? Colors.grey800 : "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Image {
        anchors.centerIn: parent
        width: 36
        height: 36
        source: Quickshell.iconPath(root.modelData.icon, "application-x-executable")
        fillMode: Image.PreserveAspectFit
    }

    // Tooltip
    Rectangle {
        id: tooltip
        anchors {
            bottom: root.top
            bottomMargin: 10
            horizontalCenter: root.horizontalCenter
        }
        width: tipText.implicitWidth + 16
        height: 26
        radius: 8
        color: Colors.grey900
        border.color: Colors.grey800
        border.width: 3
        z: 999

        visible: opacity > 0
        opacity: hoverArea.containsMouse ? 1.0 : 0.0

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: 300 }
                NumberAnimation { duration: 150 }
            }
        }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: root.modelData.name
            font.pixelSize: 12
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: Colors.grey100
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            Quickshell.execDetached(root.modelData.command)
        }
    }
}
