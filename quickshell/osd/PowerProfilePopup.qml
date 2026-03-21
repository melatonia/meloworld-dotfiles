import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"

PopupWindow {
    id: root
    visible: SessionState.powerPopupVisible
    implicitWidth: 200
    implicitHeight: column.implicitHeight + 20
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.grey900
        border.color: Colors.grey800
        border.width: 2

        Column {
            id: column
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 4

            Repeater {
                model: [
                    { profile: PowerProfile.PowerSaver,  icon: "󰌪", label: "Power Saver" },
                    { profile: PowerProfile.Balanced,    icon: "󰛲", label: "Balanced"    },
                    { profile: PowerProfile.Performance, icon: "󰓅", label: "Performance" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 30
                    radius: 6
                    visible: modelData.profile !== PowerProfile.Performance
                        || PowerProfiles.hasPerformanceProfile
                    color: PowerProfiles.profile === modelData.profile
                        ? Colors.purple200 : Colors.grey700

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                        }
                        spacing: 8
                        Text {
                            text: modelData.icon
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            color: PowerProfiles.profile === modelData.profile
                                ? Colors.grey900 : Colors.purple200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            color: PowerProfiles.profile === modelData.profile
                                ? Colors.grey900 : Colors.purple200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: if (PowerProfiles.profile !== modelData.profile) parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: {
                            PowerProfiles.profile = modelData.profile
                            SessionState.powerPopupVisible = false
                        }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
