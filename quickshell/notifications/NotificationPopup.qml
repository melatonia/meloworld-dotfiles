import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../dashboard"
import "../theme"

PanelWindow {
    id: root
    required property var screen

    // ─── Notification sound ─────────────────────────────────────────────────
    // Change this path to point at any file pw-play can handle.
    readonly property string soundPath:
        Quickshell.env("HOME") + "/.config/quickshell/assets/sounds/notification.flac"

    anchors { bottom: true; right: true }

    implicitWidth:  440
    implicitHeight: 1000

    color:         "transparent"
    exclusiveZone: 0

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
            Quickshell.execDetached(["pw-play", root.soundPath])
        }
    }

    // ─── Card stack ────────────────────────────────────────────────────────
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
                id:       wrapper
                required property var modelData
                width:    400

                // Track card height while alive; collapse to 0 on exit.
                // The null guard prevents a binding error during the brief
                // window between model removal and delegate destruction.
                height: (card && card.isExiting) ? 0 : (card ? card.implicitHeight : 0)

                Behavior on height {
                    enabled: card ? card.isExiting : false
                    NumberAnimation {
                        duration:    300
                        easing.type: Easing.OutQuart
                    }
                }

                NotificationCard {
                    id:           card
                    notification: wrapper.modelData
                    // Cards grow upward: anchor to bottom of wrapper so
                    // expansion pushes neighbours above, not below.
                    anchors.bottom: parent.bottom
                }
            }
        }
    }
}
