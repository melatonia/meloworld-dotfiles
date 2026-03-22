import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../theme"

PopupWindow {
    id: root
    visible: animState !== "closed"
    implicitWidth: 210
    implicitHeight: 600
    color: "transparent"

    property string animState: "closed"

    Connections {
        target: SessionState
        function onPowerPopupVisibleChanged() {
            if (SessionState.powerPopupVisible) {
                animState = "open"
            } else {
                animState = "closing"
            }
        }
    }

    function profileColor(profile) {
        if (profile === PowerProfile.PowerSaver)  return Colors.green200
        if (profile === PowerProfile.Performance) return Colors.red200
        return Colors.orange200
    }

    Rectangle {
        id: innerRect
        width: parent.width
        height: column.implicitHeight + 20
        Behavior on height {
            SmoothedAnimation { velocity: 800; easing.type: Easing.OutExpo }
        }

        y: 0
        opacity: 1.0

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: innerRect; y: 0; opacity: 1.0 }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: innerRect; y: -20; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                from: "*"; to: "open"
                SequentialAnimation {
                    PropertyAction { target: innerRect; property: "y"; value: -20 }
                    PropertyAction { target: innerRect; property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: innerRect; property: "y"
                            to: 0; duration: 250; easing.type: Easing.OutExpo
                        }
                        NumberAnimation {
                            target: innerRect; property: "opacity"
                            to: 1.0; duration: 180; easing.type: Easing.OutCubic
                        }
                    }
                }
            },
            Transition {
                from: "*"; to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: innerRect; property: "y"
                            to: -20; duration: 180; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: innerRect; property: "opacity"
                            to: 0.0; duration: 150; easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        radius: 10
        color: Colors.grey900
        border.color: profileColor(PowerProfiles.profile)
        border.width: 2
        clip: true

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
                    color: isActive ? profileColor(modelData.profile) : Colors.grey800

                    Rectangle {
                        visible: !isActive
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: profileColor(modelData.profile)
                    }
                    Row {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                        spacing: 8
                        Text {
                            text: modelData.icon
                            font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                            color: isActive ? Colors.grey900 : Colors.grey200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: isActive ? Colors.grey900 : Colors.grey200
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: if (!isActive) parent.opacity = 0.8
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
