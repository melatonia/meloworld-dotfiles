import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../theme"

Item {
    id: root

    property string appId:    ""
    property string appLabel: ""
    property string iconName: ""
    property bool   isRunning: false

    implicitWidth:  48
    implicitHeight: 56   // 36px icon + padding + 5px dot area

    // Icon — IconImage resolves XDG icon theme names directly.
    // implicitSize sets both width and height in one go.
    IconImage {
        id: icon
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -4   // shift up slightly to leave room for dot
        implicitSize: 36
        source:       root.iconName

        scale: hoverArea.containsMouse ? 1.12 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    // Running indicator dot
    Rectangle {
        visible:                  root.isRunning
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     2
        width:  5
        height: 5
        radius: 3
        color:  PanelColors.border
    }

    // Tooltip
    ToolTip {
        visible: hoverArea.containsMouse
        text:    root.appLabel
        delay:   500

        contentItem: Text {
            text:           root.appLabel
            color:          PanelColors.textMain
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }

        background: Rectangle {
            color:        PanelColors.barBackground
            radius:       6
            border.color: PanelColors.border
            border.width: 1
        }
    }

    MouseArea {
        id:           hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            // DesktopEntries.byId() looks up the .desktop file.
            // .execute() launches it correctly via the desktop entry spec.
            var entry = DesktopEntries.byId(root.appId)
            if (entry) {
                entry.execute()
            } else {
                Quickshell.execDetached([root.appId])
            }
        }
    }
}
