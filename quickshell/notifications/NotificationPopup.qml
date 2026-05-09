import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../dashboard"
import "../theme"

PanelWindow {
    id: root
    required property var screen

    anchors { bottom: true; right: true }
    implicitWidth:  440
    implicitHeight: 1000
    color:          "transparent"
    exclusiveZone:  0
    mask: Region { item: cardColumn }

    NotificationServer {
        id: server
        actionsSupported:        true
        imageSupported:          true
        bodySupported:           true
        bodyMarkupSupported:     true
        persistenceSupported:    true
        bodyHyperlinksSupported: true

        onNotification: (notif) => {
            notif.tracked = true
            NotificationState.add(notif)
            const home = Quickshell.env("HOME")
            const path = home + "/.config/quickshell/assets/sounds/notification.flac"
            Quickshell.execDetached(["pw-play", path])
        }
    }

    Column {
        id: cardColumn
        spacing: 8
        anchors {
            bottom:       parent.bottom
            right:        parent.right
            bottomMargin: 10
            rightMargin:  10
        }

        Repeater {
            model: server.trackedNotifications

            Item {
                id:      wrapper
                required property var modelData
                width:    400

                // Link height directly to the card's animated implicitHeight.
                // This forces the Column to layout every frame during expansion.
                height:   card.isExiting ? 0 : card.implicitHeight

                Behavior on height {
                    // Only animate height here when exiting (sliding away)
                    enabled: card.isExiting
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                NotificationCard {
                    id:           card
                    notification: wrapper.modelData
                    anchors.bottom: parent.bottom
                }
            }
        }
    }
}
