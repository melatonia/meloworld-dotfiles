import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root
    visible: AudioState.popupVisible
    implicitWidth: 300
    implicitHeight: popupColumn.implicitHeight + 20
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 80
            easing.type: Easing.OutCubic
        }
    }
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.grey900
        border.color: Colors.teal200
        border.width: 2

        Column {
            id: popupColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 10
            }
            spacing: 4

            Item { width: 1; height: 2 }

            // ── Output Device header ──────────────────────
            Rectangle {
                width: parent.width
                height: 34
                radius: 6
                color: Colors.grey800

                Rectangle {
                    width: 3
                    height: parent.height - 10
                    radius: 2
                    anchors {
                        left: parent.left
                        leftMargin: 4
                        verticalCenter: parent.verticalCenter
                    }
                    color: Colors.teal200
                }

                Row {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 14
                    }
                    spacing: 6
                    Text {
                        text: "󰕾"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.teal200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Output"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ── Output device list ────────────────────────
            Repeater {
                model: AudioState.sinks
                delegate: Rectangle {
                    required property var modelData
                    width: popupColumn.width
                    height: 34
                    radius: 6
                    color: modelData.name === AudioState.defaultSink
                        ? Colors.teal200 : Colors.grey800

                    Rectangle {
                        visible: modelData.name !== AudioState.defaultSink
                        width: 3
                        height: parent.height - 10
                        radius: 2
                        anchors {
                            left: parent.left
                            leftMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        color: Colors.teal200
                    }

                    Text {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                            right: parent.right
                            rightMargin: 8
                        }
                        text: modelData.description
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: modelData.name === AudioState.defaultSink
                            ? Colors.grey900 : Colors.grey200
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: if (modelData.name !== AudioState.defaultSink) parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: AudioState.setDefaultSink(modelData.name)
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ── Input Device header ───────────────────────
            Rectangle {
                width: parent.width
                height: 34
                radius: 6
                color: Colors.grey800

                Rectangle {
                    width: 3
                    height: parent.height - 10
                    radius: 2
                    anchors {
                        left: parent.left
                        leftMargin: 4
                        verticalCenter: parent.verticalCenter
                    }
                    color: Colors.teal200
                }

                Row {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 14
                    }
                    spacing: 6
                    Text {
                        text: "󰍬"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.teal200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Input"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ── Input device list ─────────────────────────
            Repeater {
                model: AudioState.sources
                delegate: Rectangle {
                    required property var modelData
                    width: popupColumn.width
                    height: 34
                    radius: 6
                    color: modelData.name === AudioState.defaultSource
                        ? Colors.teal200 : Colors.grey800

                    Rectangle {
                        visible: modelData.name !== AudioState.defaultSource
                        width: 3
                        height: parent.height - 10
                        radius: 2
                        anchors {
                            left: parent.left
                            leftMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        color: Colors.teal200
                    }

                    Text {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                            right: parent.right
                            rightMargin: 8
                        }
                        text: modelData.description
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: modelData.name === AudioState.defaultSource
                            ? Colors.grey900 : Colors.grey200
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: if (modelData.name !== AudioState.defaultSource) parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: AudioState.setDefaultSource(modelData.name)
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            Item { width: 1; height: 6 }

            // ── Volume slider ─────────────────────────────
            Row {
                width: parent.width
                height: 28
                spacing: 8
                Text {
                    text: AudioState.muted ? "󰝟" : "󰕾"
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"
                    color: AudioState.muted ? Colors.grey500 : Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                }
                AudioSlider {
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.volume
                    accentColor: Colors.teal200
                    onMoved: (v) => AudioState.setVolume(v)
                }
            }

            // ── Mic slider ────────────────────────────────
            Row {
                width: parent.width
                height: 28
                spacing: 8
                bottomPadding: 4
                Text {
                    text: "󰍬"
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                }
                AudioSlider {
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.micVolume
                    accentColor: Colors.teal200
                    onMoved: (v) => AudioState.setMicVolume(v)
                }
            }

            Item { width: 1; height: 4 }
        }
    }
}
