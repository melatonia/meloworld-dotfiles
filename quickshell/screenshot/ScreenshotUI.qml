import QtQuick
import Quickshell
import Quickshell.Io as Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: win
    visible: false // Stay hidden until called
    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "qs-screenshot"
    exclusionMode: ExclusionMode.Ignore


    // ─── IPC Handler ───
    Io.IpcHandler {
        target: "screenshot"
        function capture(): void {
            // Append a timestamp to bypass Qt's image cache so the fresh image loads
            masterImg.source = "file:///tmp/qs-master.png?t=" + Date.now()
            win.visible = true
            mainItem.forceActiveFocus()
        }
    }

    // ─── Helper to Reset State ───
    function closeOverlay() {
        win.visible = false
        mainItem.isDragging = false
        mainItem.startX = 0; mainItem.curX = 0
        mainItem.startY = 0; mainItem.curY = 0
    }

    Item {
        id: mainItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.closeOverlay()

        // ─── Background: The Freeze Frame ───
        Image {
            id: masterImg
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            cache: false

            Rectangle {
                anchors.fill: parent
                color: "#99000000"
            }
        }

        // ─── Selection State ───
        property int startX: 0
        property int startY: 0
        property int curX: 0
        property int curY: 0
        property bool isDragging: false

        readonly property int selX: Math.min(startX, curX)
        readonly property int selY: Math.min(startY, curY)
        readonly property int selW: Math.abs(curX - startX) + 1
        readonly property int selH: Math.abs(curY - startY) + 1

        // ─── THE TEAL OVERLAY ───
        Rectangle {
            id: selectionBox
            visible: parent.isDragging || parent.selW > 0
            x: parent.selX
            y: parent.selY
            width: parent.selW
            height: parent.selH

            color: "#2280cbc4"
            border.color: PanelColors.launcher
            border.width: 2

            Item {
                anchors.fill: parent
                anchors.margins: 2
                clip: true
                Image {
                    source: masterImg.source // Reuse the cache-busted source
                    x: -parent.parent.x - 2
                    y: -parent.parent.y - 2
                    width: masterImg.width
                    height: masterImg.height
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }

        // ─── Selection Info Pill ───
        Rectangle {
            visible: parent.isDragging && parent.selW > 5
            x: Math.min(parent.curX + 16, parent.width - width - 8)
            y: Math.min(parent.curY + 16, parent.height - height - 8)
            width: pillText.width + 20
            height: 32
            radius: 6
            color: PanelColors.popupBackground
            border.color: PanelColors.border
            border.width: 2

            Text {
                id: pillText
                anchors.centerIn: parent
                text: parent.parent.selW + "  " + parent.parent.selH
                color: PanelColors.textMain
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: mouse => {
                if (mouse.button === Qt.RightButton) {
                    win.closeOverlay()
                    return
                }
                parent.startX = mouse.x
                parent.startY = mouse.y
                parent.curX = mouse.x
                parent.curY = mouse.y
                parent.isDragging = true
            }

            onPositionChanged: mouse => {
                if (parent.isDragging) {
                    parent.curX = mouse.x
                    parent.curY = mouse.y
                }
            }

            onReleased: mouse => {
                if (mouse.button === Qt.RightButton) return

                parent.isDragging = false
                if (parent.selW > 5 && parent.selH > 5) {
                    let globalX = win.screen.x + parent.selX
                    let globalY = win.screen.y + parent.selY

                    cropProc.geometry = `${parent.selW}x${parent.selH}+${globalX}+${globalY}`
                    win.visible = false
                    cropProc.running = true
                } else {
                    win.closeOverlay()
                }
            }
        }
    }

    // ─── Post-Processing Pipeline ───
    Io.Process {
        id: cropProc
        property string geometry: ""
        command: ["sh", "-c", `
            FILE="$HOME/Pictures/Screenshots/Screenshot From $(date +'%Y-%m-%d %H-%M-%S').png"
            magick /tmp/qs-master.png -crop ${geometry} "$FILE" && \
            wl-copy < "$FILE" && \
            notify-send "Screenshot Captured" "Saved to Pictures/Screenshots" && \
            pw-play "$HOME/.config/quickshell/assets/sounds/screenshot.flac"
        `]
        onExited: win.closeOverlay()
    }
}
