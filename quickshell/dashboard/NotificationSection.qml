import QtQuick
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: root
    anchors.fill: parent

    property alias emptyHeight: emptyCol.implicitHeight

    // ── Accent color logic ────────────────────────────────────────────────────
    function accentForEntry(entry) {
        if (entry.urgency === Notification.Critical) return PanelColors.error
        return hashColor(entry.appName)
    }

    function hashColor(str) {
        var hash = 0
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }
        var colors = [
            Colors.teal200, Colors.lightBlue200, Colors.green200,
            Colors.purple200, Colors.orange200, Colors.pink200,
            Colors.yellow200, Colors.cyan200, Colors.deepPurple200,
            Colors.blueGrey300,
        ]
        return colors[Math.abs(hash) % colors.length]
    }

    // ── Empty state ───────────────────────────────────────────────────────────
    Column {
        id: emptyCol
        visible: NotificationState.history.count === 0
        anchors.centerIn: parent
        spacing: 8
        opacity: 0.3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰂛"
            font.pixelSize: 36
            font.family: "JetBrainsMono Nerd Font"
            color: PanelColors.textDim
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "no notifications"
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            color: PanelColors.textDim
        }
    }

    // ── Notification list ─────────────────────────────────────────────────────
    ListView {
        id: notifList
        anchors.fill: parent
        spacing: 8
        model: NotificationState.history
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            SequentialAnimation {
                PropertyAction  { property: "opacity"; value: 0.0 }
                PropertyAction  { property: "x";       value: -16 }
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "x";       to: 0;   duration: 220; easing.type: Easing.OutExpo  }
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x";       to: -200; duration: 220; easing.type: Easing.InExpo  }
                NumberAnimation { property: "opacity"; to: 0;    duration: 180; easing.type: Easing.InCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutExpo }
        }

        delegate: Rectangle {
            id: card
            required property var modelData
            required property int index

            readonly property color accent: root.accentForEntry(modelData)
            property bool expanded: false

            width: notifList.width
            height: cardCol.implicitHeight + 20
            radius: 8
            color: PanelColors.popupBackground
            border.color: accent
            border.width: 2
            clip: true

            Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.OutExpo }
            }

            Rectangle {
                width: 3
                height: parent.height - 16
                radius: 2
                anchors {
                    left: parent.left
                    leftMargin: 6
                    verticalCenter: parent.verticalCenter
                }
                color: accent
                opacity: 0.85
            }

            Column {
                id: cardCol
                anchors {
                    top:        parent.top;   topMargin:   10
                    left:       parent.left;  leftMargin:  18
                    right:      parent.right; rightMargin: 28
                }
                spacing: 4

                Row {
                    width: parent.width

                    Text {
                        text: modelData.appName
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: card.accent
                        width: parent.width - timeText.implicitWidth
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: timeText
                        text: Qt.formatTime(modelData.time, "HH:mm")
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: PanelColors.rowBackground
                    opacity: 0.5
                }

                Text {
                    visible: modelData.summary !== ""
                    width: parent.width
                    text: modelData.summary
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textAccent
                    wrapMode: Text.WordWrap
                    maximumLineCount: card.expanded ? 20 : 2
                    elide: Text.ElideRight
                }

                Text {
                    id: bodyText
                    visible: modelData.body !== ""
                    width: parent.width
                    text: modelData.body
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textMain
                    wrapMode: Text.WordWrap
                    maximumLineCount: card.expanded ? 999 : 2
                    elide: card.expanded ? Text.ElideNone : Text.ElideRight
                    textFormat: Text.PlainText
                }

                Rectangle {
                    id: expandPill
                    visible: modelData.body !== "" && (bodyText.truncated || card.expanded)
                    width: expandRow.implicitWidth + 14
                    height: 22
                    radius: 5
                    color: expandMouse.containsMouse ? PanelColors.rowBackground : "transparent"

                    Row {
                        id: expandRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: card.expanded ? "󰅃" : "󰅀"
                            font.pixelSize: 11
                            font.family: "JetBrainsMono Nerd Font"
                            color: expandMouse.containsMouse ? PanelColors.textAccent : PanelColors.textDim
                        }
                        Text {
                            text: card.expanded ? "Collapse" : "Read more"
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: expandMouse.containsMouse ? PanelColors.textAccent : PanelColors.textDim
                        }
                    }

                    MouseArea {
                        id: expandMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.expanded = !card.expanded
                    }
                }
            }

            Text {
                text: "󰅖"
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
                color: dismissMouse.containsMouse ? PanelColors.error : PanelColors.textDim
                anchors {
                    top:   parent.top;   topMargin:   8
                    right: parent.right; rightMargin: 8
                }

                MouseArea {
                    id: dismissMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationState.removeByIndex(index)
                }
            }
        }
    }

    // ── Scroll hints ──────────────────────────────────────────────────────────
    Rectangle {
        visible: NotificationState.history.count > 0 && !notifList.atYBeginning
        anchors { top: parent.top; topMargin: 4; horizontalCenter: parent.horizontalCenter }
        width: 160; height: 24; radius: 6
        color: PanelColors.rowBackground
        z: 20

        Row {
            anchors.centerIn: parent; spacing: 6
            Text { text: "󰁞"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
            Text { text: "scroll for more"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
        }
    }

    Rectangle {
        visible: NotificationState.history.count > 0 && !notifList.atYEnd
        anchors { bottom: parent.bottom; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
        width: 160; height: 24; radius: 6
        color: PanelColors.rowBackground
        z: 20

        Row {
            anchors.centerIn: parent; spacing: 6
            Text { text: "󰁆"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
            Text { text: "scroll for more"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
        }
    }
}
