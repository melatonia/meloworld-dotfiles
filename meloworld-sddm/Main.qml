import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Rectangle {
    id: root
    anchors.fill: parent
    color: root.clrBg
    visible: true
    opacity: 0

    
    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: 800
        easing.type: Easing.OutCubic
    }

    // ── Design System ─────────────────────────────────────────
    property color clrBg:       (typeof config !== 'undefined' && config.background_color) ? config.background_color : "#212121"
    property color clrBgAlt:    "#2d2d2d"
    property color clrFg:       "#ffffffdd"
    property color clrFgDim:    "#616161"
    property color clrAccent:   (typeof config !== 'undefined' && config.accent_color) ? config.accent_color : "#80cbc4"
    property color clrBorder:   "#424242"
    property color clrUrgent:   (typeof config !== 'undefined' && config.urgent_color) ? config.urgent_color : "#ef9a9a"
    property color clrReboot:   "#ffcc80"
    property color clrSession:  "#a5d6a7"
    property color clrClock:    "#ffffffdd"
    property color clrPillFg:   "#212121"

    property string fontMain: (typeof config !== 'undefined' && config.font) ? config.font : "JetBrainsMono Nerd Font"
    property int radiusLarge: 12
    property int radiusMed:   8
    property int radiusSmall: 5

    property int    selectedIndex: 0
    property int    sessionIndex:  0
    property string sessionLabel:  "session"

    // ── Background ────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: {
            if (typeof config === 'undefined' || !config.background) return "assets/wallpaper.jpeg";
            var bg = config.background;
            if (bg.indexOf(":/") === -1 && bg.indexOf("/") === 0) return "file://" + bg;
            return bg;
        }
        fillMode: Image.PreserveAspectCrop

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.2
        }
    }

    // ── Top Bar (Clock) ───────────────────────────────────────
    BarContainer {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 12
        }
        visible: typeof primaryScreen !== 'undefined' ? primaryScreen : true

        PillButton {
            pillColor: root.clrClock
            fontMain: root.fontMain
            label: " " + timeLabel
            
            property string timeLabel: Qt.formatDateTime(new Date(), "HH:mm")

            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: parent.timeLabel = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
    }

    // ── Center Login Card ─────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.max(320, parent.width * 0.18)
        height: cardLayout.implicitHeight + 20
        radius: root.radiusLarge
        color: root.clrBg
        border.width: 3
        border.color: root.clrBorder
        visible: typeof primaryScreen !== 'undefined' ? primaryScreen : true

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 0; to: 10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10; to: -10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: -10; to: 10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10; to: 0; duration: 50; easing.type: Easing.OutQuad }
        }

        ColumnLayout {
            id: cardLayout
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 8

            // User Selection
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    id: userRepeater
                    model: userModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: root.radiusMed
                        color: index === root.selectedIndex
                            ? root.clrAccent
                            : (userMa.containsMouse || delegateItem.activeFocus ? root.clrBorder : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        activeFocusOnTab: true
                        id: delegateItem
                        
                        KeyNavigation.tab: (index === userRepeater.count - 1) ? passwordField : undefined
                        KeyNavigation.backtab: (index === 0) ? sessionPill : undefined

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.selectedIndex = index
                                passwordField.forceActiveFocus()
                                event.accepted = true
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                text: ""
                                font.family: root.fontMain
                                font.pixelSize: 14
                                color: index === root.selectedIndex ? root.clrPillFg : root.clrFg
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (model.name || model.realName || "user")
                                font.pixelSize: 14
                                font.bold: index === root.selectedIndex
                                font.family: root.fontMain
                                color: index === root.selectedIndex ? root.clrPillFg : root.clrFg
                            }
                        }

                        MouseArea {
                            id: userMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index
                                passwordField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 2 }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: root.radiusMed
                    color: root.clrBgAlt
                    border.width: 2
                    border.color: passwordField.activeFocus ? root.clrAccent : "transparent"

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    TextInput {
                        id: passwordField
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        font.pixelSize: 14
                        font.family: root.fontMain
                        color: root.clrFg
                        selectionColor: root.clrAccent
                        clip: true
                        
                        KeyNavigation.tab: loginButton
                        KeyNavigation.backtab: userRepeater

                        onAccepted: loginAction()

                        Text {
                            anchors.fill: parent
                            text: "password"
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            font.family: root.fontMain
                            color: root.clrFgDim
                            visible: passwordField.text.length === 0 && !passwordField.activeFocus
                        }
                        
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰪛"
                            font.family: root.fontMain
                            color: root.clrUrgent
                            visible: (passwordField.modifiers & Qt.CapsLockModifier)
                            ToolTip.visible: maCaps.containsMouse
                            ToolTip.text: "Caps Lock is ON"
                            MouseArea { id: maCaps; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }

            // Error Message
            Text {
                id: errorText
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: ""
                font.pixelSize: 12
                font.family: root.fontMain
                color: root.clrUrgent
                wrapMode: Text.WordWrap
                visible: text.length > 0
            }

            // Login Button
            PillButton {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                label: "Login"
                pillColor: root.clrAccent
                fontMain: root.fontMain
                onClicked: loginAction()
                KeyNavigation.tab: rebootButton
                KeyNavigation.backtab: passwordField
            }
        }
    }

    // ── Bottom Left (Session) ─────────────────────────────────
    BarContainer {
        id: bottomLeftBar
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 12
        }
        visible: typeof primaryScreen !== 'undefined' ? primaryScreen : true

        PillButton {
            id: sessionPill
            label: " " + root.sessionLabel
            pillColor: root.clrSession
            fontMain: root.fontMain
            onClicked: {
                sessionMenuContainer.toggle()
            }
            KeyNavigation.tab: userRepeater.count > 0 ? userRepeater.itemAt(0) : passwordField
            KeyNavigation.backtab: shutdownButton
        }
    }

    Item {
        id: sessionMenuContainer
        visible: animState !== "closed"
        width: 180
        height: sessionColumn.implicitHeight + 20
        anchors {
            bottom: bottomLeftBar.top
            left: bottomLeftBar.left
            bottomMargin: 10
        }

        property string animState: "closed"

        function open() { animState = "open" }
        function close() { animState = "closing" }
        function toggle() { if (animState === "open") close(); else open(); }

        Rectangle {
            id: innerSessionRect
            width: parent.width
            height: parent.height
            radius: root.radiusLarge
            color: root.clrBg
            border.color: root.clrSession
            border.width: 2
            clip: true

            y: 0
            opacity: 1.0

            states: [
                State {
                    name: "open"
                    when: sessionMenuContainer.animState === "open"
                    PropertyChanges { target: innerSessionRect; y: 0; opacity: 1.0 }
                },
                State {
                    name: "closing"
                    when: sessionMenuContainer.animState === "closing"
                    PropertyChanges { target: innerSessionRect; y: 20; opacity: 0.0 }
                }
            ]

            transitions: [
                Transition {
                    to: "open"
                    SequentialAnimation {
                        PropertyAction { target: innerSessionRect; property: "y"; value: 20 }
                        PropertyAction { target: innerSessionRect; property: "opacity"; value: 0.0 }
                        ParallelAnimation {
                            NumberAnimation { target: innerSessionRect; property: "y"; to: 0; duration: 250; easing.type: Easing.OutExpo }
                            NumberAnimation { target: innerSessionRect; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                        }
                    }
                },
                Transition {
                    to: "closing"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation { target: innerSessionRect; property: "y"; to: 20; duration: 180; easing.type: Easing.InCubic }
                            NumberAnimation { target: innerSessionRect; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                        }
                        ScriptAction { script: sessionMenuContainer.animState = "closed" }
                    }
                }
            ]

            Column {
                id: sessionColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 10
                }
                spacing: 4

                Repeater {
                    model: typeof sessionModel !== 'undefined' ? sessionModel : null
                    delegate: Rectangle {
                        readonly property bool isActive: root.sessionIndex === index
                        width: sessionColumn.width
                        height: 34
                        radius: 6
                        color: isActive ? root.clrSession : root.clrBgAlt

                        Rectangle {
                            visible: !isActive
                            width: 3
                            height: parent.height - 10
                            radius: 2
                            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                            color: root.clrSession
                        }

                        Text {
                            anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            text: model.name || model.display || "Session"
                            color: isActive ? root.clrBg : root.clrFg
                            font.pixelSize: 13
                            font.bold: true
                            font.family: root.fontMain
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: if (!isActive) parent.opacity = 0.8
                            onExited: parent.opacity = 1.0
                            onClicked: {
                                root.sessionIndex = index
                                updateSession()
                                sessionMenuContainer.close()
                            }
                        }

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }

    // ── Bottom Right (Power) ──────────────────────────────────
    BarContainer {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 12
        }
        visible: typeof primaryScreen !== 'undefined' ? primaryScreen : true

        PillButton {
            id: rebootButton
            label: " Reboot"
            pillColor: root.clrReboot
            fontMain: root.fontMain
            onClicked: sddm.reboot()
            KeyNavigation.tab: shutdownButton
            KeyNavigation.backtab: loginButton
        }

        PillButton {
            id: shutdownButton
            label: "⏻ Shutdown"
            pillColor: root.clrUrgent
            fontMain: root.fontMain
            onClicked: sddm.powerOff()
            KeyNavigation.tab: sessionPill
            KeyNavigation.backtab: rebootButton
        }
    }

    // ── Logic ─────────────────────────────────────────────────
    function updateSession() {
        if (typeof sessionModel === 'undefined' || !sessionModel) return;
        var count = (typeof sessionModel.count !== 'undefined') ? sessionModel.count : (typeof sessionModel.rowCount === 'function' ? sessionModel.rowCount() : 0)
        if (count > 0 && root.sessionIndex < count) {
            var idx = sessionModel.index(root.sessionIndex, 0)
            var name = sessionModel.data(idx, Qt.DisplayRole)
            root.sessionLabel = name || "Session"
        }
    }

    function loginAction() {
        if (typeof userModel === 'undefined' || !userModel || userModel.count === 0) return
        errorText.text = ""

        var idx = userModel.index(root.selectedIndex, 0)
        var username = userModel.data(idx, "name") || userModel.data(idx, 0x0101) || userModel.data(idx, Qt.DisplayRole) || userModel.lastUser

        sddm.login(username, passwordField.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "incorrect password"
            passwordField.text = ""
            passwordField.forceActiveFocus()
            shakeAnim.start()
        }
        function onLoginSucceeded() {
            errorText.color = root.clrAccent
            errorText.text = "logging in..."
        }
    }

    Component.onCompleted: {
        updateSession()
        passwordField.forceActiveFocus()
    }
}

