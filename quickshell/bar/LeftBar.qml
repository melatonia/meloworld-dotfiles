import QtQuick
import Quickshell
import "../theme"
import "widgets"

Row {
    spacing: 6

    LauncherWidget {
        anchors.verticalCenter: parent.verticalCenter
    }

    WorkspaceBar {
        anchors.verticalCenter: parent.verticalCenter
    }
}
