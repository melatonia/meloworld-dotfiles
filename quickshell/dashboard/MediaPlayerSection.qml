import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

SectionBase {
    id: root
    title: "Media Player"
    icon: "󰕾"
    accent: PanelColors.audio

    // ── Player selection ──────────────────────────────────────────────────────
    // Filter out browser idle registrations: require a non-empty trackTitle
    // OR an active Playing state. Chrome/Firefox register on D-Bus with blank
    // metadata when nothing is playing — this discards those ghost entries.
    readonly property MprisPlayer activePlayer: {
        const vals = Mpris.players.values
        // First pass: prefer a player that is actively Playing
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (!p) continue
            if (p.playbackState === MprisPlaybackState.Playing
                    && (p.trackTitle ?? "") !== "")
                return p
        }
        // Second pass: fall back to a paused/stopped player with known track
        // (excludes browsers with blank metadata)
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (!p) continue
            if ((p.trackTitle ?? "") !== "")
                return p
        }
        return null
    }

    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing

    // ── Pause cooldown ────────────────────────────────────────────────────────
    // Keep the last known player visible for 10 s after it disappears,
    // so pausing doesn't make the widget vanish immediately.
    // If a new valid player appears during cooldown, it takes over instantly.
    property MprisPlayer displayPlayer: null
    property bool inCooldown: false

    Timer {
        id: cooldownTimer
        interval: 10000
        repeat: false
        onTriggered: {
            root.inCooldown = false
            root.displayPlayer = null
        }
    }

    onActivePlayerChanged: {
        if (activePlayer !== null) {
            // New real player — show it immediately, cancel any cooldown
            cooldownTimer.stop()
            inCooldown = false
            displayPlayer = activePlayer
        } else {
            // Player gone — start cooldown, keep last displayPlayer
            if (displayPlayer !== null) {
                inCooldown = true
                cooldownTimer.restart()
            }
        }
    }

    // The widget is shown if we have a live player OR are in cooldown
    readonly property bool hasContent: activePlayer !== null || inCooldown
    // What we actually render — live player when available, cached otherwise
    readonly property MprisPlayer shownPlayer: activePlayer !== null ? activePlayer : displayPlayer

    // ── Position tracking ─────────────────────────────────────────────────────
    property real livePosition: shownPlayer?.position ?? 0
    property bool userSeeking: false

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying && !root.userSeeking
        onTriggered: { if (root.shownPlayer) root.livePosition = root.shownPlayer.position }
    }

    Connections {
        target: root.shownPlayer
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
        visible: !root.hasContent
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
        visible: root.hasContent
        width: parent.width
        spacing: 12

        // Fade out during cooldown to signal "nothing active"
        opacity: root.inCooldown && !root.isPlaying ? 0.5 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }

        // ── Art + track info ──────────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 12

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
                    source: root.shownPlayer?.trackArtUrl ?? ""
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

            Column {
                width: parent.width - artBox.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    width: parent.width
                    text: root.shownPlayer?.trackTitle || "Unknown Title"
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textAccent
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.shownPlayer?.trackArtist || "Unknown Artist"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: (root.shownPlayer?.identity ?? "") !== ""
                    height: 18
                    width: badgeText.implicitWidth + 12
                    radius: 4
                    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
                    border.width: 1

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.shownPlayer?.identity ?? ""
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        color: root.accent
                    }
                }
            }
        }

        // ── Wave progress bar + timestamps ────────────────────────────────────
        Column {
            width: parent.width
            spacing: 4
            visible: root.shownPlayer?.positionSupported ?? false

            WaveBar {
                id: waveBar
                width: parent.width
                accentColor: root.accent
                from: 0
                to: Math.max(1, root.shownPlayer?.length ?? 1)
                value: root.livePosition
                playing: root.isPlaying
                seekable: root.shownPlayer?.canSeek ?? false
                onSeeked: (v) => {
                    root.userSeeking = true
                    root.shownPlayer.position = v
                    root.livePosition = v
                    // Release seeking lock after a short settle
                    seekReleaseTimer.restart()
                }
            }

            Timer {
                id: seekReleaseTimer
                interval: 1200
                onTriggered: root.userSeeking = false
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
                    text: root.fmtTime(root.shownPlayer?.length ?? 0)
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                }
            }
        }

        // ── Controls ──────────────────────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            MediaButton {
                icon: "󰒮"
                enabled: root.shownPlayer?.canGoPrevious ?? false
                onClicked: root.shownPlayer?.previous()
            }

            MediaButton {
                icon: root.isPlaying ? "󰏤" : "󰐊"
                highlighted: true
                accentColor: root.accent
                enabled: root.isPlaying
                    ? (root.shownPlayer?.canPause ?? false)
                    : (root.shownPlayer?.canPlay ?? false)
                onClicked: root.isPlaying
                    ? root.shownPlayer?.pause()
                    : root.shownPlayer?.play()
            }

            MediaButton {
                icon: "󰒭"
                enabled: root.shownPlayer?.canGoNext ?? false
                onClicked: root.shownPlayer?.next()
            }
        }
    }

    // ── Material 3 Expressive WaveBar ─────────────────────────────────────────
    component WaveBar: Item {
        id: bar
        // API & Logic from PanelSlider.qml
        property real value: 0
        property real from: 0
        property real to: 100
        property color accentColor: Colors.teal200
        property bool playing: false
        property bool seekable: true
        signal seeked(real value)

        implicitWidth: 120
        implicitHeight: 32

        property bool dragging: barMouse.pressed
        property real internalValue: 0
        readonly property bool activeInteraction: dragging
        readonly property bool isNeedle: activeInteraction || playing

        readonly property real targetValue: activeInteraction ? internalValue : value
        property real animValue: targetValue
        Behavior on animValue {
            enabled: !bar.dragging
            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
        }

        readonly property real _fillWidth: ((bar.animValue - bar.from) / (bar.to - bar.from)) * bar.width

        function _updateFromMouse(mouseX) {
            var newVal = Math.max(bar.from, Math.min(bar.to,
                bar.from + (mouseX / bar.width) * (bar.to - bar.from)))
            bar.internalValue = newVal
            bar.seeked(newVal)
        }

        // Wave Animation Driver
        property real _phase: 0
        NumberAnimation on _phase {
            from: 0; to: Math.PI * 2
            duration: 1200
            loops: Animation.Infinite
            running: bar.playing && !bar.activeInteraction
        }

        property real _waveAmount: 0.0
        Behavior on _waveAmount { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
        onPlayingChanged: _waveAmount = (playing && !activeInteraction) ? 1.0 : 0.0
        onActiveInteractionChanged: _waveAmount = (playing && !activeInteraction) ? 1.0 : 0.0

        // 1. BACKGROUND Track (Straight part from PanelSlider.qml[cite: 2])
        Rectangle {
            id: trackBackground
            x: Math.max(0, bar._fillWidth - 3) // Slight overlap to prevent gaps
            width: Math.max(0, parent.width - x)
            height: 6
            radius: 3 // Rounded ends for the inactive part[cite: 2]
            anchors.verticalCenter: parent.verticalCenter
            color: barMouse.containsMouse
                ? Qt.lighter(PanelColors.trackBackground, 1.1)
                : Qt.rgba(PanelColors.trackBackground.r, PanelColors.trackBackground.g, PanelColors.trackBackground.b, 0.4)
        }

        // 2. ACTIVE Track (Wavy part with rounded caps)
        Canvas {
            id: waveCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (bar._fillWidth <= 0) return

                const cy = height / 2
                const amp = 3.5 * bar._waveAmount
                const freq = 0.16

                ctx.beginPath()
                ctx.lineWidth = 6 // Matches PanelSlider thickness[cite: 2]
                ctx.lineCap = "round" // FIX: This rounds the left-most start of the line[cite: 1]
                ctx.strokeStyle = barMouse.containsMouse ? Qt.lighter(bar.accentColor, 1.15) : bar.accentColor

                // Offset start by 3px so the rounded cap is visible and not squared by the edge
                const startX = 3

                if (bar._waveAmount > 0) {
                    for (let x = startX; x <= bar._fillWidth; x++) {
                        const y = cy + Math.sin(x * freq + bar._phase) * amp
                        if (x === startX) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                } else {
                    ctx.moveTo(startX, cy)
                    ctx.lineTo(bar._fillWidth, cy)
                }
                ctx.stroke()
            }

            Connections {
                target: bar
                function onAnimValueChanged() { waveCanvas.requestPaint() }
                function on_PhaseChanged() { waveCanvas.requestPaint() }
                function on_WaveAmountChanged() { waveCanvas.requestPaint() }
            }
        }

        // 3. Handle (Needle Morph from PanelSlider.qml[cite: 2])
        Item {
            id: handleContainer
            width: 0; height: 0
            anchors.verticalCenter: parent.verticalCenter
            x: bar._fillWidth

            Rectangle {
                id: handle
                anchors.centerIn: parent
                width: bar.isNeedle ? 6 : (barMouse.containsMouse ? 18 : 14)
                height: bar.isNeedle ? 24 : (barMouse.containsMouse ? 18 : 14)
                radius: width / 2
                color: barMouse.containsMouse ? Qt.lighter(bar.accentColor, 1.15) : bar.accentColor

                Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            }
        }

        MouseArea {
            id: barMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: bar.seekable
            onPressed: (mouse) => { bar.internalValue = bar.animValue; bar._updateFromMouse(mouse.x) }
            onPositionChanged: (mouse) => { if (pressed) bar._updateFromMouse(mouse.x) }
            onClicked: (mouse) => bar._updateFromMouse(mouse.x)
        }
    }

    // ── MediaButton ───────────────────────────────────────────────────────────
    component MediaButton: Rectangle {
        id: btn
        property string icon: ""
        property bool highlighted: false
        property color accentColor: PanelColors.audio
        property bool enabled: true
        signal clicked()

        width: 40; height: 40
        radius: 8

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
