import QtQuick
import QtQuick.Controls
import SddmComponents

Item {
    id: root
    width: Screen.width
    height: Screen.height

    // ── exact values from PanelColors + Colors ────────────────
    readonly property color clrBarBg:    "#212121"   // grey900
    readonly property color clrPillFg:   "#212121"   // grey900 — text ON pills
    readonly property color clrClock:    "#ffffffdd" // white   — clock pill bg
    readonly property color clrAccent:   "#80cbc4"   // teal200
    readonly property color clrShutdown: "#ef9a9a"   // red200
    readonly property color clrReboot:   "#ffcc80"   // orange200
    readonly property color clrSession:  "#a5d6a7"   // green200
    readonly property color clrFg:       "#ffffffdd"
    readonly property color clrFgDim:    "#616161"   // grey700
    readonly property color clrSurface:  "#2d2d2d"
    readonly property color clrSelected: "#424242"

    property int    selectedIndex: 0
    property int    sessionIndex:  0
    property string sessionLabel:  "session"

    // ── pill — exact replica of Pill.qml ─────────────────────
    // height: 28, radius: 5, font: 16px bold JetBrainsMono
    // width: label.implicitWidth + 16
    // color: pillColor, hover: Qt.lighter(1.15), scale: 1.03
    // text color: pillForeground = #212121
    component PillButton: Rectangle {
        id: pill
        property string label:     ""
        property color  pillColor: root.clrAccent
        signal clicked()

        implicitHeight: 28
        implicitWidth:  pillText.implicitWidth + 16
        radius: 5
        color: ma.containsMouse ? Qt.lighter(pillColor, 1.15) : pillColor
        scale: ma.containsMouse ? 1.03 : 1.0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            font.pixelSize: 16
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: root.clrPillFg
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    // ── bar container — exact replica of Bar.qml containers ──
    // height: 40 (= 55 - 15), radius: 8, color: #212121
    // width: content.implicitWidth + 12
    // content anchors.centerIn: parent
    component BarContainer: Rectangle {
        id: container
        property alias content: innerRow
        default property alias children: innerRow.children

        height: 40
        radius: 8
        color: root.clrBarBg
        width: innerRow.implicitWidth + 12

        Row {
            id: innerRow
            anchors.centerIn: parent
            spacing: 4
        }
    }

    // ── wallpaper ─────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: "assets/wallpaper.jpeg"
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.15
    }

    // ── clock — top center, exactly like CenterBar ────────────
    BarContainer {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 8
        }

        PillButton {
            pillColor: root.clrClock
            label: " " + Qt.formatDateTime(new Date(), "HH:mm")

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: parent.label =
                    " " + Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
    }

    // ── center card ───────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 280
        height: cardColumn.implicitHeight + 48
        radius: 8
        color: root.clrBarBg

        Column {
            id: cardColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 24
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 4

            // ── user list ─────────────────────────────────────
            Repeater {
                model: userModel

                delegate: Rectangle {
                    width: cardColumn.width
                    height: 36
                    radius: 5
                    color: index === root.selectedIndex
                        ? root.clrAccent
                        : (userMa.containsMouse ? root.clrSelected : root.clrSurface)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: model.name || model.realName || "user"
                        font.pixelSize: 13
                        font.bold: index === root.selectedIndex
                        font.family: "JetBrainsMono Nerd Font"
                        color: index === root.selectedIndex
                            ? root.clrPillFg
                            : root.clrFg
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

            Item { width: 1; height: 4 }

            // ── password field ────────────────────────────────
            Rectangle {
                width: parent.width
                height: 36
                radius: 5
                color: root.clrSurface
                border.color: passwordField.activeFocus
                    ? root.clrAccent : "transparent"
                border.width: 1

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
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    color: root.clrFg
                    selectionColor: root.clrAccent
                    clip: true
                    onAccepted: loginAction()
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    text: "password"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    color: root.clrFgDim
                    visible: passwordField.text.length === 0
                        && !passwordField.activeFocus
                }
            }

            // ── error ─────────────────────────────────────────
            Text {
                id: errorText
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: ""
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                color: root.clrShutdown
                wrapMode: Text.WordWrap
                visible: text.length > 0
            }

            Item { width: 1; height: 4 }

            // ── login — full width teal pill ──────────────────
            PillButton {
                label: "  login"
                pillColor: root.clrAccent
                width: parent.width
                implicitHeight: 36
                onClicked: loginAction()
            }
        }
    }

    // ── session — bottom left, bar container ──────────────────
    BarContainer {
        anchors {
            bottom: parent.bottom
            left: parent.left
            bottomMargin: 8
            leftMargin: 8
        }

        PillButton {
            id: sessionPill
            label: "⊹  " + root.sessionLabel
            pillColor: root.clrSession
            onClicked: {
                root.sessionIndex = (root.sessionIndex + 1) % Math.max(sessionModel.count, 1)
                updateSession()
            }
        }
    }

    // ── power — bottom right, bar container ───────────────────
    BarContainer {
        anchors {
            bottom: parent.bottom
            right: parent.right
            bottomMargin: 8
            rightMargin: 8
        }

        PillButton {
            label: " Reboot"
            pillColor: root.clrReboot
            onClicked: sddm.reboot()
        }

        PillButton {
            label: "⏻ Shutdown"
            pillColor: root.clrShutdown
            onClicked: sddm.powerOff()
        }
    }

    // ── logic ─────────────────────────────────────────────────
    function updateSession() {
        if (sessionModel && sessionModel.count > 0) {
            var name = sessionModel.data(
                sessionModel.index(root.sessionIndex, 0),
                Qt.DisplayRole
            )
            root.sessionLabel = name || "session"
        }
    }

    function loginAction() {
        errorText.text = ""
        var username = userModel.data(
            userModel.index(root.selectedIndex, 0),
            Qt.UserRole + 1
        ) || userModel.data(
            userModel.index(root.selectedIndex, 0),
            Qt.DisplayRole
        )
        sddm.login(username, passwordField.text, root.sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "incorrect password"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        updateSession()
        passwordField.forceActiveFocus()
    }
}
