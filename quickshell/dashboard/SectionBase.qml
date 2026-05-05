import QtQuick
import "../theme"

Item {
    id: root
    property string title: ""
    property string icon: ""
    property color accent: PanelColors.launcher
    default property alias content: container.data
    
    width: parent.width
    implicitHeight: mainCol.implicitHeight

    Column {
        id: mainCol
        width: parent.width
        spacing: 12

        // Header Row
        Row {
            id: headerRow
            width: parent.width
            spacing: 8
            visible: root.title !== ""
            leftPadding: 4
            
            Text {
                text: root.icon
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font"
                color: root.accent
                anchors.verticalCenter: parent.verticalCenter
                visible: root.icon !== ""
            }

            Text {
                text: root.title
                font.pixelSize: 16
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: PanelColors.textMain
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Content Container
        Column {
            id: container
            width: parent.width
            spacing: 10
        }
        
        // Spacing before divider
        Item { width: 1; height: 8 }

        // Divider (Bolder 4px height matching rofi border standards)
        Rectangle {
            width: parent.width
            height: 4
            radius: 2
            color: PanelColors.rowBackground
            opacity: 0.6
        }
        
        // Spacing after divider
        Item { width: 1; height: 8 }
    }
}
