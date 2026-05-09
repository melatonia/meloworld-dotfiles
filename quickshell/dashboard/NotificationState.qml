pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property alias history: historyModel

    ListModel {
        id: historyModel
    }

    function add(n) {
        historyModel.insert(0, {
            appName: n.appName,
            summary: n.summary,
            body:    n.body,
            icon:    n.icon || "",
            time:    new Date(),
            urgency: n.urgency
        })
        if (historyModel.count > 50)
            historyModel.remove(50)
    }

    function removeByIndex(index) {
        if (index >= 0 && index < historyModel.count)
            historyModel.remove(index)
    }

    function clearHistory() {
        historyModel.clear()
    }
}
