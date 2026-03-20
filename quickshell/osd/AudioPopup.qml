import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root
    visible: AudioState.popupVisible
    implicitWidth: 300
    implicitHeight: popupColumn.implicitHeight + 20
    Behavior on implicitHeight { NumberAnimation { duration: 10 } }
    Component.onCompleted: console.log("height:", popupColumn.implicitHeight)
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.grey900
        border.color: Colors.grey800
        border.width: 2

        Column {
            id: popupColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 10
            }
            spacing: 0

            property bool outputExpanded: true
            property bool inputExpanded: true

            // ── Output Device header ──────────────────────
            Rectangle {
                width: parent.width
                height: 36
                radius: 6
                color: Colors.grey800

                Row {
                    enabled: false
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 8
                    }
                    spacing: 6

                    Text {
                        text: popupColumn.outputExpanded ? "▲" : "▼"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.purple200
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Output Device"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.purple200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: popupColumn.outputExpanded = !popupColumn.outputExpanded
                }
            }

            // ── Output device list ────────────────────────
            Column {
                visible: popupColumn.outputExpanded
                width: parent.width
                spacing: 2
                topPadding: 2
                bottomPadding: 2

                Repeater {
                    model: AudioState.sinks
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 32
                        radius: 4
                        color: modelData.name === AudioState.defaultSink
                            ? Colors.purple200 : Colors.grey700

                        Text {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8
                            }
                            text: modelData.description
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            color: modelData.name === AudioState.defaultSink
                                ? Colors.grey900 : Colors.purple200
                            elide: Text.ElideRight
                            width: parent.width - 16
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
            }

            Item { width: 1; height: 6 }

            // ── Input Device header ───────────────────────
            Rectangle {
                width: parent.width
                height: 36
                radius: 6
                color: Colors.grey800

                Row {
                    enabled: false
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 8
                    }
                    spacing: 6

                    Text {
                        text: popupColumn.inputExpanded ? "▲" : "▼"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.lightBlue200
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Input Device"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.lightBlue200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: popupColumn.inputExpanded = !popupColumn.inputExpanded
                }
            }

            // ── Input device list ─────────────────────────
            Column {
                visible: popupColumn.inputExpanded
                width: parent.width
                spacing: 2
                topPadding: 2
                bottomPadding: 2

                Repeater {
                    model: AudioState.sources
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 32
                        radius: 4
                        color: modelData.name === AudioState.defaultSource
                            ? Colors.lightBlue200 : Colors.grey700

                        Text {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8
                            }
                            text: modelData.description
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            color: modelData.name === AudioState.defaultSource
                                ? Colors.grey900 : Colors.lightBlue200
                            elide: Text.ElideRight
                            width: parent.width - 16
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
            }

            Item { width: 1; height: 10 }

            // ── Volume slider ─────────────────────────────
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: "󰕾"
                    font.pixelSize: 16
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.purple200
                    anchors.verticalCenter: parent.verticalCenter
                }

                AudioSlider {
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.volume
                    accentColor: Colors.purple200
                    onMoved: (v) => AudioState.setVolume(v)
                }
            }

            Item { width: 1; height: 8 }

            // ── Mic slider ────────────────────────────────
            Row {
                width: parent.width
                spacing: 8
                bottomPadding: 4

                Text {
                    text: "󰍬"
                    font.pixelSize: 16
                    font.family: "JetBrainsMono Nerd Font"
                    color: Colors.lightBlue200
                    anchors.verticalCenter: parent.verticalCenter
                }

                AudioSlider {
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.micVolume
                    accentColor: Colors.lightBlue200
                    onMoved: (v) => AudioState.setMicVolume(v)
                }
            }
        }
    }
}
