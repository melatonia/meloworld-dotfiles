import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    anchors.fill: parent
    color: root.clrBg
    visible: true
    opacity: 1

    // ── Design System ──────────────────────────────────────────
    property color clrBg:      (typeof config !== 'undefined' && config.background_color) ? config.background_color : "#212121"
    property color clrBgAlt:   "#2d2d2d"
    property color clrFg:      "#ffffffdd"
    property color clrFgDim:   "#616161"
    property color clrAccent:  (typeof config !== 'undefined' && config.accent_color)     ? config.accent_color     : "#80cbc4"
    property color clrBorder:  "#424242"
    property color clrUrgent:  (typeof config !== 'undefined' && config.urgent_color)     ? config.urgent_color     : "#ef9a9a"
    property color clrReboot:  "#ffcc80"
    property color clrSession: "#a5d6a7"

    property string fontMain:  (typeof config !== 'undefined' && config.font) ? config.font : "JetBrainsMono Nerd Font"
    property int radiusLarge:  12
    property int radiusMed:    8

    // ── State ──────────────────────────────────────────────────
    property int    selectedIndex:   (typeof userModel !== 'undefined' && userModel) ? Math.max(0, userModel.lastIndex) : 0
    property int    sessionIndex:    (typeof sessionModel !== 'undefined' && sessionModel) ? Math.max(0, sessionModel.lastIndex) : 0
    property string sessionLabel:    "session"
    property string currentUsername: (typeof sddm !== 'undefined') ? sddm.lastUser : ""  // FIX: store username directly

    onSelectedIndexChanged: updateSessionLabel()

    // ── Background ────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: (typeof config !== 'undefined' && config.background) ? config.background : "assets/wallpaper.jpeg"
        fillMode: Image.PreserveAspectCrop

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.2
        }
    }

    // ── Top Bar (Clock) ───────────────────────────────────────
    BarContainer {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        bgColor: root.clrBgAlt
        visible: typeof primaryScreen !== 'undefined' ? primaryScreen : true

        PillButton {
            id: topClock
            pillColor: root.clrFg
            textColor: root.clrBg
            fontMain: root.fontMain
            label: " " + timeLabel
            activeFocusOnTab: false

            property string timeLabel: Qt.formatDateTime(new Date(), "HH:mm")

            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: topClock.timeLabel = Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
    }

    // ── Auth Card ─────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 360
        height: cardLayout.implicitHeight + 48
        radius: root.radiusLarge
        color: root.clrBg
        border.width: 4
        border.color: passwordField.activeFocus && !shakeAnim.running ? root.clrAccent : root.clrBorder

        Behavior on border.color { ColorAnimation { duration: 150 } }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 0; to: 10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10; to: -10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: -10; to: 10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; from: 10; to: 0; duration: 50; easing.type: Easing.OutQuad }
        }

        ColumnLayout {
            id: cardLayout
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 12

            // ── User List ──────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    id: userRepeater
                    model: (typeof userModel !== 'undefined') ? userModel : null

                    delegate: Rectangle {
                        id: userDelegate
                        readonly property bool isActive: index === root.selectedIndex
                        Layout.fillWidth: true
                        height: 38
                        radius: root.radiusMed
                        color: isActive ? root.clrBorder : (userMa.containsMouse || userDelegate.activeFocus ? root.clrBgAlt : "transparent")
                        antialiasing: true
                        scale: (userMa.containsMouse || userDelegate.activeFocus) ? 1.03 : 1.0
                        transformOrigin: Item.Center
                        border.width: userDelegate.activeFocus ? 3 : 0
                        border.color: root.clrAccent
                        activeFocusOnTab: true

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.selectedIndex = index
                                root.currentUsername = model.name  // FIX: save username from delegate
                                passwordField.forceActiveFocus()
                                event.accepted = true
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 12
                            Text { text: ""; font.family: root.fontMain; font.pixelSize: 16; color: isActive ? root.clrAccent : root.clrFg }
                            Text {
                                Layout.fillWidth: true
                                text: model.name || model.realName || "user"
                                font.pixelSize: 14
                                font.bold: isActive
                                font.family: root.fontMain
                                color: isActive ? root.clrAccent : root.clrFg
                            }
                        }

                        MouseArea {
                            id: userMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: function(mouse) {
                                root.selectedIndex = index
                                root.currentUsername = model.name  // FIX: save username from delegate
                                passwordField.forceActiveFocus()
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                    }
                }
            }

            // ── Password Field ─────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: root.radiusMed
                color: root.clrBgAlt
                border.width: passwordField.activeFocus ? 3 : 0
                border.color: root.clrAccent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12
                    Text { text: ""; font.family: root.fontMain; font.pixelSize: 16; color: passwordField.activeFocus ? root.clrAccent : root.clrFgDim }
                    TextInput {
                        id: passwordField
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        font.pixelSize: 14
                        font.family: root.fontMain
                        color: root.clrFg
                        activeFocusOnTab: true
                        onAccepted: loginAction()

                        Text {
                            anchors.fill: parent
                            text: "Password..."
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            font.family: root.fontMain
                            color: root.clrFgDim
                            visible: passwordField.text.length === 0 && !passwordField.activeFocus
                        }
                    }
                }
            }

            // ── Login Button ───────────────────────────────────
            Rectangle {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: root.radiusMed
                activeFocusOnTab: true
                antialiasing: true
                color: (loginMa.containsMouse || loginButton.activeFocus) ? Qt.lighter(root.clrAccent, 1.15) : root.clrAccent
                scale: (loginMa.containsMouse || loginButton.activeFocus) ? 1.03 : 1.0
                border.width: loginButton.activeFocus ? 3 : 0
                border.color: Qt.lighter(root.clrAccent, 1.3)

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        loginAction()
                        event.accepted = true
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text { text: "󰍂"; font.family: root.fontMain; font.pixelSize: 16; color: root.clrBg }
                    Text { text: "Login"; font.family: root.fontMain; font.bold: true; font.pixelSize: 14; color: root.clrBg }
                }

                MouseArea {
                    id: loginMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: function(mouse) { loginAction() }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
            }
        }
    }

    // ── Bottom Bars ───────────────────────────────────────────
    BarContainer {
        id: bottomLeftBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 12
        bgColor: root.clrBgAlt

        PillButton {
            id: sessionPill
            label: " " + root.sessionLabel
            pillColor: root.clrSession
            textColor: root.clrBg
            fontMain: root.fontMain
            onClicked: sessionMenuContainer.toggle()
        }
    }

    BarContainer {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 6
        bgColor: root.clrBgAlt

        PillButton {
            id: rebootButton
            label: " Reboot"
            pillColor: root.clrReboot
            textColor: root.clrBg
            fontMain: root.fontMain
            onClicked: sddm.reboot()
        }

        PillButton {
            id: shutdownButton
            label: "⏻ Shutdown"
            pillColor: root.clrUrgent
            textColor: root.clrBg
            fontMain: root.fontMain
            onClicked: sddm.powerOff()
        }
    }

    // ── Session Flyout ────────────────────────────────────────
    Item {
        id: sessionMenuContainer
        width: 180
        height: sessionColumn.implicitHeight + 20
        anchors.bottom: bottomLeftBar.top
        anchors.left: bottomLeftBar.left
        anchors.bottomMargin: 10
        visible: animState !== "closed"
        enabled: animState !== "closed"
        property string animState: "closed"
        function open()   { animState = "open"    }
        function close()  { animState = "closing" }
        function toggle() { animState === "open" ? close() : open() }

        Rectangle {
            id: innerSessionRect
            anchors.fill: parent
            radius: root.radiusLarge
            color: root.clrBg
            border.color: root.clrSession
            border.width: 2
            clip: true

            states: [
                State { name: "open"; when: sessionMenuContainer.animState === "open"; PropertyChanges { target: innerSessionRect; y: 0; opacity: 1.0 } },
                State { name: "closing"; when: sessionMenuContainer.animState === "closing"; PropertyChanges { target: innerSessionRect; y: 20; opacity: 0.0 } }
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
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 4

                Repeater {
                    model: (typeof sessionModel !== 'undefined') ? sessionModel : null
                    delegate: Rectangle {
                        readonly property bool isActive: root.sessionIndex === index
                        width: sessionColumn.width
                        height: 34
                        radius: 6
                        color: isActive ? root.clrSession : root.clrBgAlt
                        Rectangle {
                            visible: !isActive
                            width: 3; height: parent.height - 12; radius: 2; color: root.clrSession
                            anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                            text: model.name || "Session"
                            color: isActive ? root.clrBg : root.clrFg
                            font.pixelSize: 13; font.bold: true; font.family: root.fontMain
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: function(mouse) {
                                root.sessionIndex = index
                                updateSessionLabel()
                                sessionMenuContainer.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Logic ─────────────────────────────────────────────────
    function sessionCount() { return (typeof sessionModel !== 'undefined' && sessionModel) ? sessionModel.count : 0 }

    // FIX: loginAction now uses currentUsername (set directly from model.name in delegates)
    // instead of the broken userModel.data(idx, Qt.UserRole) call which used the wrong role ID.
    function loginAction() {
        if (typeof sddm === 'undefined') return
        if (typeof userModel === 'undefined' || !userModel || userModel.count === 0) return
        var username = root.currentUsername || sddm.lastUser
        if (username) sddm.login(username, passwordField.text, root.sessionIndex)
    }

    function updateSessionLabel() {
        var count = sessionCount()
        if (count > 0 && root.sessionIndex < count) {
            var idx = sessionModel.index(root.sessionIndex, 0)
            root.sessionLabel = sessionModel.data(idx, Qt.UserRole) || "Session"
        }
    }

    NumberAnimation { id: fadeOutAnim; target: root; property: "opacity"; to: 0; duration: 400; running: false; easing.type: Easing.InCubic }

    Connections {
        target: sddm
        function onLoginFailed() {
            shakeAnim.start()
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            fadeOutAnim.start()
        }
    }

    // FIX: initialize currentUsername from userModel using the correct role (Qt.UserRole + 1)
    Component.onCompleted: {
        updateSessionLabel()
        if (typeof userModel !== 'undefined' && userModel && userModel.count > 0) {
            var idx = userModel.index(root.selectedIndex, 0)
            root.currentUsername = userModel.data(idx, Qt.UserRole + 1) || sddm.lastUser
        }
        passwordField.forceActiveFocus()
    }
}
