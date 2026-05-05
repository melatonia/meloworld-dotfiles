import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

SectionBase {
    id: root
    accent: PanelColors.launcher
    
    property string username: "User"
    property string hostname: "Host"
    
    Process {
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.username = text.trim()
        }
    }
    
    Process {
        command: ["/usr/bin/hostname"] // FIXED: Using absolute path
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hostname = text.trim()
        }
    }

    Row {
        width: parent.width
        spacing: 16
        topPadding: 4
        // Reduced bottom padding to fix the "weird gap"
        bottomPadding: 4

        // Avatar
        Rectangle {
            width: 64; height: 64
            radius: 32
            color: PanelColors.rowBackground
            border.color: Colors.blue200
            border.width: 2
            clip: true

            Text {
                anchors.centerIn: parent
                text: ""
                font.pixelSize: 36
                font.family: "JetBrainsMono Nerd Font"
                color: PanelColors.textAccent
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                text: "Welcome back,"
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                color: PanelColors.textDim
            }

            Text {
                text: root.username
                font.pixelSize: 24
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: PanelColors.textAccent
            }
            
            Text {
                text: "@" + root.hostname
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                color: Colors.blue200
                opacity: 0.9
            }
        }
    }
}
