import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root
    visible: AudioState.popupVisible

    implicitWidth: 280
    implicitHeight: popupContent.implicitHeight + 20

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.grey900

        Column {
            id: popupContent
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 10
            }
            spacing: 6

            // Output devices
            Text {
                text: "󰕾  Output"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.grey400
                topPadding: 4
            }

            Repeater {
                model: AudioState.sinks
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 36
                    radius: 6
                    color: modelData.name === AudioState.defaultSink
                        ? Colors.purple200
                        : Colors.grey800

                    Text {
                        anchors.centerIn: parent
                        text: modelData.description
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: modelData.name === AudioState.defaultSink
                            ? Colors.grey900
                            : Colors.white
                        elide: Text.ElideRight
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: AudioState.setDefaultSink(modelData.name)
                    }
                }
            }

            // Input devices
            Text {
                text: "󰍬  Input"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.grey400
                topPadding: 4
            }

            Repeater {
                model: AudioState.sources
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 36
                    radius: 6
                    color: modelData.name === AudioState.defaultSource
                        ? Colors.purple200
                        : Colors.grey800

                    Text {
                        anchors.centerIn: parent
                        text: modelData.description
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: modelData.name === AudioState.defaultSource
                            ? Colors.grey900
                            : Colors.white
                        elide: Text.ElideRight
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: AudioState.setDefaultSource(modelData.name)
                    }
                }
            }
        }
    }
}
