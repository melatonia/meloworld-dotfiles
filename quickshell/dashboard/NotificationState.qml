pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property alias history: historyModel

    ListModel {
        id: historyModel
    }

    // We keep the server here as a backup, but ideally we'd share the one from the popup.
    // However, to fix the "already registered" warning, we should ensure only one server is active.
    // If we want to capture history, we MUST have a server listening.
    NotificationServer {
        id: server
        onNotification: (n) => {
            historyModel.insert(0, {
                appName: n.appName,
                summary: n.summary,
                body: n.body,
                icon: n.icon || "",
                time: new Date(),
                urgency: n.urgency
            })
            
            if (historyModel.count > 50) {
                historyModel.remove(50)
            }
        }
    }

    function removeByIndex(index) {
        if (index >= 0 && index < historyModel.count) {
            historyModel.remove(index)
        }
    }

    function clearHistory() {
        historyModel.clear()
    }
}
