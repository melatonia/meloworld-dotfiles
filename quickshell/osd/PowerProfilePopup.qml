import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"

PopupBase {
    id: root
    implicitWidth:  210
    borderColor:    PanelColors.profileColor(PowerProfiles.profile)
    clipContent:    true
    contentHeight:  column.implicitHeight

    Connections {
        target: SessionState
        function onPowerPopupVisibleChanged() {
            root.animState = SessionState.powerPopupVisible ? "open" : "closing"
        }
    }


    // ── Content ───────────────────────────────────
    Column {
        id: column
        anchors { fill: parent; margins: 10 }
        spacing: 4

        Repeater {
            model: [
                { profile: PowerProfile.PowerSaver,  icon: "󰌪", label: "Power Saver" },
                { profile: PowerProfile.Balanced,    icon: "",  label: "Balanced"    },
                { profile: PowerProfile.Performance, icon: "󰓅", label: "Performance" }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool isActive: PowerProfiles.profile === modelData.profile
                visible: modelData.profile !== PowerProfile.Performance
                    || PowerProfiles.hasPerformanceProfile
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: isActive ? PanelColors.profileColor(modelData.profile) : PanelColors.rowBackground

                Rectangle {
                    visible: !isActive
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: PanelColors.profileColor(modelData.profile)
                }
                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                    spacing: 8
                    Text {
                        text: modelData.icon
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? PanelColors.pillForeground : Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.label
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? PanelColors.pillForeground : Colors.grey200
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: if (!isActive) parent.opacity = 0.8
                    onExited:  parent.opacity = 1.0
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
