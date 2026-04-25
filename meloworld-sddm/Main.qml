import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import SddmComponents

Item {
    id: root
    width: Screen.width
    height: Screen.height

    // ── Design System (Sync with Rofi + Quickshell) ───────────
    readonly property color clrBg:       "#212121"
    readonly property color clrBgAlt:    "#2d2d2d"
    readonly property color clrFg:       "#ffffffdd"
    readonly property color clrFgDim:    "#616161"
    readonly property color clrAccent:   "#80cbc4"
    readonly property color clrBorder:   "#424242"
    readonly property color clrUrgent:   "#ef9a9a"
    readonly property color clrReboot:   "#ffcc80"
    readonly property color clrSession:  "#a5d6a7"
    readonly property color clrClock:    "#ffffffdd"
    readonly property color clrPillFg:   "#212121"

    readonly property string fontMain: "JetBrainsMono Nerd Font"
    readonly property int radiusLarge: 12
    readonly property int radiusMed:   8
    readonly property int radiusSmall: 5

    property int    selectedIndex: 0
    property int    sessionIndex:  0
    property string sessionLabel:  "session"

    // ── Components ────────────────────────────────────────────

    // Exact replica of quickshell/bar/widgets/Pill.qml
    component PillButton: Rectangle {
        id: pill
        property string label:     ""
        property color  pillColor: root.clrAccent
        signal clicked()

        implicitHeight: 28
        implicitWidth:  pillText.implicitWidth + 16 // 8px each side
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
            font.family: root.fontMain
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

    // Exact replica of quickshell/bar/Bar.qml containers
    component BarContainer: Rectangle {
        id: container
        property alias spacing: innerRow.spacing
        default property alias children: innerRow.children

        height: 40
        radius: 8
        color: root.clrBg
        width: innerRow.implicitWidth + 12 // 6px each side

        Row {
            id: innerRow
            anchors.centerIn: parent
            spacing: 6 // Matches LeftBar.qml spacing
        }
    }

    // ── Background ────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: config.background || "assets/wallpaper.jpeg"
        fillMode: Image.PreserveAspectCrop

        // Dark overlay
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

        PillButton {
            pillColor: root.clrClock
            label: "  " + Qt.formatDateTime(new Date(), "HH:mm")

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: parent.label = "  " + Qt.formatDateTime(new Date(), "HH:mm")
            }
        }
    }

    // ── Center Login Card ─────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 320
        height: cardLayout.implicitHeight + 20 // 10px each side (matching Rofi window padding)
        radius: root.radiusLarge
        color: root.clrBg
        border.width: 3
        border.color: root.clrBorder

        ColumnLayout {
            id: cardLayout
            anchors {
                fill: parent
                margins: 10 // Matches Rofi window padding: 10px
            }
            spacing: 8 // Matches Rofi mainbox spacing: 8px

            // User Selection
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 // Closer spacing for user elements

                Repeater {
                    model: userModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36 // Matches Rofi element height approx (8+13+8+2)
                        radius: root.radiusMed
                        color: index === root.selectedIndex
                            ? root.clrAccent
                            : (userMa.containsMouse ? root.clrBorder : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12  // Matches Rofi element padding: 8px 12px
                            anchors.rightMargin: 12
                            spacing: 12 // Matches Rofi element spacing: 12px

                            Text {
                                text: ""
                                font.family: root.fontMain
                                font.pixelSize: 14
                                color: index === root.selectedIndex ? root.clrPillFg : root.clrFg
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.name || model.realName || "user"
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

            // Password Field
            Rectangle {
                Layout.fillWidth: true
                height: 40 // Matches Rofi inputbar height (approx)
                radius: root.radiusMed
                color: root.clrBgAlt
                border.width: 2
                border.color: passwordField.activeFocus ? root.clrAccent : "transparent"

                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: passwordField
                    anchors {
                        fill: parent
                        leftMargin: 12 // Matches Rofi inputbar padding: 10px 12px
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
                Layout.fillWidth: true
                Layout.preferredHeight: 36 // Matches user element height
                label: "Login"
                pillColor: root.clrAccent
                onClicked: loginAction()
            }
        }
    }

    // ── Bottom Left (Session) ─────────────────────────────────
    BarContainer {
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 12
        }

        PillButton {
            id: sessionPill
            label: "⊹ " + root.sessionLabel
            pillColor: root.clrSession
            onClicked: {
                root.sessionIndex = (root.sessionIndex + 1) % Math.max(sessionModel.count, 1)
                updateSession()
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

        PillButton {
            label: " Reboot"
            pillColor: root.clrReboot
            onClicked: sddm.reboot()
        }

        PillButton {
            label: "⏻ Shutdown"
            pillColor: root.clrUrgent
            onClicked: sddm.powerOff()
        }
    }

    // ── Logic ─────────────────────────────────────────────────
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
