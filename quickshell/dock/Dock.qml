import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root
    required property var screen

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 80
    color: "transparent"
    exclusiveZone: 0

    // ── Dodge logic ───────────────────────────────────
    property int winX: 0
    property int winY: 0
    property int winWidth: 0
    property int winHeight: 0

    // Dock sits at screen bottom, starts at y = screenHeight - 80
    // If window bottom edge (y + height) > screenHeight - 80, dodge
    property bool shouldHide: (winY + winHeight) > (screen.height - 80)

    property bool dockVisible: !shouldHide

    Process {
        id: watchGeom
        command: ["mmsg", "-w", "-x"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var xMatch = line.match(/\S+\s+x\s+(\d+)/)
                var yMatch = line.match(/\S+\s+y\s+(\d+)/)
                var wMatch = line.match(/\S+\s+width\s+(\d+)/)
                var hMatch = line.match(/\S+\s+height\s+(\d+)/)
                if (xMatch) root.winX = parseInt(xMatch[1])
                if (yMatch) root.winY = parseInt(yMatch[1])
                if (wMatch) root.winWidth = parseInt(wMatch[1])
                if (hMatch) root.winHeight = parseInt(hMatch[1])
            }
        }
    }

    // ── Dock container ────────────────────────────────
    Rectangle {
        id: dockBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.dockVisible ? 10 : -70
        
        height: 60
        width: dockRow.implicitWidth + 20
        radius: 12
        color: "#dd212121"

        opacity: root.dockVisible ? 1.0 : 0.0
        
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: [
                    { icon: "/usr/share/icons/Papirus/48x48/apps/firefox-bin.svg",             cmd: ["firefox"] },
                    { icon: "/usr/share/icons/Papirus/48x48/apps/com.mitchellh.ghostty.svg",   cmd: ["ghostty"] },
                    { icon: "/usr/share/icons/Papirus/48x48/apps/cider.svg",                   cmd: ["cider"] },
                    { icon: "/usr/share/icons/Papirus/48x48/apps/aseprite.svg",                cmd: ["/home/melatonia/.local/share/Steam/steamapps/common/Aseprite/aseprite"] },
                    { icon: "/usr/share/icons/Papirus/48x48/apps/com.bitwig.BitwigStudio.svg", cmd: ["bitwig-studio"] }
                ]

                delegate: Item {
                    required property var modelData
                    width: 48
                    height: 48

                    Image {
                        id: appIcon
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        source: modelData.icon
                        smooth: true
                        mipmap: true

                        Behavior on width { NumberAnimation { duration: 100 } }
                        Behavior on height { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            appIcon.width = 48
                            appIcon.height = 48
                        }
                        onExited: {
                            appIcon.width = 40
                            appIcon.height = 40
                        }
                        onClicked: Quickshell.execDetached(modelData.cmd)
                    }
                }
            }
        }
    }
}
