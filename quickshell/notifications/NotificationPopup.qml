import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

PanelWindow {
    id: root
    required property var screen

    anchors { bottom: true; right: true }
    implicitWidth: 440
    implicitHeight: notifColumn.implicitHeight + 20
    color: "transparent"
    exclusiveZone: 0

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodySupported: true

        onNotification: (notif) => {
            notif.tracked = true
        }
    }

    Column {
        id: notifColumn
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: 10
            rightMargin: 10
        }
        spacing: 8

        Repeater {
            model: server.trackedNotifications
            delegate: NotificationCard {
                required property var modelData
                notification: modelData
            }
        }
    }
}
