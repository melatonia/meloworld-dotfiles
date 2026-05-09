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

    // Column anchored to the bottom-right. Grows upward as cards are added.
    // No ListView, no rotation — input coordinates are exactly as authored.
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

            // Wrapper tracks the card's full height so the Column slot
            // stays correct during expand/collapse.
            Item {
                id:       wrapper
                required property var modelData
                width:    400
                height:   card.implicitHeight

                NotificationCard {
                    id:           card
                    notification: wrapper.modelData
                }
            }
        }
    }
}
