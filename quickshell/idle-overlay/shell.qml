import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "qs-idle-overlay"

            color: "transparent"

            // ─── TUNABLES ───
            property real dimOpacity: 0.4
            property int fadeInDuration: 1200
            property int fadeOutDuration: 240
            property color catColor: "#ffffffdd"
            property real catOpacity: 0.84
            property int catFontSize: 18
            property real catLineHeight: 1

            // ─── State ───
            property bool isQuitting: false
            // Guard against Hyprland's synthetic key/pointer events fired at
            // map-time when a layer surface with Exclusive keyboard focus is
            // created.  Input is ignored until this is true.
            property bool inputReady: false

            function fadeAndQuit() {
                if (!inputReady) return
                if (isQuitting) return
                isQuitting = true
                dimLayer.opacity = 0.0
                catText.opacity = 0.0
                quitTimer.start()
            }

            Timer {
                id: quitTimer
                interval: win.fadeOutDuration
                repeat: false
                onTriggered: Qt.quit()
            }

            // ─── Dim Layer ───
            Rectangle {
                id: dimLayer
                anchors.fill: parent
                color: "#000000"
                opacity: 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: win.isQuitting ? win.fadeOutDuration : win.fadeInDuration
                        easing.type: win.isQuitting ? Easing.OutQuart : Easing.InOutQuad
                    }
                }
            }

            // ─── Cat ───
            Text {
                id: catText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -20

                property string cat1: "      |\\      _,,,---,,_\n" +
                                    "      /,`.-'`'    -.  ;-;;,_\n" +
                                    "     |,4-  ) )-,_. ,\\ (  `'-'\n" +
                                    "    '---''(_/--'  `-'\\_)  melo."

                property string cat2: "      |\\      _,,,---,,_\n" +
                                    "   z  /,`.-'`'    -.  ;-;;,_\n" +
                                    "     |,4-  ) )-,_. ,\\ (  `'-'\n" +
                                    "    '---''(_/--'  `-'\\_)  melo."

                property string cat3: "  Z   |\\      _,,,---,,_\n" +
                                    "   z  /,`.-'`'    -.  ;-;;,_\n" +
                                    "     |,4-  ) )-,_. ,\\ (  `'-'\n" +
                                    "    '---''(_/--'  `-'\\_)  melo."

                property int catFrame: 0
                text: catFrame === 0 ? cat1 : catFrame === 1 ? cat2 : cat3

                Timer {
                    id: frameTimer
                    interval: 600
                    repeat: true
                    running: false
                    onTriggered: catText.catFrame = (catText.catFrame + 1) % 3
                }

                color: win.catColor
                opacity: 0.0
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: win.catFontSize
                lineHeight: win.catLineHeight
                horizontalAlignment: Text.AlignLeft
                renderType: Text.NativeRendering

                Behavior on opacity {
                    NumberAnimation {
                        duration: win.isQuitting ? win.fadeOutDuration : win.fadeInDuration
                        easing.type: win.isQuitting ? Easing.OutQuart : Easing.InOutQuad
                    }
                }

                SequentialAnimation {
                    id: breathe
                    running: false
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: catText
                        property: "opacity"
                        to: 0.5
                        duration: 1200
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        target: catText
                        property: "opacity"
                        to: win.catOpacity
                        duration: 1800
                        easing.type: Easing.InOutCubic
                    }
                }
            }

            // ─── Input ───
            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: win.fadeAndQuit()

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    hoverEnabled: true
                    onPressed: win.fadeAndQuit()
                    // Use onPositionChanged instead of the individual axis signals
                    // to avoid firing on Hyprland's initial pointer-warp event.
                    property point lastPos: Qt.point(-1, -1)
                    onPositionChanged: (mouse) => {
                        if (lastPos.x < 0) {
                            lastPos = Qt.point(mouse.x, mouse.y)
                            return
                        }
                        win.fadeAndQuit()
                    }
                }
            }

            // ─── Arm input after the fade-in settles ───
            // Hyprland fires a synthetic KeyPress + pointer-warp the moment an
            // Exclusive layer surface is mapped.  We ignore all input for a
            // short window so those spurious events don't immediately quit.
            Timer {
                id: inputReadyTimer
                interval: 300   // well within the 1200 ms fade-in
                repeat: false
                onTriggered: win.inputReady = true
            }

            // ─── Trigger fade in ───
            Component.onCompleted: {
                dimLayer.opacity = win.dimOpacity
                catText.opacity = win.catOpacity
                breatheTimer.start()
                inputReadyTimer.start()
            }

            Timer {
                id: breatheTimer
                interval: win.fadeInDuration
                repeat: false
                onTriggered: {
                    breathe.running = true
                    frameTimer.running = true
                }
            }
        }
    }
}
