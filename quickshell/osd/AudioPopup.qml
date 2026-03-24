import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root
    visible: animState !== "closed"
    implicitWidth: 300
    implicitHeight: 600
    color: "transparent"

    property string animState: "closed"

    Connections {
        target: AudioState
        function onPopupVisibleChanged() {
            if (AudioState.popupVisible) {
                animState = "open"
            } else {
                animState = "closing"
            }
        }
    }

    // ── Naming Logic (Reverted to the version you liked) ──
    function shortName(desc) {
        if (!desc) return ""
        let s = desc.trim()

        const noise = /\b(HD Audio|Controller|Analog|Stereo|Mono|Digital|Output|Input|Series)\b/gi
        s = s.replace(noise, "")

        let words = s.split(/\s+/).filter(w => w.length > 0)
        let uniqueWords = []
        for (let i = 0; i < words.length; i++) {
            let isDuplicate = false
            for (let j = 0; j < uniqueWords.length; j++) {
                if (uniqueWords[j].toLowerCase() === words[i].toLowerCase()) {
                    isDuplicate = true
                    break
                }
            }
            if (!isDuplicate) {
                uniqueWords.push(words[i])
            }
        }

        s = uniqueWords.join(" ")
        s = s.replace(/[()\[\]\-_]/g, " ").replace(/\s{2,}/g, " ")
        return s.trim() || desc
    }

    Rectangle {
        id: innerRect
        width: parent.width
        height: popupColumn.implicitHeight + 20
        radius: 10
        color: Colors.grey900
        border.color: Colors.teal200
        border.width: 2
        clip: false // Essential for tooltips to show outside the bounds

        Behavior on height {
            SmoothedAnimation { velocity: 800; easing.type: Easing.OutExpo }
        }

        y: 0
        opacity: 1.0

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: innerRect; y: 0; opacity: 1.0 }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: innerRect; y: -20; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                SequentialAnimation {
                    PropertyAction { target: innerRect; property: "y"; value: -20 }
                    PropertyAction { target: innerRect; property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y"; to: 0; duration: 250; easing.type: Easing.OutExpo }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y"; to: -20; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        Column {
            id: popupColumn
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
            spacing: 4

            Item { width: 1; height: 2 }

            // ── Output Section ──
            Row {
                id: outHeader
                visible: AudioState.sinks.length > 1
                height: visible ? 34 : 0
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
                    color: isActive ? Colors.teal200 : (devMouse.containsMouse ? Colors.grey700 : Colors.grey800)

                    Text {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                        text: root.shortName(modelData.description)
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? Colors.grey900 : Colors.grey200
                        elide: Text.ElideRight
                    }

                    // Fading Tooltip
                    Rectangle {
                        id: tooltip
                        anchors { bottom: parent.top; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                        width: tipText.implicitWidth + 16; height: 26; radius: 6
                        color: Colors.grey800; border.color: Colors.teal200; border.width: 1
                        z: 999
                        visible: opacity > 0
                        opacity: devMouse.containsMouse ? 1.0 : 0.0

                        Behavior on opacity {
                            SequentialAnimation {
                                PauseAnimation { duration: 300 } // Small delay
                                NumberAnimation { duration: 150 }
                            }
                        }

                        Text {
                            id: tipText
                            anchors.centerIn: parent
                            text: modelData.description // The "Full" name you wanted to see
                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.grey100
                        }
                    }

                    MouseArea { id: devMouse; anchors.fill: parent; hoverEnabled: true; onClicked: AudioState.setDefaultSink(modelData.name) }
                }
            }

            // ── Input Section ──
            Row {
                id: inHeader
                visible: AudioState.sources.length > 1
                height: visible ? 34 : 0
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
                    color: isActive ? Colors.teal200 : (inMouse.containsMouse ? Colors.grey700 : Colors.grey800)

                    Text {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14; right: parent.right; rightMargin: 8 }
                        text: root.shortName(modelData.description)
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? Colors.grey900 : Colors.grey200
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: inTooltip
                        anchors { bottom: parent.top; bottomMargin: 6; horizontalCenter: parent.horizontalCenter }
                        width: inTipText.implicitWidth + 16; height: 26; radius: 6
                        color: Colors.grey800; border.color: Colors.teal200; border.width: 1
                        z: 999
                        visible: opacity > 0
                        opacity: inMouse.containsMouse ? 1.0 : 0.0

                        Behavior on opacity {
                            SequentialAnimation {
                                PauseAnimation { duration: 400 }
                                NumberAnimation { duration: 150 }
                            }
                        }

                        Text { id: inTipText; anchors.centerIn: parent; text: modelData.description; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: Colors.grey100 }
                    }

                    MouseArea { id: inMouse; anchors.fill: parent; hoverEnabled: true; onClicked: AudioState.setDefaultSource(modelData.name) }
                }
            }

            // ── Dividers & Sliders ──
            Rectangle { visible: outHeader.visible || inHeader.visible; width: parent.width; height: 1; color: Colors.grey800 }

            // Volume
            Rectangle {
                width: parent.width; height: 34; radius: 6; color: Colors.grey800
                Row {
                    anchors { fill: parent; margins: 10 }
                    spacing: 8
                    Text { text: AudioState.muted ? "󰝟" : "󰕾"; font.pixelSize: 16; color: AudioState.muted ? Colors.grey500 : Colors.teal200; anchors.verticalCenter: parent.verticalCenter; MouseArea { anchors.fill: parent; onClicked: AudioState.setMute(!AudioState.muted) } }
                    AudioSlider { width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter; value: AudioState.volume; accentColor: AudioState.muted ? Colors.grey600 : Colors.teal200; onMoved: (v) => AudioState.setVolume(v) }
                    Text { text: AudioState.volume + "%"; width: 32; font.pixelSize: 12; color: Colors.grey300; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // Mic
            Rectangle {
                width: parent.width; height: 34; radius: 6; color: Colors.grey800
                Row {
                    anchors { fill: parent; margins: 10 }
                    spacing: 8
                    Text { text: AudioState.micMuted ? "󰍭" : "󰍬"; font.pixelSize: 16; color: AudioState.micMuted ? Colors.grey500 : Colors.teal200; anchors.verticalCenter: parent.verticalCenter; MouseArea { anchors.fill: parent; onClicked: AudioState.setMicMute(!AudioState.micMuted) } }
                    AudioSlider { width: parent.width - 64; anchors.verticalCenter: parent.verticalCenter; value: AudioState.micVolume; accentColor: AudioState.micMuted ? Colors.grey600 : Colors.teal200; onMoved: (v) => AudioState.setMicVolume(v) }
                    Text { text: AudioState.micVolume + "%"; width: 32; font.pixelSize: 12; color: Colors.grey300; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            Item { width: 1; height: 4 }
        }
    }
}
