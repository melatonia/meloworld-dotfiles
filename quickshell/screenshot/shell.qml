import QtQuick
import Quickshell
import Quickshell.Io as Io
import Quickshell.Wayland

ShellRoot {
    id: root

    PanelWindow {
        id: win
        // Target the screen where the mouse currently is
        screen: Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Qt.quit()

            // ─── Background: The Freeze Frame ───
            Image {
                id: masterImg
                anchors.fill: parent
                source: "file:///tmp/qs-master.png"
                fillMode: Image.PreserveAspectCrop
                cache: false

                // Darken everything initially
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
            readonly property int selW: Math.abs(curX - startX)
            readonly property int selH: Math.abs(curY - startY)

            // ─── THE TEAL OVERLAY (Restored & Guaranteed) ───
            // This "cuts a hole" in the darkness and adds the teal border
            Rectangle {
                id: selectionBox
                visible: parent.isDragging || parent.selW > 0
                x: parent.selX
                y: parent.selY
                width: parent.selW
                height: parent.selH

                // Teal color scheme (#80cbc4)
                color: "#2280cbc4" // Subtle teal tint inside
                border.color: "#80cbc4" // Bright teal border
                border.width: 2

                // The "Clear" look: show the original un-dimmed image inside
                Item {
                    anchors.fill: parent
                    anchors.margins: 2 // Don't cover the border
                    clip: true
                    Image {
                        source: "file:///tmp/qs-master.png"
                        x: -parent.parent.x - 2
                        y: -parent.parent.y - 2
                        width: masterImg.width
                        height: masterImg.height
                        fillMode: Image.PreserveAspectCrop
                    }
                }
            }

            // ─── Precision Magnifier ───
            Rectangle {
                visible: parent.isDragging
                width: 100; height: 100
                radius: 50
                color: "black"
                border.color: "#80cbc4"
                border.width: 2
                clip: true

                // Follows mouse with an offset
                x: parent.curX + 20
                y: parent.curY + 20

                Image {
                    source: "file:///tmp/qs-master.png"
                    width: masterImg.width * 4 // 4x Zoom
                    height: masterImg.height * 4
                    x: -(parent.parent.curX * 4) + 50
                    y: -(parent.parent.curY * 4) + 50
                }

                // Crosshair
                Rectangle { color: "#80cbc4"; width: 10; height: 1; anchors.centerIn: parent }
                Rectangle { color: "#80cbc4"; width: 1; height: 10; anchors.centerIn: parent }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor

                // 1. Enable detection of both left and right clicks
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPressed: mouse => {
                    // 2. Discard and Exit immediately on right-click
                    if (mouse.button === Qt.RightButton) {
                        Qt.quit();
                        return;
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
                    // 3. Prevent accidental processing if right button was released
                    if (mouse.button === Qt.RightButton) return;

                    parent.isDragging = false
                    if (parent.selW > 5 && parent.selH > 5) {
                        let globalX = win.screen.x + parent.selX
                        let globalY = win.screen.y + parent.selY

                        cropProc.geometry = `${parent.selW}x${parent.selH}+${globalX}+${globalY}`
                        win.visible = false
                        cropProc.running = true
                    } else {
                        Qt.quit()
                    }
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

            # Crop the master frame we took at the start
            magick /tmp/qs-master.png -crop ${geometry} "$FILE" && \
            wl-copy < "$FILE" && \
            notify-send "Screenshot Captured" "Saved to Pictures/Screenshots" && \
            pw-play "$HOME/.config/mango/assets/sounds/screenshot.flac"
        `]
        onExited: Qt.quit()
    }
}
