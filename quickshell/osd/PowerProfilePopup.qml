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
        anchors { fill: parent; margins: root.padding }
        spacing: 4

        Repeater {
            model: [
                { profile: PowerProfile.PowerSaver,  icon: "󰌪", label: "Power Saver" },
                { profile: PowerProfile.Balanced,    icon: "󰗑",  label: "Balanced"    },
                { profile: PowerProfile.Performance, icon: "󰓅", label: "Performance" }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool isActive: PowerProfiles.profile === modelData.profile
                visible: modelData.profile !== PowerProfile.Performance
                    || PowerProfiles.hasPerformanceProfile
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: {
                    let base = PanelColors.profileColor(modelData.profile)
                    let bg = isActive ? base : PanelColors.rowBackground
                    return profileMouse.containsMouse && !isActive ? Qt.lighter(bg, 1.15) : bg
                }
                Behavior on color { ColorAnimation { duration: 150 } }

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
                        color: isActive ? PanelColors.pillForeground : PanelColors.textMain
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.label
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? PanelColors.pillForeground : PanelColors.textMain
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: profileMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        PowerProfiles.profile = modelData.profile
                        SessionState.powerPopupVisible = false
                    }
                }
            }
        }
    }
}
