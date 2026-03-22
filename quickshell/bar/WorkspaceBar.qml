import QtQuick
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    property var tags: ({})

    // Find the currently focused tag number
    function focusedTag() {
        for (var i = 1; i <= 9; i++) {
            if (tags[i] && tags[i].focused) return i
        }
        return 1
    }

    // Get sorted list of visible tag numbers
    function visibleTags() {
        var result = []
        for (var i = 1; i <= 9; i++) {
            if (tags[i] && (tags[i].focused || tags[i].clients > 0)) result.push(i)
        }
        return result
    }

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
            property bool shouldShow: focused || clients > 0

            visible: width > 0
            width: shouldShow ? 28 : 0
            Behavior on width {
                SmoothedAnimation { velocity: 120; easing.type: Easing.OutExpo }
            }

            height: 28
            radius: 5
            color: focused ? PanelColors.workspaceActive : PanelColors.workspaceInactive
            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            clip: true

            Text {
                anchors.centerIn: parent
                text: tagNum
                color: parent.focused ? PanelColors.pillForeground : Colors.grey400
                font.pixelSize: 16
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
                onClicked: {
                    switchProc.tagTarget = parent.tagNum
                    switchProc.running = true
                }
                onWheel: (event) => {
                    var visible = root.visibleTags()
                    if (visible.length === 0) return
                    var current = root.focusedTag()
                    var idx = visible.indexOf(current)
                    // scroll down → next tag (higher number)
                    // scroll up → previous tag (lower number)
                    if (event.angleDelta.y < 0) {
                        idx = Math.min(idx + 1, visible.length - 1)
                    } else {
                        idx = Math.max(idx - 1, 0)
                    }
                    switchProc.tagTarget = visible[idx]
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
