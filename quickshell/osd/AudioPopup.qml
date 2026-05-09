import QtQuick
import Quickshell
import "../theme"

PopupBase {
    id: root
    implicitWidth: 300
    borderColor: PanelColors.audio
    clipContent: false
    contentHeight: popupColumn.implicitHeight

    Connections {
        target: AudioState
        function onPopupVisibleChanged() {
            root.animState = AudioState.popupVisible ? "open" : "closing"
        }
    }

    // ── Tooltip API ───────────────────────────────
    property string hoveredText: ""
    property real tipX: 0
    property real tipY: 0

    Timer { id: showTimer; interval: 450; onTriggered: showAnim.start() }
    NumberAnimation { id: showAnim; target: tooltip; property: "opacity"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    NumberAnimation { id: hideAnim; target: tooltip; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }

    function updateTip(item, text) {
        showTimer.stop()
        showAnim.stop()
        hideAnim.stop()
        tooltip.opacity = 0
        root.hoveredText = text
        root.tipX = 14
        root.tipY = item.y + popupColumn.y - tooltip.height - 6
        showTimer.start()
    }

    function clearTip() {
        showTimer.stop()
        showAnim.stop()
        hideAnim.stop()
        hideAnim.start()
    }

    function shortName(desc) {
        if (!desc) return ""
        let s = desc.trim()
        const noise = /\b(HD Audio|Controller|Analog|Stereo|Mono|Digital|Output|Input|Series)\b/gi
        s = s.replace(noise, "")
        let words = s.split(/\s+/).filter(w => w.length > 0)
        let seen = new Set(), unique = []
        for (let w of words) {
            let lw = w.toLowerCase()
            if (!seen.has(lw)) { seen.add(lw); unique.push(w) }
        }
        return unique.join(" ").replace(/[()[\]\-_]/g, " ").replace(/\s{2,}/g, " ").trim() || desc
    }

    // ── Icon Toggle Button ────────────────────────
    // active   (unmuted): PanelColors.audio bg         + PanelColors.pillForeground icon
    // inactive (muted):   PanelColors.trackBackground bg + PanelColors.audio icon
    component IconButton: Rectangle {
        id: btn
        property string icon: ""
        property bool active: true
        signal clicked()

        width: height       // always square; callers set height to match sibling slider
        radius: 6
        color: btn.active ? PanelColors.audio : PanelColors.trackBackground
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
            color: btn.active ? PanelColors.pillForeground : PanelColors.audio
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: btn.clicked()
        }
    }

    Column {
        id: popupColumn
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
        spacing: 8

        Row {
            visible: AudioState.sinks.length > 1
            height: visible ? 34 : 0
            spacing: 6
            leftPadding: 4
            Text { text: "󰕾"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.audio; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Output"; font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain; anchors.verticalCenter: parent.verticalCenter }
        }

        Repeater {
            model: AudioState.sinks.length > 1 ? AudioState.sinks : []
            delegate: Rectangle {
                id: devBox
                required property var modelData
                readonly property bool isActive: modelData.name === AudioState.defaultSink
                width: popupColumn.width
                height: 34
                radius: 6
                color: {
                    let base = isActive ? PanelColors.audio : PanelColors.rowBackground
                    return sinkMouse.containsMouse && !isActive ? Qt.lighter(base, 1.15) : base
                }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                    text: root.shortName(modelData.description)
                    font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: isActive ? PanelColors.pillForeground : PanelColors.textMain
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: sinkMouse
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: { root.updateTip(parent, modelData.description) }
                    onExited: { root.clearTip() }
                    onClicked: AudioState.setDefaultSink(modelData.name)
                }
            }
        }

        Row {
            visible: AudioState.sources.length > 1
            height: visible ? 34 : 0
            spacing: 6
            leftPadding: 4
            Text { text: "󰍬"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.audio; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Input"; font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain; anchors.verticalCenter: parent.verticalCenter }
        }

        Repeater {
            model: AudioState.sources.length > 1 ? AudioState.sources : []
            delegate: Rectangle {
                id: inBox
                required property var modelData
                readonly property bool isActive: modelData.name === AudioState.defaultSource
                width: popupColumn.width
                height: 34
                radius: 6
                color: {
                    let base = isActive ? PanelColors.audio : PanelColors.rowBackground
                    return sourceMouse.containsMouse && !isActive ? Qt.lighter(base, 1.15) : base
                }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                    text: root.shortName(modelData.description)
                    font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: isActive ? PanelColors.pillForeground : PanelColors.textMain
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: sourceMouse
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: { root.updateTip(parent, modelData.description) }
                    onExited: { root.clearTip() }
                    onClicked: AudioState.setDefaultSource(modelData.name)
                }
            }
        }

        Rectangle {
            visible: AudioState.sinks.length > 1 || AudioState.sources.length > 1
            width: parent.width
            height: visible ? 2 : 0
            color: PanelColors.rowBackground
        }

        // ── Volume row ────────────────────────────
        Row {
            width: popupColumn.width
            height: 34
            spacing: 6

            IconButton {
                // height binds to the slider's actual height — if slider implicitHeight
                // ever changes, the button tracks it automatically
                height: volSlider.height
                active: !AudioState.muted
                icon: AudioState.muted ? "󰝟" : "󰕾"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: AudioState.setMute(!AudioState.muted)
            }

            PanelSlider {
                id: volSlider
                // width accounts for the square button (== its own height) + spacing
                width: parent.width - height - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                clickable: true
                label: AudioState.volume + "%"
                value: AudioState.volume
                accentColor: AudioState.muted ? PanelColors.textDim : PanelColors.audio
                onMoved: (v) => AudioState.setVolume(v)
            }
        }

        // ── Mic row ───────────────────────────────
        Row {
            width: popupColumn.width
            height: 34
            spacing: 6

            IconButton {
                height: micSlider.height
                active: !AudioState.micMuted
                icon: AudioState.micMuted ? "󰍭" : "󰍬"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: AudioState.setMicMute(!AudioState.micMuted)
            }

            PanelSlider {
                id: micSlider
                width: parent.width - height - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                clickable: true
                label: AudioState.micVolume + "%"
                value: AudioState.micVolume
                accentColor: AudioState.micMuted ? PanelColors.textDim : PanelColors.audio
                onMoved: (v) => AudioState.setMicVolume(v)
            }
        }
    }

    Rectangle {
        id: tooltip
        opacity: 0
        z: 9999
        enabled: false
        width: tipLabel.implicitWidth + 16
        height: 26
        radius: 6
        color: PanelColors.rowBackground
        border.color: PanelColors.audio
        border.width: 1
        x: root.tipX
        y: root.tipY
        Text {
            id: tipLabel
            anchors.centerIn: parent
            text: root.hoveredText
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
            color: PanelColors.textMain
        }
    }
}
