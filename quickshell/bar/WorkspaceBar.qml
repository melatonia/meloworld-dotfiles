import QtQuick
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    property var tags: ({})

    Process {
        id: watchProc
        command: ["mmsg", "-w", "-t"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var match = line.match(/\S+\s+tag\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
                if (match) {
                    var num = parseInt(match[1])
                    var focused = parseInt(match[2]) === 1
                    var clients = parseInt(match[3])
                    var newTags = Object.assign({}, root.tags)
                    newTags[num] = { focused: focused, clients: clients }
                    root.tags = newTags
                }
            }
        }
    }

    Repeater {
        model: 9
        delegate: Rectangle {
            required property int index
            property int tagNum: index + 1
            property bool focused: root.tags[tagNum] ? root.tags[tagNum].focused : false
            property int clients: root.tags[tagNum] ? root.tags[tagNum].clients : 0

            visible: focused || clients > 0
            width: visible ? 28 : 0
            height: 28
            radius: 5
            color: focused ? PanelColors.workspaceActive : PanelColors.workspaceInactive

            Text {
                anchors.centerIn: parent
                text: tagNum
                color: parent.focused ? PanelColors.pillForeground : Colors.grey400
                font.pixelSize: 16
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.opacity = 0.8
                onExited:  parent.opacity = 1.0
                onClicked: {
                    switchProc.tagTarget = parent.tagNum
                    switchProc.running = true
                }
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    Process {
        id: switchProc
        property int tagTarget: 1
        command: ["mmsg", "-s", "-t", tagTarget.toString()]
        running: false
    }
}
