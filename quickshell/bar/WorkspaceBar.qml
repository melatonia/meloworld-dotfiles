import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Row {
    id: root
    spacing: 4

    ListModel {
        id: tagsModel
        Component.onCompleted: {
            for (let i = 1; i <= 9; i++) {
                append({ tagNum: i, focused: false, clients: 0 })
            }
        }
    }

    property var cachedVisibleTags: []
    property int cachedFocusedTag: 1

    function updateCache() {
        var visible = []
        var focused = 1
        for (var i = 0; i < tagsModel.count; i++) {
            var item = tagsModel.get(i)
            if (item.focused) focused = item.tagNum
            if (item.focused || item.clients > 0) visible.push(item.tagNum)
        }
        root.cachedVisibleTags = visible
        root.cachedFocusedTag = focused
    }

    property bool canScroll: true
    Timer {
        id: scrollThrottle
        interval: 30
        onTriggered: root.canScroll = true
    }

    Timer {
        id: watchRestartTimer
        interval: 1000
        onTriggered: watchProc.running = true
    }

    Process {
        id: watchProc
        command: ["mmsg", "-w", "-t"]
        running: true
        onRunningChanged: {
            if (!running) watchRestartTimer.start()
        }
        stdout: SplitParser {
            onRead: (line) => {
                var match = line.match(/\S+\s+tag\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
                if (match) {
                    var num     = parseInt(match[1])
                    var focused = parseInt(match[2]) === 1
                    var clients = parseInt(match[3])
                    var idx = num - 1
                    if (idx >= 0 && idx < 9) {
                        tagsModel.setProperty(idx, "focused", focused)
                        tagsModel.setProperty(idx, "clients", clients)
                    }
                    root.updateCache()
                }
            }
        }
    }

    Repeater {
        model: tagsModel
        delegate: Rectangle {
            property bool shouldShow: focused || clients > 0
            property bool hovered:    false

            visible: width > 0
            width:   shouldShow ? 28 : 0
            Behavior on width {
                SmoothedAnimation { velocity: 120; easing.type: Easing.OutExpo }
            }

            height: 28
            radius: 5
            color: {
                if (focused)  return hovered ? Qt.lighter(PanelColors.workspaceActive,   1.15) : PanelColors.workspaceActive
                return hovered ? Qt.lighter(PanelColors.workspaceInactive, 1.4)  : PanelColors.workspaceInactive
            }
            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            clip: true

            Text {
                anchors.centerIn: parent
                text:        tagNum
                color:       parent.focused ? PanelColors.pillForeground : PanelColors.textDim
                font.pixelSize: 16
                font.bold:   true
                font.family: "JetBrainsMono Nerd Font"
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            MouseArea {
                anchors.fill:  parent
                hoverEnabled:  true
                onEntered:     parent.hovered = true
                onExited:      parent.hovered = false
                onClicked: {
                    Quickshell.execDetached(["mmsg", "-s", "-t", tagNum.toString()])
                }
                onWheel: (event) => {
                    if (!root.canScroll) return
                    var visible = root.cachedVisibleTags
                    if (visible.length === 0) return
                    var current = root.cachedFocusedTag
                    var idx     = visible.indexOf(current)
                    // scroll down → next tag, scroll up → previous tag
                    if (event.angleDelta.y < 0) {
                        idx = Math.min(idx + 1, visible.length - 1)
                    } else {
                        idx = Math.max(idx - 1, 0)
                    }
                    Quickshell.execDetached(["mmsg", "-s", "-t", visible[idx].toString()])
                    root.canScroll = false
                    scrollThrottle.start()
                }
            }
        }
    }
}
