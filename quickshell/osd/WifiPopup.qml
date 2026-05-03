import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    implicitWidth: 260
    implicitHeight: 600
    color: "transparent"

    property color borderColor: NetworkState.wifiEnabled ? PanelColors.network : PanelColors.border
    property bool clipContent: true
    property int padding: 10
    property int contentHeight: Math.min(contentCol.implicitHeight, 480)
    property string animState: "closed"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayershell.Overlay

    property var screenObj: null
    screen: screenObj

    property int xPos: 0
    property var anchorWindow: null

    anchors.top: anchorWindow && anchorWindow.anchors.top ? true : false
    anchors.bottom: anchorWindow && anchorWindow.anchors.bottom ? true : false
    anchors.left: true
    
    // The usable area automatically accounts for the bar's exclusive zone.
    // Margin 0 makes it perfectly flush with the bar.
    margins.top: 0
    margins.bottom: 0
    margins.left: xPos

    visible: animState !== "closed"

    // ── UI State ─────────────────────────────────────
    property string viewState: "list"
    property string targetSSID: ""
    property string targetSecurity: ""
    property string passwordText: ""
    readonly property int maxListHeight: 5 * 34 + 4 * 4

    Connections {
        target: SessionState
        function onWifiPopupVisibleChanged() {
            if (SessionState.wifiPopupVisible) {
                viewState = "list"
                passwordText = ""
                root.animState = "open"
                NetworkState.rescan()
            } else {
                root.animState = "closing"
            }
        }
    }

    function signalIcon(sig) {
        if (sig >= 80) return "󰤨"
        else if (sig >= 60) return "󰤥"
        else if (sig >= 40) return "󰤢"
        else if (sig >= 20) return "󰤟"
        else return "󰤯"
    }

    function isSecured(sec) {
        return sec !== "" && sec !== "--"
    }

    function handleNetworkClick(ssid, security, known) {
        if (known || !isSecured(security)) {
            NetworkState.connect(ssid)
        } else {
            targetSSID = ssid
            targetSecurity = security
            passwordText = ""
            viewState = "password"
        }
    }

    Rectangle {
        id: innerRect
        width:  parent.width
        height: root.contentHeight + (root.padding * 2)
        radius: 10
        color:  PanelColors.popupBackground
        border.color: root.borderColor
        border.width: 2
        clip:   root.clipContent

        Behavior on height {
            SmoothedAnimation { velocity: 800; easing.type: Easing.OutExpo }
        }

        y:       0
        opacity: 1.0

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: innerRect; y: 0; opacity: 1.0 }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: innerRect; y: -20; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                SequentialAnimation {
                    PropertyAction  { target: innerRect; property: "y";       value: -20  }
                    PropertyAction  { target: innerRect; property: "opacity"; value: 0.0  }
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y";       to: 0;   duration: 250; easing.type: Easing.OutExpo  }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: innerRect; property: "y";       to: -20; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { target: innerRect; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

    Column {
        id: contentCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.padding
        }
        spacing: 4

        // ── List View ─────────────────────────────────
        Column {
            id: listView
            width: parent.width
            spacing: 4
            visible: root.viewState === "list"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // 1. WiFi Toggle
            Rectangle {
                width: parent.width; height: 34; radius: 6
                color: NetworkState.wifiEnabled ? PanelColors.network : PanelColors.rowBackground
                Rectangle {
                    visible: !NetworkState.wifiEnabled
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: PanelColors.network
                }
                Row {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text {
                        text: NetworkState.wifiEnabled ? "󰤨" : "󰤭"
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: NetworkState.wifiEnabled ? PanelColors.pillForeground : PanelColors.textMain
                    }
                    Text {
                        text: NetworkState.wifiEnabled ? "WiFi On" : "WiFi Off"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: NetworkState.wifiEnabled ? PanelColors.pillForeground : PanelColors.textMain
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: NetworkState.toggleWifi()
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // 2. Active Connection
            Rectangle {
                visible: NetworkState.wifiEnabled && NetworkState.activeSSID !== ""
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: PanelColors.network
                Row {
                    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text {
                        text: root.signalIcon(NetworkState.activeSignal)
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                    }
                    Text {
                        text: NetworkState.activeSSID
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                        elide: Text.ElideRight
                        width: parent.width - 23 - 8 - activeSigText.width - 8
                    }
                    Text {
                        id: activeSigText
                        text: NetworkState.activeSignal + "%"
                        font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                    }
                }
            }

            Rectangle {
                visible: NetworkState.wifiEnabled
                width: parent.width; height: visible ? 1 : 0
                color: PanelColors.rowBackground
            }

            // 3. Known Networks
            Repeater {
                model: NetworkState.networks
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.known && modelData.ssid !== NetworkState.activeSSID
                    width: parent.width; height: visible ? 34 : 0; radius: 6
                    color: PanelColors.rowBackground
                    Rectangle {
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: PanelColors.network
                    }
                    Row {
                        anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Text {
                            text: root.signalIcon(modelData.signal)
                            font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textMain
                        }
                        Text {
                            text: modelData.ssid
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textMain
                            elide: Text.ElideRight
                            width: parent.width - 23 - 8 - knownKeyIcon.width - 8
                        }
                        Text {
                            id: knownKeyIcon
                            text: "󰌆"
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.network
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                        onClicked: root.handleNetworkClick(modelData.ssid, modelData.security, true)
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            Rectangle {
                visible: NetworkState.wifiEnabled && NetworkState.networks.some(function(n){ return n.known && n.ssid !== NetworkState.activeSSID })
                width: parent.width; height: visible ? 1 : 0
                color: PanelColors.rowBackground
            }

            // 4. Scan Button
            Rectangle {
                visible: NetworkState.wifiEnabled
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: NetworkState.isScanning ? PanelColors.networkScanning : PanelColors.rowBackground
                Rectangle {
                    visible: !NetworkState.isScanning
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: PanelColors.networkScanning
                }
                Row {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text {
                        text: "󰑐"
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: NetworkState.isScanning ? PanelColors.pillForeground : PanelColors.textMain
                        SequentialAnimation on opacity {
                            running: NetworkState.isScanning
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        text: NetworkState.isScanning ? "Scanning..." : "Scan"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: NetworkState.isScanning ? PanelColors.pillForeground : PanelColors.textMain
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: NetworkState.rescan()
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // 5. Connecting State
            Rectangle {
                visible: NetworkState.connecting
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: PanelColors.rowBackground
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰤨"
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.network
                        SequentialAnimation on opacity {
                            running: NetworkState.connecting
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        text: "Connecting..."
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textMain
                    }
                }
            }

            // 6. nmtui
            Rectangle {
                visible: NetworkState.wifiEnabled
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: PanelColors.rowBackground
                Rectangle {
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: PanelColors.textDim
                }
                Row {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text {
                        text: "󰈀"
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textDim
                    }
                    Text {
                        text: "Open nmtui..."
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textDim
                    }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        Quickshell.execDetached(["ghostty", "--title=nmtui", "-e", "nmtui"])
                        SessionState.wifiPopupVisible = false
                    }
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // 7. Other Networks
            Item {
                visible: NetworkState.wifiEnabled && NetworkState.networks.some(function(n){ return !n.known })
                width: parent.width
                height: visible ? root.maxListHeight : 0

                Flickable {
                    id: netFlick
                    anchors.fill: parent
                    contentHeight: otherNetCol.implicitHeight
                    clip: true
                    interactive: contentHeight > height

                    Column {
                        id: otherNetCol
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: NetworkState.networks
                            delegate: Rectangle {
                                required property var modelData
                                visible: !modelData.known
                                width: otherNetCol.width; height: visible ? 34 : 0; radius: 6
                                color: PanelColors.rowBackground
                                Rectangle {
                                    width: 3; height: parent.height - 10; radius: 2
                                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                    color: PanelColors.textDim
                                }
                                Row {
                                    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 8
                                    Text {
                                        text: root.signalIcon(modelData.signal)
                                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textMain
                                    }
                                    Text {
                                        text: modelData.ssid
                                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textMain
                                        elide: Text.ElideRight
                                        width: parent.width - 23 - 8 - lockIcon.width - 8
                                    }
                                    Text {
                                        id: lockIcon
                                        text: root.isSecured(modelData.security) ? "󰌾" : ""
                                        font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textDim
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    onEntered: parent.opacity = 0.8
                                    onExited: parent.opacity = 1.0
                                    onClicked: root.handleNetworkClick(modelData.ssid, modelData.security, false)
                                }
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                    }
                }

                // Scroll up hint
                Rectangle {
                    visible: !netFlick.atYBeginning
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 22; radius: 6
                    color: PanelColors.rowBackground
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: ""; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
                        Text { text: "scroll up"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
                    }
                }

                // Scroll down hint
                Rectangle {
                    visible: !netFlick.atYEnd
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 22; radius: 6
                    color: PanelColors.rowBackground
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: ""; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
                        Text { text: "scroll for more"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
                    }
                }
            }
        }

        // ── Password View ─────────────────────────────
        Column {
            id: passwordView
            width: parent.width
            spacing: 4
            visible: root.viewState === "password"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            onVisibleChanged: {
                if (visible) pwInput.forceActiveFocus()
            }

            // Back
            Rectangle {
                width: parent.width; height: 34; radius: 6
                color: PanelColors.rowBackground
                Rectangle {
                    width: 3; height: parent.height - 10; radius: 2
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    color: PanelColors.textDim
                }
                Row {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text { text: "󰁍"; font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain }
                    Text { text: "Back"; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textMain }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: root.viewState = "list"
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // Target SSID
            Rectangle {
                width: parent.width; height: 34; radius: 6
                color: PanelColors.network
                Row {
                    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text { text: "󰤨"; font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.pillForeground }
                    Text {
                        text: root.targetSSID
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                        elide: Text.ElideRight
                        width: parent.width - 31
                    }
                }
            }

            // Password Input
            Rectangle {
                width: parent.width; height: 34; radius: 6
                color: pwInput.activeFocus ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                border.color: NetworkState.connectError !== "" ? PanelColors.error : (pwInput.activeFocus ? PanelColors.network : "transparent")
                border.width: pwInput.activeFocus || NetworkState.connectError !== "" ? 1 : 0
                Row {
                    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text { text: "󰌾"; font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
                    TextInput {
                        id: pwInput
                        width: parent.width - 23 - 8 - toggleVis.width - 8
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textMain
                        selectionColor: PanelColors.network
                        selectedTextColor: PanelColors.pillForeground
                        echoMode: showPw.checked ? TextInput.Normal : TextInput.Password
                        clip: true
                        text: root.passwordText
                        onTextChanged: {
                            root.passwordText = text
                            NetworkState.connectError = ""
                        }
                        onAccepted: {
                            if (root.passwordText.length > 0) {
                                NetworkState.connect(root.targetSSID, root.passwordText)
                                root.viewState = "list"
                            }
                        }
                    }
                    Text {
                        id: toggleVis
                        text: showPw.checked ? "󰈈" : "󰈉"
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.textDim
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showPw.checked = !showPw.checked
                        }
                    }
                }
                MouseArea { anchors.fill: parent; z: -1; onClicked: pwInput.forceActiveFocus() }
                Text {
                    visible: pwInput.text === "" && !pwInput.activeFocus
                    anchors { left: parent.left; leftMargin: 37; verticalCenter: parent.verticalCenter }
                    text: "Password"
                    font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                }
            }

            Item { id: showPw; property bool checked: false; visible: false }

            // Error
            Rectangle {
                visible: NetworkState.connectError !== ""
                width: parent.width; height: visible ? 26 : 0; radius: 6
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: NetworkState.connectError
                    font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.error
                }
            }

            // Connect Button
            Rectangle {
                width: parent.width; height: 34; radius: 6
                color: root.passwordText.length > 0 ? PanelColors.network : PanelColors.rowBackground
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰤨"; font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"; color: root.passwordText.length > 0 ? PanelColors.pillForeground : PanelColors.textDim }
                    Text { text: "Connect"; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: root.passwordText.length > 0 ? PanelColors.pillForeground : PanelColors.textDim }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: if (root.passwordText.length > 0) parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        if (root.passwordText.length > 0) {
                            NetworkState.connect(root.targetSSID, root.passwordText)
                            root.viewState = "list"
                        }
                    }
                }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }
}
}
