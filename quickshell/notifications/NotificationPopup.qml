import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

PanelWindow {
    id: root
    required property var screen

    anchors { bottom: true; right: true }
    implicitWidth: 440
    implicitHeight: 1000
    color: "transparent"
    exclusiveZone: 0
    mask: Region { item: notifList }

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodySupported: true

        onNotification: (notif) => {
            notif.tracked = true
            const home = Quickshell.env("HOME")
            const path = home + "/.config/quickshell/assets/sounds/notification.flac"
            Quickshell.execDetached(["pw-play", path])
        }
    }

    ListView {
        id: notifList
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: 10
            rightMargin: 10
        }
        width: 400
        height: contentHeight
        spacing: 8
        interactive: false
        verticalLayoutDirection: ListView.BottomToTop

        model: server.trackedNotifications

        delegate: NotificationCard {
            required property var modelData
            notification: modelData
        }

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            NumberAnimation { property: "x"; from: 420; to: 0; duration: 250; easing.type: Easing.OutExpo }
        }

        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic }
        }
    }
}
