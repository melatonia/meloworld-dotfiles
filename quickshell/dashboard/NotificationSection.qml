import QtQuick
import "../theme"

Item {
    id: root
    anchors.fill: parent

    // Clear button — floats top-right, z-stacked above list
    Text {
        id: clearBtn
        anchors { top: parent.top; right: parent.right }
        text: "Clear All"
        font.pixelSize: 11
        font.family: "JetBrainsMono Nerd Font"
        color: clearMouse.containsMouse ? PanelColors.error : PanelColors.textDim
        visible: NotificationState.history.count > 0
        z: 10

        MouseArea {
            id: clearMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationState.clearHistory()
        }
    }

    // Empty state
    Column {
        visible: NotificationState.history.count === 0
        anchors.centerIn: parent
        spacing: 8
        opacity: 0.3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰂛"
            font.pixelSize: 48
            font.family: "JetBrainsMono Nerd Font"
            color: PanelColors.textDim
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: PanelColors.textDim
        }
    }

    ListView {
        id: notifList
        anchors.fill: parent
        spacing: 12
        model: NotificationState.history
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            SequentialAnimation {
                PropertyAction { property: "opacity"; value: 0.0 }
                PropertyAction { property: "x"; value: -20 }
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "x"; to: 0; duration: 250; easing.type: Easing.OutExpo }
                }
            }
        }

        remove: Transition {
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { property: "x"; to: -(width + 40); duration: 250; easing.type: Easing.InExpo }
                    NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                }
            }
        }

        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutExpo }
        }

        delegate: Rectangle {
            id: card
            required property var modelData
            required property int index

            width: notifList.width
            height: cardCol.implicitHeight + 32
            radius: 10
            color: PanelColors.popupBackground
            border.color: PanelColors.network
            border.width: 2

            property bool expanded: false

            Behavior on height {
                NumberAnimation { duration: 250; easing.type: Easing.OutExpo }
            }

            Column {
                id: cardCol
                anchors {
                    top: parent.top; left: parent.left; right: parent.right
                    topMargin: 14; leftMargin: 24; rightMargin: 16
                }
                spacing: 0

                Row {
                    width: parent.width; height: 22
                    Text {
                        text: modelData.appName
                        font.pixelSize: 16; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.network
                        width: parent.width - timeText.width - 24
                        elide: Text.ElideRight
                    }
                    Text {
                        id: timeText
                        text: Qt.formatTime(modelData.time, "HH:mm")
                        font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textDim
                    }
                }

                Rectangle { width: parent.width; height: 2; color: PanelColors.rowBackground; opacity: 0.6 }
                Item { width: 1; height: 8 }

                Text {
                    width: parent.width
                    text: modelData.summary
                    font.pixelSize: 18; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textAccent
                    wrapMode: Text.WordWrap
                    maximumLineCount: card.expanded ? 10 : 2
                    elide: Text.ElideRight
                }

                Item { width: 1; height: 4 }

                Text {
                    id: bodyText
                    width: parent.width
                    text: modelData.body
                    font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textMain
                    wrapMode: Text.WordWrap
                    maximumLineCount: card.expanded ? 999 : 2
                    elide: card.expanded ? Text.ElideNone : Text.ElideRight
                    visible: text !== ""
                }

                Item { width: 1; height: 8; visible: showMorePill.visible }

                Rectangle {
                    id: showMorePill
                    visible: modelData.body !== "" && (bodyText.truncated || card.expanded)
                    width: showMoreRow.implicitWidth + 16
                    height: 28
                    radius: 6
                    color: moreMouse.containsMouse ? PanelColors.rowBackground : "transparent"

                    Row {
                        id: showMoreRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: card.expanded ? "󰅃" : "󰅀"
                            font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
                            color: moreMouse.containsMouse ? PanelColors.textAccent : PanelColors.textDim
                        }
                        Text {
                            text: card.expanded ? "Collapse" : "Read full message"
                            font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: moreMouse.containsMouse ? PanelColors.textAccent : PanelColors.textDim
                        }
                    }

                    MouseArea {
                        id: moreMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: card.expanded = !card.expanded
                    }
                }
            }

            Text {
                text: "󰅖"
                font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"
                color: discardMouse.containsMouse ? PanelColors.error : PanelColors.textDim
                anchors { top: parent.top; right: parent.right; margins: 10 }
                z: 10
                MouseArea {
                    id: discardMouse; anchors.fill: parent; hoverEnabled: true
                    onClicked: NotificationState.removeByIndex(index)
                }
            }
        }
    }

    // Scroll hints
    Rectangle {
        visible: !notifList.atYBeginning
        anchors { top: parent.top; topMargin: -4; horizontalCenter: parent.horizontalCenter }
        width: 180; height: 28; radius: 8
        color: PanelColors.rowBackground
        z: 20
        Row {
            anchors.centerIn: parent; spacing: 8
            Text { text: "󰁞"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
            Text { text: "scroll for more"; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
        }
    }

    Rectangle {
        visible: !notifList.atYEnd
        anchors { bottom: parent.bottom; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
        width: 180; height: 28; radius: 8
        color: PanelColors.rowBackground
        z: 20
        Row {
            anchors.centerIn: parent; spacing: 8
            Text { text: "󰁆"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
            Text { text: "scroll for more"; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
        }
    }
}
