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

            // Wrapper handles the smooth vertical sliding so the Column layout doesn't snap.
            Item {
                id:       wrapper
                required property var modelData
                width:    400

                property bool isInitialized: false

                // If exiting, shrink to 0. Otherwise, grow from 0 to the card's full height.
                height:   card.isExiting ? 0 : (isInitialized ? card.implicitHeight : 0)

                Behavior on height {
                    NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
                }

                Component.onCompleted: {
                    // Trigger the entrance height animation immediately after creation
                    Qt.callLater(() => { wrapper.isInitialized = true })
                }

                NotificationCard {
                    id:           card
                    notification: wrapper.modelData
                }
            }
        }
    }
}
