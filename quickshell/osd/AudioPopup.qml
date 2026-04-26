import QtQuick
import Quickshell
import "../theme"

PopupBase {
    id: root
    implicitWidth:  300
    borderColor:    PanelColors.audio
    clipContent:    false
    contentHeight:  popupColumn.implicitHeight

    Connections {
        target: AudioState
        function onPopupVisibleChanged() {
            root.animState = AudioState.popupVisible ? "open" : "closing"
        }
    }

    // ── Tooltip API ───────────────────────────────
    property string hoveredText: ""
    property real   tipX: 0
    property real   tipY: 0
    
    Timer { id: showTimer; interval: 450; onTriggered: showAnim.start() }
    NumberAnimation { id: showAnim; target: tooltip; property: "opacity"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    NumberAnimation { id: hideAnim; target: tooltip; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }

    function updateTip(item, text) {
        showTimer.stop(); showAnim.stop(); hideAnim.stop()
        tooltip.opacity = 0 // Instant reset for navigation
        root.hoveredText = text
        root.tipX = 14
        root.tipY = item.y + popupColumn.y - tooltip.height - 6
        showTimer.start()
    }

    function clearTip() {
        showTimer.stop(); showAnim.stop(); hideAnim.stop()
        hideAnim.start() // Smooth fade on exit
    }

    // ── Naming Logic ──────────────────────────────
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

    Column {
        id: popupColumn
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
        spacing: 8

        // ── Output section ────────────────────────
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
                id: devBox; required property var modelData
                readonly property bool isActive: modelData.name === AudioState.defaultSink
                width: popupColumn.width; height: 34; radius: 6
                color: isActive ? PanelColors.audio : PanelColors.rowBackground
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                    text: root.shortName(modelData.description); font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: isActive ? PanelColors.pillForeground : PanelColors.textMain; elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: { if (!isActive) parent.opacity = 0.8; root.updateTip(parent, modelData.description) }
                    onExited:  { parent.opacity = 1.0; root.clearTip() }
                    onClicked: AudioState.setDefaultSink(modelData.name)
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // ── Input section ─────────────────────────
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
                id: inBox; required property var modelData
                readonly property bool isActive: modelData.name === AudioState.defaultSource
                width: popupColumn.width; height: 34; radius: 6
                color: isActive ? PanelColors.audio : PanelColors.rowBackground
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                    text: root.shortName(modelData.description); font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: isActive ? PanelColors.pillForeground : PanelColors.textMain; elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: { if (!isActive) parent.opacity = 0.8; root.updateTip(parent, modelData.description) }
                    onExited:  { parent.opacity = 1.0; root.clearTip() }
                    onClicked: AudioState.setDefaultSource(modelData.name)
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        Rectangle { 
            visible: AudioState.sinks.length > 1 || AudioState.sources.length > 1
            width: parent.width; height: visible ? 1 : 0; color: PanelColors.rowBackground 
        }

        // Sliders
        Rectangle {
            width: parent.width; height: 34; radius: 6; color: PanelColors.rowBackground
            Row {
                anchors { fill: parent; margins: root.padding }; spacing: 8
                Text {
                    text: AudioState.muted ? "󰝟" : "󰕾"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                    color: AudioState.muted ? PanelColors.textDim : PanelColors.audio; anchors.verticalCenter: parent.verticalCenter
                    MouseArea { anchors.fill: parent; onClicked: AudioState.setMute(!AudioState.muted) }
                }
                PanelSlider {
                    width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.volume; accentColor: AudioState.muted ? PanelColors.textDim : PanelColors.audio
                    onMoved: (v) => AudioState.setVolume(v)
                }
                Text { text: AudioState.volume + "%"; width: 32; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Rectangle {
            width: parent.width; height: 34; radius: 6; color: PanelColors.rowBackground
            Row {
                anchors { fill: parent; margins: root.padding }; spacing: 8
                Text {
                    text: AudioState.micMuted ? "󰍭" : "󰍬"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                    color: AudioState.micMuted ? PanelColors.textDim : PanelColors.audio; anchors.verticalCenter: parent.verticalCenter
                    MouseArea { anchors.fill: parent; onClicked: AudioState.setMicMute(!AudioState.micMuted) }
                }
                PanelSlider {
                    width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.micVolume; accentColor: AudioState.micMuted ? PanelColors.textDim : PanelColors.audio
                    onMoved: (v) => AudioState.setMicVolume(v)
                }
                Text { text: AudioState.micVolume + "%"; width: 32; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    Rectangle {
        id: tooltip; opacity: 0; z: 9999; enabled: false
        width: tipLabel.implicitWidth + 16; height: 26; radius: 6
        color: PanelColors.rowBackground; border.color: PanelColors.audio; border.width: 1
        x: root.tipX; y: root.tipY
        Text { id: tipLabel; anchors.centerIn: parent; text: root.hoveredText; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain }
    }
}
