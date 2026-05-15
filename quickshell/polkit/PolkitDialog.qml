import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "../theme"

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    screen: Quickshell.screens[0]

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    PolkitAgent { id: agent }

    Connections {
        target: agent
        function onAuthenticationRequestStarted() {
            root.visible = true
            passField.text = ""
            passField.forceActiveFocus()
        }
        function onFlowChanged() {
            if (!agent.flow) {
                root.visible = false
                passField.text = ""
            }
        }
    }

    Connections {
        target: agent.flow
        function onAuthenticationFailed() {
            passField.text = ""
            passField.forceActiveFocus()
        }
        function onIsResponseRequiredChanged() {
            if (agent.flow?.isResponseRequired)
                passField.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
    }

    Rectangle {
        anchors.centerIn: parent
        width: 360
        height: contentCol.implicitHeight + 32
        radius: 10
        color: PanelColors.popupBackground
        border.color: PanelColors.border
        border.width: 1

        Column {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 10

            Row {
                width: parent.width
                spacing: 10

                Rectangle {
                    width: 32; height: 32; radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: PanelColors.rowBackground
                    Text {
                        anchors.centerIn: parent
                        text: "󰌾"
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.session
                    }
                }

                Text {
                    width: parent.width - 42
                    anchors.verticalCenter: parent.verticalCenter
                    text: agent.flow?.message ?? ""
                    color: PanelColors.textMain
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                width: parent.width
                text: agent.flow?.actionId ?? ""
                color: PanelColors.textDim
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
                elide: Text.ElideRight
            }

            Text {
                visible: (agent.flow?.supplementaryMessage ?? "") !== ""
                width: parent.width
                text: agent.flow?.supplementaryMessage ?? ""
                color: (agent.flow?.supplementaryIsError ?? false)
                    ? PanelColors.error : PanelColors.textDim
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 6
                color: passField.activeFocus
                    ? Qt.lighter(PanelColors.rowBackground, 1.15)
                    : PanelColors.rowBackground
                border.color: passField.activeFocus ? PanelColors.session : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    anchors {
                        left: parent.left; leftMargin: 12
                        right: parent.right; rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: agent.flow?.inputPrompt ?? "Password:"
                        color: PanelColors.textDim
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    TextInput {
                        id: passField
                        width: parent.width - parent.spacing - 80
                        height: 34
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: (agent.flow?.responseVisible ?? false)
                            ? TextInput.Normal : TextInput.Password
                        color: PanelColors.textMain
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        focus: true

                        onAccepted: {
                            if (agent.flow?.isResponseRequired) {
                                agent.flow.submit(passField.text)
                                passField.text = ""
                            }
                        }

                        Keys.onEscapePressed: agent.flow?.cancelAuthenticationRequest()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: passField.forceActiveFocus()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "↵ authenticate   esc cancel"
                color: PanelColors.textDim
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
            }
        }
    }
}
