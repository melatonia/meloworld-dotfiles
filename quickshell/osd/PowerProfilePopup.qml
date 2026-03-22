import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"

PopupWindow {
    id: root
    visible: SessionState.powerPopupVisible
    implicitWidth: 210
    implicitHeight: column.implicitHeight + 20
    Behavior on implicitHeight {
        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
    }
    color: "transparent"

    function profileColor(profile) {
        if (profile === PowerProfile.PowerSaver)  return Colors.green200
        if (profile === PowerProfile.Performance) return Colors.red200
        return Colors.orange200
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.grey900
        border.color: profileColor(PowerProfiles.profile)
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
                    { profile: PowerProfile.Balanced,    icon: "", label: "Balanced"    },
                    { profile: PowerProfile.Performance, icon: "󰓅", label: "Performance" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.profile !== PowerProfile.Performance
                        || PowerProfiles.hasPerformanceProfile
                    width: parent.width
                    height: visible ? 34 : 0
                    radius: 6
                    color: PowerProfiles.profile === modelData.profile
                        ? profileColor(modelData.profile) : Colors.grey800

                    // Left accent stripe for inactive items
                    Rectangle {
                        visible: PowerProfiles.profile !== modelData.profile
                        width: 3
                        height: parent.height - 10
                        radius: 2
                        anchors {
                            left: parent.left
                            leftMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        color: profileColor(modelData.profile)
                    }

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                        }
                        spacing: 8
                        Text {
                            text: modelData.icon
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: PowerProfiles.profile === modelData.profile
                                ? Colors.grey900 : Colors.grey200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: PowerProfiles.profile === modelData.profile
                                ? Colors.grey900 : Colors.grey200
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
