import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Rectangle {
    id: root
    required property Notification notification

    readonly property int cardWidth:          400
    readonly property int dismissMs:          4000
    readonly property int collapsedBodyLines: 3

    property bool expanded: false
    property bool isExiting: false

    visible: notification !== null

    width:          cardWidth
    height:         implicitHeight
    implicitHeight: cardContent.implicitHeight + 28

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    radius: 10
    color:  PanelColors.popupBackground

    border.color: accentColor
    border.width: 2
    clip:         true
    layer.enabled: true

    opacity: 0
    x:       cardWidth + 40
    y:       0

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target:      root
            property:    "opacity"
            from:        0
            to:          1
            duration:    400
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target:      root
            property:    "x"
            from:        cardWidth + 40
            to:          0
            duration:    500
            easing.type: Easing.OutQuart
        }
    }

    readonly property color accentColor: {
        if (!notification) return Colors.blueGrey300
        if (notification.urgency === Notification.Critical) return PanelColors.error
        if (notification.hints["x-hint-color"]) return notification.hints["x-hint-color"]
        return hashColor(notification.appName)
    }

    function hashColor(str) {
        if (!str || str === "") return Colors.blueGrey300
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

    readonly property bool bodyIsLong: {
        if (!notification) return false
        var body = notification.body ?? ""
        if (body === "") return false
        return body.length > 120 || body.split("\n").length > 3
    }

    property bool dismissing: false

    function pauseDismiss() {
        dismissTimer.stop()
        ringTimer.stop()
        ringFadeInAnim.stop()
        hoverEnterAnim.start()
    }

    function resumeDismiss() {
        hoverEnterAnim.stop()
        ringFadeInAnim.start()
        timerItem.startTime = Date.now() - (1.0 - timerRing.progress) * root.dismissMs
        dismissTimer.interval = timerRing.progress * root.dismissMs
        dismissTimer.restart()
        ringTimer.start()
    }

    Component.onCompleted: {
        enterAnim.start()
        dismissTimer.start()
        timerItem.startTime = Date.now()
    }

    function dismiss() {
        if (root.dismissing) return
        root.dismissing = true
        dismissTimer.stop()
        ringTimer.running = false
        exitAnim.dismissMode = true
        exitAnim.start()
    }

    function expire() {
        if (root.dismissing) return
        root.dismissing = true
        dismissTimer.stop()
        ringTimer.running = false
        exitAnim.dismissMode = false
        exitAnim.start()
    }

    property var pendingAction: null

    function invokeAction(action) {
        if (root.dismissing) return
        root.dismissing = true
        dismissTimer.stop()
        ringTimer.running = false
        root.pendingAction = action
        exitAnim.dismissMode = true
        exitAnim.start()
    }

    SequentialAnimation {
        id: exitAnim
        property bool dismissMode: false
        ParallelAnimation {
            NumberAnimation {
                target:      root
                property:    "x"
                to:          cardWidth + 20
                duration:    250
                easing.type: Easing.InExpo
            }
            NumberAnimation {
                target:      root
                property:    "opacity"
                to:          0
                duration:    200
                easing.type: Easing.InCubic
            }
        }
        ScriptAction { script: { root.isExiting = true } }
        PauseAnimation { duration: 200 }
        ScriptAction {
            script: {
                if (root.pendingAction) {
                    root.pendingAction.invoke()
                    root.pendingAction = null
                } else if (exitAnim.dismissMode) {
                    notification.dismiss()
                } else {
                    notification.expire()
                }
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: root.dismissMs
        onTriggered: root.expire()
    }

    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        hoverEnabled: true

        SequentialAnimation {
            id: hoverEnterAnim
            ScriptAction { script: {
                dismissTimer.stop()
                ringTimer.stop()
            }}
            NumberAnimation { target: timerRing; property: "progress"; to: 1.0; duration: 200 }
            PauseAnimation  { duration: 100 }
            NumberAnimation { target: timerRing; property: "opacity"; to: 0.0; duration: 200 }
        }

        NumberAnimation {
            id:       ringFadeInAnim
            target:   timerRing
            property: "opacity"
            to:       1.0
            duration: 150
        }

        onEntered: root.pauseDismiss()
        onExited:  root.resumeDismiss()
        onClicked: root.dismiss()
    }

    Rectangle {
        id: leftStrip
        width:  4
        height: parent.height - 24
        radius: 2
        anchors {
            left:           parent.left
            leftMargin:     7
            verticalCenter: parent.verticalCenter
        }
        color:   root.accentColor
        opacity: 0.9
    }

    Column {
        id: cardContent
        anchors {
            // FIX: Anchor to TOP instead of BOTTOM to prevent internal "sinking"
            // content will now expand downwards relative to the card's head.
            top:          parent.top
            topMargin:    14
            left:         parent.left
            right:        parent.right
            leftMargin:   24
            rightMargin:  16
        }
        spacing: 0

        Row {
            width:   parent.width
            height:  22
            spacing: 8

            Image {
                id:      appIconImg
                visible: (notification?.appIcon ?? "") !== "" && status === Image.Ready
                source:  (notification?.appIcon ?? "") !== "" ? "image://icon/" + notification.appIcon : ""
                width:   18
                height:  18
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                smooth:   true
            }

            Text {
                text:           notification?.appName ?? ""
                font.pixelSize: 13
                font.bold:      true
                font.family:    "JetBrainsMono Nerd Font"
                color:          root.accentColor
                elide:          Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - timerItem.width - (appIconImg.visible ? appIconImg.width + parent.spacing : 0) - parent.spacing
            }

            Item {
                id:     timerItem
                width:  32
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                property real startTime: Date.now()

                Canvas {
                    id:     timerRing
                    width:  22
                    height: 22
                    anchors.right: parent.right
                    property real progress: 1.0
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.strokeStyle = root.accentColor
                        ctx.lineWidth   = 2
                        ctx.lineCap     = "round"
                        ctx.beginPath()
                        ctx.arc(11, 11, 8, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * progress), false)
                        ctx.stroke()
                    }
                    onProgressChanged: requestPaint()
                }

                Timer {
                    id:       ringTimer
                    interval: 50
                    running:  true
                    repeat:   true
                    onTriggered: {
                        timerRing.progress = Math.max(0, (root.dismissMs - (Date.now() - timerItem.startTime)) / root.dismissMs)
                    }
                }
            }
        }

        Rectangle {
            width:   parent.width
            height:  1
            color:   PanelColors.rowBackground
            opacity: 0.6
        }

        Item { width: 1; height: 8 }

        Row {
            width:   parent.width
            spacing: 10

            Column {
                width:   notifImageFrame.visible ? parent.width - notifImageFrame.width - parent.spacing : parent.width
                spacing: 4

                Text {
                    visible:          (notification?.summary ?? "") !== ""
                    text:             notification?.summary ?? ""
                    font.pixelSize:   18
                    font.bold:        true
                    font.family:      "JetBrainsMono Nerd Font"
                    color:            PanelColors.textAccent
                    width:            parent.width
                    wrapMode:         Text.WordWrap
                    maximumLineCount: 2
                    elide:            Text.ElideRight
                }

                Item {
                    id:               bodyTextContainer
                    visible:          (notification?.body ?? "") !== ""
                    width:            parent.width
                    height:           bodyText.implicitHeight
                    clip:             true

                    Behavior on height {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        id:               bodyText
                        text:             notification?.body ?? ""
                        font.pixelSize:   14
                        font.family:      "JetBrainsMono Nerd Font"
                        color:            PanelColors.textMain
                        width:            parent.width
                        wrapMode:         Text.WordWrap
                        maximumLineCount: root.expanded ? -1 : root.collapsedBodyLines
                        elide:            root.expanded  ? Text.ElideNone : Text.ElideRight
                        textFormat:       Text.PlainText
                    }
                }
            }

            Rectangle {
                id:           notifImageFrame
                visible:      (notification?.image ?? "") !== "" && notifImageInner.status === Image.Ready
                width:        visible ? 60 : 0
                height:       60
                radius:       8
                color:        "transparent"
                border.color: root.accentColor
                border.width: 3
                clip:         true

                Image {
                    id:              notifImageInner
                    anchors.fill:    parent
                    anchors.margins: 3
                    fillMode:        Image.PreserveAspectCrop
                    source:          notification?.image ?? ""
                    smooth:          true
                }
            }
        }

        Item {
            width: 1;
            height: (expandButton.visible || actionArea.visible) ? 10 : 0
        }

        Item {
            id:      expandButton
            visible: root.bodyIsLong
            width:   parent.width
            height:  visible ? 32 : 0

            Rectangle {
                width:   parent.width
                height:  1
                color:   root.accentColor
                opacity: 0.2
                anchors.top: parent.top
            }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text:           root.expanded ? "󰅃" : "󰅀"
                    font.pixelSize: 17
                    font.family:    "JetBrainsMono Nerd Font"
                    color:          root.accentColor
                    opacity:        expandButtonMouse.containsMouse ? 1.0 : 0.65
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Text {
                    text:           root.expanded ? "Collapse" : "Show more"
                    font.pixelSize: 15
                    font.bold:      true
                    font.family:    "JetBrainsMono Nerd Font"
                    color:          root.accentColor
                    opacity:        expandButtonMouse.containsMouse ? 1.0 : 0.65
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
            }

            MouseArea {
                id:           expandButtonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:    root.pauseDismiss()
                onExited:     if (!cardMouseArea.containsMouse) root.resumeDismiss()
                onClicked:    root.expanded = !root.expanded
            }
        }

        Item {
            id:      actionArea
            visible: (notification?.actions?.length ?? 0) > 0
            width:   parent.width
            // Bottom margin fixed to 12px to match the accent strip
            height:  visible ? actionsRow.implicitHeight + 12 : 0

            Rectangle {
                width:   parent.width
                height:  1
                color:   root.accentColor
                opacity: 0.25
                anchors.top: parent.top
            }

            Row {
                id: actionsRow
                anchors {
                    top:       parent.top
                    topMargin: 12
                    left:      parent.left
                    right:     parent.right
                }
                spacing: 8

                Repeater {
                    model: notification?.actions ?? []
                    Rectangle {
                        required property var modelData
                        height: 30
                        width:  actionLabel.implicitWidth + 24
                        radius: 6
                        color: Qt.lighter(root.accentColor, actionMouse.containsMouse ? 1.15 : 1.0)
                        scale: actionMouse.containsMouse ? 1.03 : 1.0

                        Behavior on color { ColorAnimation  { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

                        Text {
                            id:               actionLabel
                            text:             modelData.text
                            font.pixelSize:   13
                            font.bold:        true
                            font.family:      "JetBrainsMono Nerd Font"
                            color:            PanelColors.popupBackground
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id:           actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onEntered:    root.pauseDismiss()
                            onExited:     if (!cardMouseArea.containsMouse) root.resumeDismiss()
                            onClicked:    root.invokeAction(modelData)
                        }
                    }
                }
            }
        }
    }
}
