import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root
    visible: animState !== "closed"
    implicitWidth: 300
    implicitHeight: 600
    color: "transparent"

    property string animState: "closed"

    Connections {
        target: AudioState
        function onPopupVisibleChanged() {
            if (AudioState.popupVisible) {
                animState = "open"
            } else {
                animState = "closing"
            }
        }
    }

    function shortName(desc) {
        if (!desc) return ""
        var s = desc
        var half = Math.floor(s.length / 2)
        if (s.length % 2 === 0 && s.slice(0, half) === s.slice(half + 1)) {
            s = s.slice(0, half)
        } else {
            s = s.replace(/^(.+)\s+\1$/, "$1")
        }
        s = s.replace(/\s*HD\s+Audio\b/gi, "")
        s = s.replace(/\s*Controller\b/gi, "")
        s = s.replace(/\s*Analog\s*(Stereo|Mono)?\b/gi, "")
        s = s.replace(/\s*Direct\b/gi, "")
        s = s.replace(/\s{2,}/g, " ").trim()
        return s
    }

    Rectangle {
        id: innerRect
        width: parent.width
        height: popupColumn.implicitHeight + 20
        Behavior on height {
            SmoothedAnimation { velocity: 800; easing.type: Easing.OutExpo }
        }

        y: 0
        opacity: 1.0

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: innerRect; y: 0; opacity: 1.0 }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: innerRect; y: -20; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                from: "*"; to: "open"
                SequentialAnimation {
                    PropertyAction { target: innerRect; property: "y"; value: -20 }
                    PropertyAction { target: innerRect; property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: innerRect; property: "y"
                            to: 0; duration: 250; easing.type: Easing.OutExpo
                        }
                        NumberAnimation {
                            target: innerRect; property: "opacity"
                            to: 1.0; duration: 180; easing.type: Easing.OutCubic
                        }
                    }
                }
            },
            Transition {
                from: "*"; to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: innerRect; property: "y"
                            to: -20; duration: 180; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: innerRect; property: "opacity"
                            to: 0.0; duration: 150; easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        radius: 10
        color: Colors.grey900
        border.color: Colors.teal200
        border.width: 2
        clip: true

        Column {
            id: popupColumn
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
            spacing: 4

            Item { width: 1; height: 2 }

            // ── Output header ─────────────────────────────
            Row {
                height: 34
                spacing: 6
                leftPadding: 4
                Text {
                    text: "󰕾"
                    font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Output"
                    font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.grey200
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // ── Output devices ────────────────────────────
            Repeater {
                model: AudioState.sinks
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isActive: modelData.name === AudioState.defaultSink
                    width: popupColumn.width; height: 34; radius: 6
                    color: isActive ? Colors.teal200 : Colors.grey800

                    Rectangle {
                        visible: !isActive
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: Colors.teal200
                    }
                    Text {
                        id: deviceLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                        text: root.shortName(modelData.description)
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? Colors.grey900 : Colors.grey200
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        visible: deviceLabel.truncated && deviceHover.containsMouse
                        z: 10
                        anchors { top: parent.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
                        width: tipText.implicitWidth + 16; height: 26; radius: 5
                        color: Colors.grey800
                        border.color: Colors.teal200; border.width: 1
                        Text {
                            id: tipText
                            anchors.centerIn: parent
                            text: modelData.description
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey200
                        }
                    }
                    MouseArea {
                        id: deviceHover
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: if (!parent.isActive) parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: AudioState.setDefaultSink(modelData.name)
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ── Divider ───────────────────────────────────
            Rectangle { width: popupColumn.width; height: 1; color: Colors.grey800 }

            // ── Input header ──────────────────────────────
            Row {
                height: 34
                spacing: 6
                leftPadding: 4
                Text {
                    text: "󰍬"
                    font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Input"
                    font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.grey200
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // ── Input devices ─────────────────────────────
            Repeater {
                model: AudioState.sources
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isActive: modelData.name === AudioState.defaultSource
                    width: popupColumn.width; height: 34; radius: 6
                    color: isActive ? Colors.teal200 : Colors.grey800

                    Rectangle {
                        visible: !isActive
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: Colors.teal200
                    }
                    Text {
                        id: srcLabel
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                        text: root.shortName(modelData.description)
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? Colors.grey900 : Colors.grey200
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        visible: srcLabel.truncated && srcHover.containsMouse
                        z: 10
                        anchors { top: parent.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
                        width: srcTip.implicitWidth + 16; height: 26; radius: 5
                        color: Colors.grey800
                        border.color: Colors.teal200; border.width: 1
                        Text {
                            id: srcTip
                            anchors.centerIn: parent
                            text: modelData.description
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey200
                        }
                    }
                    MouseArea {
                        id: srcHover
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: if (!parent.isActive) parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: AudioState.setDefaultSource(modelData.name)
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ── Divider ───────────────────────────────────
            Rectangle { width: popupColumn.width; height: 1; color: Colors.grey800 }
            Item { width: 1; height: 2 }

            // ── Volume slider ─────────────────────────────
            Row {
                width: parent.width; height: 28; spacing: 8
                Text {
                    text: AudioState.muted ? "󰝟" : "󰕾"
                    font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"
                    color: AudioState.muted ? Colors.grey500 : Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                }
                AudioSlider {
                    width: parent.width - 32 - 42
                    anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.volume
                    accentColor: Colors.teal200
                    onMoved: (v) => AudioState.setVolume(v)
                }
                Text {
                    width: 38
                    text: AudioState.volume + "%"
                    font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.grey400
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // ── Mic slider ────────────────────────────────
            Row {
                width: parent.width; height: 28; spacing: 8; bottomPadding: 4
                Text {
                    text: "󰍬"
                    font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                }
                AudioSlider {
                    width: parent.width - 32 - 42
                    anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.micVolume
                    accentColor: Colors.teal200
                    onMoved: (v) => AudioState.setMicVolume(v)
                }
                Text {
                    width: 38
                    text: AudioState.micVolume + "%"
                    font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                    color: Colors.grey400
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { width: 1; height: 4 }
        }
    }
}
