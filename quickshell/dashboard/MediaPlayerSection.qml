import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

SectionBase {
    id: root
    title: "Media Player"
    icon: "󰕾"
    accent: PanelColors.audio
    
    property var activePlayer: null
    
    function updatePlayer() {
        for (let i = 0; i < Mpris.players.length; i++) {
            const p = Mpris.players[i];
            if (p && p.playbackState === MprisPlaybackState.Playing) {
                activePlayer = p;
                return;
            }
        }
        activePlayer = Mpris.players.length > 0 ? Mpris.players[0] : null;
    }

    // FIXED: Use Mpris.players and onCountChanged which is the correct signal for ServiceList
    Connections {
        target: Mpris.players
        function onCountChanged() { root.updatePlayer() }
    }
    
    Component.onCompleted: updatePlayer()
    
    visible: true

    Column {
        width: parent.width
        spacing: 12
        visible: root.activePlayer !== null

        Row {
            width: parent.width
            spacing: 12

            // Artwork
            Rectangle {
                width: 72; height: 72
                radius: 8
                color: PanelColors.rowBackground
                border.color: root.accent
                border.width: 1
                clip: true

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: root.activePlayer && root.activePlayer.metadata["mpris:artUrl"] ? root.activePlayer.metadata["mpris:artUrl"] : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    visible: artImage.status !== Image.Ready
                    anchors.centerIn: parent
                    text: "󰎆"
                    font.pixelSize: 28
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                }
            }

            Column {
                width: parent.width - 84
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Column {
                    width: parent.width
                    spacing: 0
                    Text {
                        width: parent.width
                        text: root.activePlayer ? root.activePlayer.metadata["xesam:title"] || "No Title" : ""
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textAccent
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.activePlayer ? (root.activePlayer.metadata["xesam:artist"] ? root.activePlayer.metadata["xesam:artist"].join(", ") : "Unknown Artist") : ""
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textDim
                        elide: Text.ElideRight
                    }
                }

                Row {
                    spacing: 16
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: "󰒮"
                        font.pixelSize: 18
                        font.family: "JetBrainsMono Nerd Font"
                        color: prevMouse.containsMouse ? root.accent : PanelColors.textAccent
                        MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.activePlayer.previous() }
                    }

                    Text {
                        text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                        font.pixelSize: 22
                        font.family: "JetBrainsMono Nerd Font"
                        color: playMouse.containsMouse ? root.accent : PanelColors.textAccent
                        MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.activePlayer.playPause() }
                    }

                    Text {
                        text: "󰒭"
                        font.pixelSize: 18
                        font.family: "JetBrainsMono Nerd Font"
                        color: nextMouse.containsMouse ? root.accent : PanelColors.textAccent
                        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.activePlayer.next() }
                    }
                }
            }
        }
    }
    
    Text {
        visible: root.activePlayer === null
        width: parent.width
        text: "No active media session"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.textDim
        horizontalAlignment: Text.AlignHCenter
        topPadding: 10
        bottomPadding: 10
    }
}
