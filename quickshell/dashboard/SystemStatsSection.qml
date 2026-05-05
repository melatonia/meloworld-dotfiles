import QtQuick
import "../theme"

SectionBase {
    title: "System Resources"
    icon: "󰢮"
    accent: Colors.blue200

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 24

        StatRing {
            id: cpuRing
            label: "CPU"
            icon: ""
            value: SystemStatsState.cpuUsage
            color: Colors.red200
        }

        StatRing {
            label: "RAM"
            icon: ""
            value: SystemStatsState.ramUsage
            color: Colors.blue200
        }

        StatRing {
            label: "GPU"
            icon: "󰢮"
            value: SystemStatsState.gpuUsage
            color: Colors.green200
        }
    }
}
