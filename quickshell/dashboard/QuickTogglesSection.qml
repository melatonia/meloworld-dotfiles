import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root
    implicitHeight: grid.implicitHeight

    component QuickToggle: Rectangle {
        id: toggle
        property string icon: ""
        property string label: ""
        property bool active: false
        property color accentColor: PanelColors.launcher
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: 8
        color: active ? accentColor : PanelColors.rowBackground
        border.color: active ? Qt.lighter(accentColor, 1.2) : "transparent"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: toggle.icon
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font"
                color: toggle.active ? PanelColors.pillForeground : toggle.accentColor
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: toggle.label
                font.pixelSize: 12
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: toggle.active ? PanelColors.pillForeground : PanelColors.textMain
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                wrapMode: Text.WordWrap
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.clicked()
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "white"
            opacity: ma.containsMouse ? 0.05 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    GridLayout {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 2
        columnSpacing: 10
        rowSpacing: 10

        QuickToggle {
            icon: SystemTogglesState.nightLightOn ? "󰖔" : "󰖙"
            label: "Night Light"
            active: SystemTogglesState.nightLightOn
            accentColor: PanelColors.brightness
            onClicked: SystemTogglesState.toggleNightLight()
        }

        QuickToggle {
            icon: "󰅶"
            label: "Caffeine"
            active: SystemTogglesState.caffeineOn
            accentColor: Colors.orange200
            onClicked: SystemTogglesState.toggleCaffeine()
        }

        QuickToggle {
            icon: NotificationState.dndOn ? "󰂛" : "󰂚"
            label: "DND"
            active: NotificationState.dndOn
            accentColor: Colors.purple200
            onClicked: NotificationState.toggleDnd()
        }

        QuickToggle {
            icon: "󰢮"
            label: "Effects"
            active: SystemTogglesState.compositorEffectsOn
            accentColor: PanelColors.gpuRing
            onClicked: SystemTogglesState.toggleCompositorEffects()
        }
    }
}
