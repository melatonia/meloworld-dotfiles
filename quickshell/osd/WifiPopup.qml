import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking
import "../theme"

PanelWindow {
    id: root
    implicitWidth: 260
    implicitHeight: 600
    color: "transparent"

    property color borderColor: Networking.wifiEnabled ? PanelColors.network : PanelColors.border
    property bool clipContent: true
    property int padding: 12
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
    margins.top: 6
    margins.bottom: 0
    margins.left: xPos

    visible: animState !== "closed"

    // ── First WiFi device from Networking ─────────────────────────────────
    readonly property var wifiDevice: {
        for (let i = 0; i < Networking.devices.values.length; i++) {
            const d = Networking.devices.values[i]
            if (d.type === DeviceType.Wifi) return d
        }
        return null
    }

    // ── Currently connected network ───────────────────────────────────────
    readonly property var activeNetwork: {
        if (!wifiDevice) return null
        for (let i = 0; i < wifiDevice.networks.values.length; i++) {
            if (wifiDevice.networks.values[i].connected) return wifiDevice.networks.values[i]
        }
        return null
    }

    property string viewState: "list"
    property var targetNetwork: null
    property string passwordText: ""
    property string connectError: ""
    readonly property int maxListHeight: 5 * 34 + 4 * 4

    Connections {
        target: SessionState
        function onWifiPopupVisibleChanged() {
            if (SessionState.wifiPopupVisible) {
                viewState = "list"
                passwordText = ""
                connectError = ""
                root.animState = "open"
                if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
            } else {
                root.animState = "closing"
            }
        }
    }

    // Listen for wrong password / failed connection on the target network
    Connections {
        target: root.targetNetwork
        enabled: root.targetNetwork !== null
        function onConnectionFailed(reason) {
            root.connectError = (reason === ConnectionFailReason.NoSecrets)
                ? "Wrong password" : "Connection failed"
        }
    }

    function signalIcon(sig) {
        if (sig >= 80) return "󰤨"
        else if (sig >= 60) return "󰤥"
        else if (sig >= 40) return "󰤢"
        else if (sig >= 20) return "󰤟"
        else return "󰤯"
    }

    function isSecured(network) {
        return network.security !== WifiSecurityType.None
    }

    function handleNetworkClick(network) {
        if (network.known || !isSecured(network)) {
            network.connect()
        } else {
            targetNetwork = network
            passwordText = ""
            connectError = ""
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

        HoverHandler { id: hover }

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
                color: {
                    let base = Networking.wifiEnabled ? PanelColors.network : PanelColors.rowBackground
                    return toggleMouse.containsMouse ? Qt.lighter(base, 1.15) : base
                }
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text {
                        text: Networking.wifiEnabled ? "󰤨" : "󰤭"
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: Networking.wifiEnabled ? PanelColors.pillForeground : PanelColors.textMain
                    }
                    Text {
                        text: Networking.wifiEnabled ? "WiFi On" : "WiFi Off"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: Networking.wifiEnabled ? PanelColors.pillForeground : PanelColors.textMain
                    }
                }
                MouseArea {
                    id: toggleMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            // 2. Active Connection
            Rectangle {
                visible: Networking.wifiEnabled && root.activeNetwork !== null
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: PanelColors.network
                Row {
                    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Text {
                        text: root.activeNetwork ? root.signalIcon(root.activeNetwork.signalStrength * 100) : ""
                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                    }
                    Text {
                        text: root.activeNetwork ? root.activeNetwork.name : ""
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                        elide: Text.ElideRight
                        width: parent.width - 23 - 8 - activeSigText.width - 8
                    }
                    Text {
                        id: activeSigText
                        text: root.activeNetwork ? Math.round(root.activeNetwork.signalStrength * 100) + "%" : ""
                        font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                        color: PanelColors.pillForeground
                    }
                }
            }

            Rectangle {
                visible: Networking.wifiEnabled
                width: parent.width; height: visible ? 2 : 0
                color: PanelColors.rowBackground
            }

            // 3. Known Networks
            Repeater {
                model: root.wifiDevice ? root.wifiDevice.networks : null
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.known && !modelData.connected
                    width: parent.width; height: visible ? 34 : 0; radius: 6
                    color: knownMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: PanelColors.network
                    }
                    Row {
                        anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Text {
                            text: root.signalIcon(modelData.signalStrength * 100)
                            font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textMain
                        }
                        Text {
                            text: modelData.name
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
                        id: knownMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: root.handleNetworkClick(modelData)
                    }
                }
            }

            Rectangle {
                visible: Networking.wifiEnabled && root.wifiDevice !== null &&
                         root.wifiDevice.networks.values.some(function(n){ return n.known && !n.connected })
                width: parent.width; height: visible ? 2 : 0
                color: PanelColors.rowBackground
            }

            // 4. Scan Button
            Rectangle {
                visible: Networking.wifiEnabled
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: {
                    let base = (root.wifiDevice && root.wifiDevice.scannerEnabled) ? PanelColors.networkScanning : PanelColors.rowBackground
                    return scanMouse.containsMouse ? Qt.lighter(base, 1.15) : base
                }
                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    visible: !(root.wifiDevice && root.wifiDevice.scannerEnabled)
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
                        color: (root.wifiDevice && root.wifiDevice.scannerEnabled) ? PanelColors.pillForeground : PanelColors.textMain
                        SequentialAnimation on opacity {
                            running: root.wifiDevice && root.wifiDevice.scannerEnabled
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        text: (root.wifiDevice && root.wifiDevice.scannerEnabled) ? "Scanning..." : "Scan"
                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                        color: (root.wifiDevice && root.wifiDevice.scannerEnabled) ? PanelColors.pillForeground : PanelColors.textMain
                    }
                }
                MouseArea {
                    id: scanMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: { if (root.wifiDevice) root.wifiDevice.scannerEnabled = true }
                }
            }

            // 5. Connecting State
            Rectangle {
                visible: root.activeNetwork !== null && root.activeNetwork.stateChanging
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
                            running: root.activeNetwork !== null && root.activeNetwork.stateChanging
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
                visible: Networking.wifiEnabled
                width: parent.width; height: visible ? 34 : 0; radius: 6
                color: nmtuiMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                Behavior on color { ColorAnimation { duration: 150 } }
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
                    id: nmtuiMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        Quickshell.execDetached(["ghostty", "--title=nmtui", "-e", "nmtui"])
                        SessionState.wifiPopupVisible = false
                    }
                }
            }

            // 7. Other Networks
            Item {
                visible: Networking.wifiEnabled && root.wifiDevice !== null &&
                         root.wifiDevice.networks.values.some(function(n){ return !n.known })
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
                            model: root.wifiDevice ? root.wifiDevice.networks : null
                            delegate: Rectangle {
                                required property var modelData
                                visible: !modelData.known
                                width: otherNetCol.width; height: visible ? 34 : 0; radius: 6
                                color: otherMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    width: 3; height: parent.height - 10; radius: 2
                                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                    color: PanelColors.textDim
                                }
                                Row {
                                    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 8
                                    Text {
                                        text: root.signalIcon(modelData.signalStrength * 100)
                                        font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textMain
                                    }
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textMain
                                        elide: Text.ElideRight
                                        width: parent.width - 23 - 8 - lockIcon.width - 8
                                    }
                                    Text {
                                        id: lockIcon
                                        text: root.isSecured(modelData) ? "󰌾" : ""
                                        font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                        color: PanelColors.textDim
                                    }
                                }
                                MouseArea {
                                    id: otherMouse
                                    anchors.fill: parent; hoverEnabled: true
                                    onClicked: root.handleNetworkClick(modelData)
                                }
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
                        Text { text: "󰁞"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
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
                        Text { text: "󰁆"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: PanelColors.textDim }
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
                color: backMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.15) : PanelColors.rowBackground
                Behavior on color { ColorAnimation { duration: 150 } }

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
                    id: backMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: root.viewState = "list"
                }
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
                        text: root.targetNetwork ? root.targetNetwork.name : ""
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
                border.color: root.connectError !== "" ? PanelColors.error : (pwInput.activeFocus ? PanelColors.network : "transparent")
                border.width: pwInput.activeFocus || root.connectError !== "" ? 1 : 0
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
                            root.connectError = ""
                        }
                        onAccepted: {
                            if (root.passwordText.length > 0 && root.targetNetwork) {
                                root.targetNetwork.connectWithPsk(root.passwordText)
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
                visible: root.connectError !== ""
                width: parent.width; height: visible ? 26 : 0; radius: 6
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: root.connectError
                    font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.error
                }
            }

            // Connect Button
            Rectangle {
                width: parent.width; height: 34; radius: 6
                color: {
                    let base = root.passwordText.length > 0 ? PanelColors.network : PanelColors.rowBackground
                    return connectMouse.containsMouse && root.passwordText.length > 0 ? Qt.lighter(base, 1.15) : base
                }
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰤨"; font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"; color: root.passwordText.length > 0 ? PanelColors.pillForeground : PanelColors.textDim }
                    Text { text: "Connect"; font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: root.passwordText.length > 0 ? PanelColors.pillForeground : PanelColors.textDim }
                }
                MouseArea {
                    id: connectMouse
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (root.passwordText.length > 0 && root.targetNetwork) {
                            root.targetNetwork.connectWithPsk(root.passwordText)
                            root.viewState = "list"
                        }
                    }
                }
            }
        }
    }
}
}
