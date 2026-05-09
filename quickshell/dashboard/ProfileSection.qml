import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

SectionBase {
    id: root
    accent: PanelColors.launcher

    property string username: "User"
    property string hostname: "Host"
    property string avatarPath: ""
    // Persistent local storage path
    property string localAvatar: Quickshell.env("HOME") + "/.config/quickshell/avatar.png"

    Process {
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.username = text.trim()
                checkLocalAvatar.running = true
            }
        }
    }

    FileView {
        path: "/etc/hostname"
        onLoaded: root.hostname = text().trim()
    }

    // PRIORITY 1: Check for manual override in config folder
    Process {
        id: checkLocalAvatar
        command: ["test", "-f", root.localAvatar]
        onExited: {
            if (exitCode === 0) {
                root.avatarPath = "file://" + root.localAvatar;
            } else {
                checkAccountsService.running = true;
            }
        }
    }

    // PRIORITY 2: Fallback to System/Gnome settings
    Process {
        id: checkAccountsService
        command: ["sh", "-c", "grep '^Icon=' /var/lib/AccountsService/users/$USER | cut -d= -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                let path = text.trim();
                if (path.length > 0) {
                    root.avatarPath = "file://" + path;
                } else {
                    root.avatarPath = "file://" + Quickshell.env("HOME") + "/.face";
                }
            }
        }
    }

    // Manual Picker logic
    Process {
        id: manualPicker
        command: ["zenity", "--file-selection", "--title=Select Profile Picture"]
        stdout: StdioCollector {
            onStreamFinished: {
                let selected = text.trim();
                if (selected.length > 0) {
                    saveAvatar.command = ["cp", selected, root.localAvatar];
                    saveAvatar.running = true;
                }
            }
        }
    }

    Process {
        id: saveAvatar
        onExited: {
            // Reset path to force reload from disk
            root.avatarPath = "";
            root.avatarPath = "file://" + root.localAvatar;
        }
    }

    Row {
        width: parent.width
        spacing: 16
        topPadding: 4
        bottomPadding: 4

        Item {
            id: avatarContainer
            width: 64
            height: 64

            Image {
                id: profileImg
                anchors.fill: parent
                anchors.margins: 2
                source: root.avatarPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
            }

            Text {
                visible: profileImg.status !== Image.Ready
                anchors.centerIn: parent
                text: ""
                font.pixelSize: 36
                font.family: "JetBrainsMono Nerd Font"
                color: PanelColors.textAccent
            }

            Rectangle {
                id: borderOverlay
                anchors.fill: parent
                color: "transparent"
                border.width: 2
                border.color: profileMouseArea.containsMouse ? PanelColors.textAccent : PanelColors.profile
                radius: 5

                scale: profileMouseArea.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                MouseArea {
                    id: profileMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: manualPicker.running = true
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: "#80000000"
                    visible: profileMouseArea.containsMouse
                    radius: 2

                    Text {
                        anchors.centerIn: parent
                        text: "󰏫"
                        color: "white"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                    }
                }
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
                color: PanelColors.profile
                opacity: 0.9
            }
        }
    }
}
