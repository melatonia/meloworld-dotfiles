import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

PopupBase {
    id: root
    implicitWidth: 300
    borderColor: PanelColors.clock
    clipContent: false
    contentHeight: popupColumn.implicitHeight

    function getPlayerIcon(identity) {
        const id = (identity || "").toLowerCase();
        if (id.includes("spotify")) return "󰓇";
        if (id.includes("firefox")) return "󰈹";
        if (id.includes("zen"))     return "󰈹";
        if (id.includes("chrome"))  return "󰊯";
        if (id.includes("vlc"))     return "󰕼";
        return "󰎆";
    }

    Connections {
        target: SessionState
        function onMediaPopupVisibleChanged() {
            root.animState = SessionState.mediaPopupVisible ? "open" : "closing"
        }
    }

    readonly property MprisPlayer activePlayer: {
        const vals = Mpris.players.values
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (!p) continue
            if (p.playbackState === MprisPlaybackState.Playing && (p.trackTitle ?? "") !== "")
                return p
        }
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (!p) continue
            if ((p.trackTitle ?? "") !== "") return p
        }
        return null
    }

    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing
    readonly property bool hasContent: activePlayer !== null
    readonly property MprisPlayer shownPlayer: activePlayer

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

    Column {
        id: popupColumn
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
        spacing: 12

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

        Row {
            visible: root.hasContent
            width: parent.width
            spacing: 12

            Item {
                id: artContainer
                width: 64
                height: 64

                Image {
                    id: artImage
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.shownPlayer?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                    mipmap: true
                    smooth: true
                }

                Text {
                    visible: artImage.status !== Image.Ready
                    anchors.centerIn: parent
                    text: "󰎆"
                    font.pixelSize: 24
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                }

                Rectangle {
                    id: artFrame
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: PanelColors.clock
                    radius: 4
                }
            }

            Column {
                width: parent.width - artContainer.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Item {
                    width: parent.width
                    height: 20
                    clip: true

                    Text {
                        id: titleText
                        text: root.shownPlayer?.trackTitle || "Unknown Title"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textAccent

                        readonly property bool overflow: implicitWidth > parent.width

                        onOverflowChanged: {
                            marqueeAnim.stop()
                            titleText.x = 0
                            if (overflow) marqueeAnim.start()
                        }
                        onTextChanged: {
                            marqueeAnim.stop()
                            titleText.x = 0
                            if (overflow) marqueeAnim.start()
                        }

                        SequentialAnimation {
                            id: marqueeAnim
                            running: false
                            loops: Animation.Infinite
                            PauseAnimation { duration: 1200 }
                            NumberAnimation {
                                target: titleText
                                property: "x"
                                from: 0
                                to: -titleText.implicitWidth
                                duration: titleText.implicitWidth * 14
                                easing.type: Easing.Linear
                            }
                            PropertyAction {
                                target: titleText
                                property: "x"
                                value: titleText.parent.width
                            }
                            NumberAnimation {
                                target: titleText
                                property: "x"
                                from: titleText.parent.width
                                to: 0
                                duration: titleText.implicitWidth * 10
                                easing.type: Easing.Linear
                            }
                            PauseAnimation { duration: 1200 }
                        }
                    }
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
                    id: identityPill
                    visible: (root.shownPlayer?.identity ?? "") !== ""
                    height: 18
                    width: pillRow.implicitWidth + 12
                    radius: height / 2
                    color: Qt.rgba(PanelColors.clock.r, PanelColors.clock.g, PanelColors.clock.b, 0.15)

                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: root.getPlayerIcon(root.shownPlayer?.identity)
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textAccent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.shownPlayer?.identity ?? ""
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textAccent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        Column {
            visible: root.hasContent && (root.shownPlayer?.positionSupported ?? false)
            width: parent.width
            spacing: 4

            WaveBar {
                id: waveBar
                width: parent.width
                accentColor: PanelColors.clock
                from: 0
                to: Math.max(1, root.shownPlayer?.length ?? 1)
                value: root.livePosition
                playing: root.isPlaying
                seekable: root.shownPlayer?.canSeek ?? false
                onSeeked: (v) => {
                    root.userSeeking = true
                    root.shownPlayer.position = v
                    root.livePosition = v
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

        Item {
            visible: root.hasContent
            width: parent.width
            height: playPauseBtn.height

            MediaButton {
                id: shuffleBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: root.shownPlayer?.shuffleSupported ?? false
                icon: "󰒝"
                accentColor: PanelColors.clock
                highlighted: root.shownPlayer?.shuffle ?? false
                onClicked: {
                    if (root.shownPlayer)
                        root.shownPlayer.shuffle = !(root.shownPlayer.shuffle ?? false)
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 4
                MediaButton {
                    icon: "󰒮"
                    accentColor: PanelColors.clock
                    enabled: root.shownPlayer?.canGoPrevious ?? false
                    onClicked: root.shownPlayer?.previous()
                }
                MediaButton {
                    id: playPauseBtn
                    icon: root.isPlaying ? "󰏤" : "󰐊"
                    highlighted: true
                    accentColor: PanelColors.clock
                    enabled: root.isPlaying
                        ? (root.shownPlayer?.canPause ?? false)
                        : (root.shownPlayer?.canPlay ?? false)
                    onClicked: root.isPlaying
                        ? root.shownPlayer?.pause()
                        : root.shownPlayer?.play()
                }
                MediaButton {
                    icon: "󰒭"
                    accentColor: PanelColors.clock
                    enabled: root.shownPlayer?.canGoNext ?? false
                    onClicked: root.shownPlayer?.next()
                }
            }

            MediaButton {
                id: repeatBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.shownPlayer?.loopSupported ?? false
                icon: (root.shownPlayer?.loopState ?? MprisLoopState.None) === MprisLoopState.Track
                    ? "󰑘" : "󰑖"
                accentColor: PanelColors.clock
                highlighted: (root.shownPlayer?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                onClicked: {
                    if (!root.shownPlayer) return
                    const s = root.shownPlayer.loopState ?? MprisLoopState.None
                    if (s === MprisLoopState.None)
                        root.shownPlayer.loopState = MprisLoopState.Playlist
                    else if (s === MprisLoopState.Playlist)
                        root.shownPlayer.loopState = MprisLoopState.Track
                    else
                        root.shownPlayer.loopState = MprisLoopState.None
                }
            }
        }
    }

    component WaveBar: Item {
        id: bar
        property real value: 0
        property real from: 0
        property real to: 100
        property color accentColor: PanelColors.clock
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
        Rectangle {
            id: trackBackground
            x: Math.max(0, bar._fillWidth - 3)
            width: Math.max(0, parent.width - x)
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: barMouse.containsMouse
                ? Qt.lighter(PanelColors.trackBackground, 1.1)
                : Qt.rgba(PanelColors.trackBackground.r, PanelColors.trackBackground.g, PanelColors.trackBackground.b, 0.4)
        }
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
                ctx.lineWidth = 6
                ctx.lineCap = "round"
                ctx.strokeStyle = barMouse.containsMouse ? Qt.lighter(bar.accentColor, 1.15) : bar.accentColor
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

    component MediaButton: Rectangle {
        id: btn
        property string icon: ""
        property bool highlighted: false
        property color accentColor: PanelColors.clock
        property bool enabled: true
        signal clicked()
        width: 40; height: 40
        radius: 8
        color: {
            if (!enabled) return Qt.rgba(PanelColors.rowBackground.r, PanelColors.rowBackground.g, PanelColors.rowBackground.b, 0.35)
            if (highlighted) return btnMouse.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor
            return btnMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.25) : PanelColors.rowBackground
        }
        border.color: highlighted ? "transparent" : Qt.rgba(1, 1, 1, btnMouse.containsMouse ? 0.10 : 0.04)
        border.width: 1
        scale: btnMouse.pressed ? 0.91 : 1.0
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.pixelSize: 18
            font.family: "JetBrainsMono Nerd Font"
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
