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

    // Shorten "org.freedesktop.policykit.exec" → "policykit.exec"
    readonly property string shortAction: {
        var id = agent.flow?.actionId ?? ""
        var parts = id.split(".")
        return parts.length > 2 ? parts.slice(-2).join(".") : id
    }

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
            shakeAnim.start()
            passField.text = ""
            passField.forceActiveFocus()
        }
        function onIsResponseRequiredChanged() {
            if (agent.flow?.isResponseRequired)
                passField.forceActiveFocus()
        }
    }

    // Dim overlay — #66 = ~40% opacity, lighter than before
    Rectangle {
        anchors.fill: parent
        color: "#66000000"
    }

    // Card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 380
        height: cardCol.implicitHeight + 48
        radius: 8
        color: PanelColors.popupBackground
        border.width: 4
        border.color: passField.activeFocus && !shakeAnim.running
            ? PanelColors.audio
            : PanelColors.border

        Behavior on border.color { ColorAnimation { duration: 150 } }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 0;   to: 10;  duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10;  to: -10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: -10; to: 10;  duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10;  to: 0;   duration: 50; easing.type: Easing.OutQuad }
        }

        Column {
            id: cardCol
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 14

            // Icon + message
            Row {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 36; height: 36; radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: PanelColors.rowBackground
                    Text {
                        anchors.centerIn: parent
                        text: "󰯄"
                        font.pixelSize: 18
                        font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.audio
                    }
                }

                Text {
                    width: parent.width - 48
                    anchors.verticalCenter: parent.verticalCenter
                    text: agent.flow?.message ?? ""
                    color: PanelColors.textMain
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    wrapMode: Text.WordWrap
                }
            }

            // Shortened action ID
            Text {
                width: parent.width
                text: root.shortAction
                color: PanelColors.textDim
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                elide: Text.ElideRight
            }

            // Supplementary message (wrong password, PAM messages)
            Text {
                visible: (agent.flow?.supplementaryMessage ?? "") !== ""
                width: parent.width
                text: agent.flow?.supplementaryMessage ?? ""
                color: (agent.flow?.supplementaryIsError ?? false)
                    ? PanelColors.error : PanelColors.textDim
                font.pixelSize: 12
                font.family: "JetBrainsMono Nerd Font"
                wrapMode: Text.WordWrap
            }

            // Password field
            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: PanelColors.rowBackground
                border.width: passField.activeFocus && !shakeAnim.running ? 2 : 0
                border.color: PanelColors.audio

                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    anchors {
                        left: parent.left; leftMargin: 14
                        right: parent.right; rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: agent.flow?.inputPrompt ?? "Password:"
                        color: PanelColors.textDim
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    TextInput {
                        id: passField
                        width: parent.width - parent.spacing - 90
                        height: 40
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: (agent.flow?.responseVisible ?? false)
                            ? TextInput.Normal : TextInput.Password
                        color: PanelColors.textMain
                        font.pixelSize: 14
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

            // ── Actions (Consistent with SDDM Buttons) ──────────
            Row {
                width: parent.width
                spacing: 12

                // Authenticate Button
                Rectangle {
                    id: authBtn
                    width: (parent.width / 2) - 6
                    height: 38
                    radius: 8
                    color: (authMa.containsMouse || authBtn.activeFocus)
                           ? Qt.lighter(PanelColors.audio, 1.15) : PanelColors.audio
                    scale: (authMa.containsMouse || authBtn.activeFocus) ? 1.03 : 1.0

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.popupBackground }
                        Text {
                            text: "Authenticate"
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            font.pixelSize: 13
                            color: PanelColors.popupBackground
                        }
                    }

                    MouseArea {
                        id: authMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (agent.flow?.isResponseRequired) {
                                agent.flow.submit(passField.text)
                                passField.text = ""
                            }
                        }
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                }

                // Cancel Button
                Rectangle {
                    id: cancelBtn
                    width: (parent.width / 2) - 6
                    height: 38
                    radius: 8
                    color: (cancelMa.containsMouse || cancelBtn.activeFocus)
                           ? "#4d4d4d" : PanelColors.rowBackground // Mimicking a 'dim' or 'alt' background
                    scale: (cancelMa.containsMouse || cancelBtn.activeFocus) ? 1.03 : 1.0
                    border.width: 1
                    border.color: PanelColors.border

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "esc"; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain }
                        Text {
                            text: "Cancel"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: PanelColors.textMain
                        }
                    }

                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: agent.flow?.cancelAuthenticationRequest()
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                }
            }
        }
    }
}
