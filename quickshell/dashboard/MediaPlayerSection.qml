import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

SectionBase {
    id: root
    title: "Media Player"
    icon: "󰕾"
    accent: PanelColors.audio

    // ── Active player ─────────────────────────────────────────────────────────
    readonly property MprisPlayer activePlayer: {
        const vals = Mpris.players.values
        for (let i = 0; i < vals.length; i++) {
            if (vals[i]?.playbackState === MprisPlaybackState.Playing)
                return vals[i]
        }
        return vals.length > 0 ? vals[0] : null
    }

    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing

    // ── Position tracking ─────────────────────────────────────────────────────
    property real livePosition: activePlayer?.position ?? 0

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: { if (root.activePlayer) root.livePosition = root.activePlayer.position }
    }

    Connections {
        target: root.activePlayer
        function onTrackChanged() { root.livePosition = 0 }
    }

    function fmtTime(secs) {
        if (!secs || secs < 0) return "0:00"
        const s = Math.floor(secs)
        const m = Math.floor(s / 60)
        const rem = s % 60
        return m + ":" + (rem < 10 ? "0" + rem : rem)
    }

    // ── Empty state ───────────────────────────────────────────────────────────
    Text {
        visible: root.activePlayer === null
        width: parent.width
        text: "No active media session"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        color: PanelColors.textDim
        horizontalAlignment: Text.AlignHCenter
        topPadding: 8
        bottomPadding: 8
    }

    // ── Player UI ─────────────────────────────────────────────────────────────
    Column {
        visible: root.activePlayer !== null
        width: parent.width
        spacing: 12

        // ── Top row: art + track info ─────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 12

            // Square artwork — same style as AudioPopup device rows
            Rectangle {
                id: artBox
                width: 72; height: 72
                radius: 8
                color: PanelColors.rowBackground
                border.color: root.accent
                border.width: 1
                clip: true

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: root.activePlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Text {
                    visible: artImage.status !== Image.Ready
                    anchors.centerIn: parent
                    text: "󰎆"
                    font.pixelSize: 28
                    font.family: "Symbols Nerd Font"
                    color: PanelColors.textDim
                }
            }

            // Track info column — vertically centered against art
            Column {
                width: parent.width - artBox.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    width: parent.width
                    text: root.activePlayer?.trackTitle || "Unknown Title"
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textAccent
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.activePlayer?.trackArtist || "Unknown Artist"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                    elide: Text.ElideRight
                }

                // Player identity badge
                Rectangle {
                    visible: (root.activePlayer?.identity ?? "") !== ""
                    height: 18
                    width: badgeText.implicitWidth + 12
                    radius: 4
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
                    border.width: 1

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.activePlayer?.identity ?? ""
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        color: root.accent
                    }
                }
            }
        }

        // ── Progress bar + timestamps ─────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 4
            visible: root.activePlayer?.positionSupported ?? false

            ProgressBar {
                width: parent.width
                accentColor: root.accent
                from: 0
                to: Math.max(1, root.activePlayer?.length ?? 1)
                value: root.livePosition
                seekable: root.activePlayer?.canSeek ?? false
                onSeeked: (v) => {
                    root.activePlayer.position = v
                    root.livePosition = v
                }
            }

            Row {
                width: parent.width
                Text {
                    id: posLeft
                    text: root.fmtTime(root.livePosition)
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                }
                Item { width: parent.width - posLeft.implicitWidth - posRight.implicitWidth; height: 1 }
                Text {
                    id: posRight
                    text: root.fmtTime(root.activePlayer?.length ?? 0)
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                }
            }
        }

        // ── Controls: three equal buttons, centered ───────────────────────────
        // All buttons identical size — no hero play button.
        // rowBackground fill matches AudioPopup clickable rows.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            MediaButton {
                icon: "󰒮"
                enabled: root.activePlayer?.canGoPrevious ?? false
                onClicked: root.activePlayer?.previous()
            }

            MediaButton {
                icon: root.isPlaying ? "󰏤" : "󰐊"
                highlighted: true
                accentColor: root.accent
                enabled: root.isPlaying
                    ? (root.activePlayer?.canPause ?? false)
                    : (root.activePlayer?.canPlay ?? false)
                onClicked: root.isPlaying
                    ? root.activePlayer?.pause()
                    : root.activePlayer?.play()
            }

            MediaButton {
                icon: "󰒭"
                enabled: root.activePlayer?.canGoNext ?? false
                onClicked: root.activePlayer?.next()
            }
        }
    }

    // ── ProgressBar ───────────────────────────────────────────────────────────
    component ProgressBar: Item {
        id: bar
        property real value: 0
        property real from: 0
        property real to: 1
        property color accentColor: PanelColors.audio
        property bool seekable: false
        signal seeked(real value)

        implicitHeight: 20
        readonly property real _ratio: to > from
            ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

        Rectangle {
            id: barTrack
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 6; radius: 3
            color: Qt.rgba(1, 1, 1, barMouse.containsMouse ? 0.15 : 0.10)
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: bar._ratio * parent.width
                height: parent.height; radius: parent.radius
                color: barMouse.containsMouse ? Qt.lighter(bar.accentColor, 1.15) : bar.accentColor
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on width {
                    enabled: !barMouse.pressed
                    NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            visible: bar.seekable
            anchors.verticalCenter: barTrack.verticalCenter
            x: bar._ratio * bar.width - width / 2
            width:  barMouse.pressed ? 6  : (barMouse.containsMouse ? 16 : 12)
            height: barMouse.pressed ? 20 : (barMouse.containsMouse ? 16 : 12)
            radius: width / 2
            color: barMouse.containsMouse ? Qt.lighter(bar.accentColor, 1.15) : bar.accentColor
            Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            Behavior on color  { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: barMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: bar.seekable
            cursorShape: bar.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: (e) => bar.seeked(bar.from + (e.x / bar.width) * (bar.to - bar.from))
            onPositionChanged: (e) => {
                if (pressed)
                    bar.seeked(bar.from + Math.max(0, Math.min(bar.width, e.x)) / bar.width * (bar.to - bar.from))
            }
        }
    }

    // ── MediaButton ───────────────────────────────────────────────────────────
    // All three buttons are the same 40×40 size.
    // `highlighted` puts the accent border on play/pause so it reads as primary
    // without breaking the size parity — matches AudioPopup's active-row pattern.
    component MediaButton: Rectangle {
        id: btn
        property string icon: ""
        property bool highlighted: false
        property color accentColor: PanelColors.audio
        property bool enabled: true
        signal clicked()

        width: 40; height: 40
        radius: 8

        // highlighted (play/pause): full accent fill + dark icon — matches pill/active-row pattern.
        // normal (prev/next): rowBackground fill — matches AudioPopup clickable rows.
        color: {
            if (!enabled) return Qt.rgba(
                PanelColors.rowBackground.r,
                PanelColors.rowBackground.g,
                PanelColors.rowBackground.b, 0.35)
            if (highlighted) return btnMouse.containsMouse
                ? Qt.lighter(accentColor, 1.1)
                : accentColor
            return btnMouse.containsMouse
                ? Qt.lighter(PanelColors.rowBackground, 1.25)
                : PanelColors.rowBackground
        }

        border.color: highlighted
            ? "transparent"
            : Qt.rgba(1, 1, 1, btnMouse.containsMouse ? 0.10 : 0.04)
        border.width: 1

        scale: btnMouse.pressed ? 0.91 : 1.0
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.pixelSize: 18
            font.family: "Symbols Nerd Font"
            color: {
                if (!btn.enabled)    return PanelColors.textDim
                if (btn.highlighted) return PanelColors.pillForeground
                return btnMouse.containsMouse ? PanelColors.textAccent : PanelColors.textMain
            }
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
