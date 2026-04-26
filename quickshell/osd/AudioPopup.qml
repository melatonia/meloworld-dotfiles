import QtQuick
import Quickshell
import "../theme"

PopupBase {
    id: root
    implicitWidth:  300
    borderColor:    Colors.teal200
    clipContent:    false  // must be false so tooltips can overflow the panel bounds
    contentHeight:  popupColumn.implicitHeight

    Connections {
        target: AudioState
        function onPopupVisibleChanged() {
            root.animState = AudioState.popupVisible ? "open" : "closing"
        }
    }

    // ── Naming Logic ──────────────────────────────
    function shortName(desc) {
        if (!desc) return ""
        let s = desc.trim()

        const noise = /\b(HD Audio|Controller|Analog|Stereo|Mono|Digital|Output|Input|Series)\b/gi
        s = s.replace(noise, "")

        let words     = s.split(/\s+/).filter(w => w.length > 0)
        let seen      = new Set()
        let unique    = []
        for (let i = 0; i < words.length; i++) {
            let lw = words[i].toLowerCase()
            if (!seen.has(lw)) { seen.add(lw); unique.push(words[i]) }
        }

        s = unique.join(" ")
        s = s.replace(/[()[\]\-_]/g, " ").replace(/\s{2,}/g, " ")
        return s.trim() || desc
    }

    // ── Content ───────────────────────────────────
    Column {
        id: popupColumn
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
        spacing: 4

        Item { width: 1; height: 2 }

        // ── Output section ────────────────────────
        Row {
            id: outHeader
            visible: AudioState.sinks.length > 1
            height:  visible ? 34 : 0
            spacing: 6
            leftPadding: 4
            Text { text: "󰕾"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: Colors.teal200; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Output"; font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: Colors.grey200; anchors.verticalCenter: parent.verticalCenter }
        }

        Repeater {
            model: AudioState.sinks.length > 1 ? AudioState.sinks : []
            delegate: Rectangle {
                id: devBox
                required property var modelData
                readonly property bool isActive: modelData.name === AudioState.defaultSink
                width: popupColumn.width; height: 34; radius: 6
                color: isActive ? Colors.teal200 : (devMouse.containsMouse ? Colors.grey700 : PanelColors.rowBackground)

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                    text: root.shortName(modelData.description)
                    font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: isActive ? PanelColors.pillForeground : Colors.grey200
                    elide: Text.ElideRight
                }

                // Fading tooltip
                Rectangle {
                    anchors { bottom: parent.top; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                    width: tipText.implicitWidth + 16; height: 26; radius: 6
                    color: PanelColors.rowBackground; border.color: Colors.teal200; border.width: 1
                    z: 999
                    visible: opacity > 0
                    opacity: devMouse.containsMouse ? 1.0 : 0.0
                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation  { duration: 300 }
                            NumberAnimation { duration: 150 }
                        }
                    }
                    Text {
                        id: tipText
                        anchors.centerIn: parent
                        text: modelData.description
                        font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.grey100
                    }
                }

                MouseArea { id: devMouse; anchors.fill: parent; hoverEnabled: true; onClicked: AudioState.setDefaultSink(modelData.name) }
            }
        }

        // ── Input section ─────────────────────────
        Row {
            id: inHeader
            visible: AudioState.sources.length > 1
            height:  visible ? 34 : 0
            spacing: 6
            leftPadding: 4
            Text { text: "󰍬"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: Colors.teal200; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Input"; font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: Colors.grey200; anchors.verticalCenter: parent.verticalCenter }
        }

        Repeater {
            model: AudioState.sources.length > 1 ? AudioState.sources : []
            delegate: Rectangle {
                id: inBox
                required property var modelData
                readonly property bool isActive: modelData.name === AudioState.defaultSource
                width: popupColumn.width; height: 34; radius: 6
                color: isActive ? Colors.teal200 : (inMouse.containsMouse ? Colors.grey700 : PanelColors.rowBackground)

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                    text: root.shortName(modelData.description)
                    font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: isActive ? PanelColors.pillForeground : Colors.grey200
                    elide: Text.ElideRight
                }

                // Fading tooltip
                Rectangle {
                    anchors { bottom: parent.top; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                    width: inTipText.implicitWidth + 16; height: 26; radius: 6
                    color: PanelColors.rowBackground; border.color: Colors.teal200; border.width: 1
                    z: 999
                    visible: opacity > 0
                    opacity: inMouse.containsMouse ? 1.0 : 0.0
                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation  { duration: 300 }
                            NumberAnimation { duration: 150 }
                        }
                    }
                    Text {
                        id: inTipText
                        anchors.centerIn: parent
                        text: modelData.description
                        font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.grey100
                    }
                }

                MouseArea { id: inMouse; anchors.fill: parent; hoverEnabled: true; onClicked: AudioState.setDefaultSource(modelData.name) }
            }
        }

        // ── Divider ───────────────────────────────
        Rectangle { visible: outHeader.visible || inHeader.visible; width: parent.width; height: 1; color: PanelColors.rowBackground }

        Rectangle {
            width: parent.width; height: 34; radius: 6; color: PanelColors.rowBackground
            Row {
                anchors { fill: parent; margins: 10 }
                spacing: 8
                Text {
                    text: AudioState.muted ? "󰝟" : "󰕾"
                    font.pixelSize: 16
                    color: AudioState.muted ? Colors.grey500 : Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea { anchors.fill: parent; onClicked: AudioState.setMute(!AudioState.muted) }
                }
                AudioSlider {
                    width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.volume; accentColor: AudioState.muted ? Colors.grey600 : Colors.teal200
                    onMoved: (v) => AudioState.setVolume(v)
                }
                Text { text: AudioState.volume + "%"; width: 32; font.pixelSize: 12; color: Colors.grey300; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Rectangle {
            width: parent.width; height: 34; radius: 6; color: PanelColors.rowBackground
            Row {
                anchors { fill: parent; margins: 10 }
                spacing: 8
                Text {
                    text: AudioState.micMuted ? "󰍭" : "󰍬"
                    font.pixelSize: 16
                    color: AudioState.micMuted ? Colors.grey500 : Colors.teal200
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea { anchors.fill: parent; onClicked: AudioState.setMicMute(!AudioState.micMuted) }
                }
                AudioSlider {
                    width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter
                    value: AudioState.micVolume; accentColor: AudioState.micMuted ? Colors.grey600 : Colors.teal200
                    onMoved: (v) => AudioState.setMicVolume(v)
                }
                Text { text: AudioState.micVolume + "%"; width: 32; font.pixelSize: 12; color: Colors.grey300; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Item { width: 1; height: 4 }
    }
}
