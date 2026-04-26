import QtQuick
import Quickshell
import "../theme"

PanelWindow {
    id: root
    visible: animState !== "closed"
    implicitWidth: 260
    implicitHeight: 500
    color: "transparent"
    
    focusable: true
    exclusiveZone: 0
    
    property int xPos: 0
    property int yPos: 0
    property var screenObj: null
    
    screen: screenObj
    anchors.top: true
    anchors.left: true
    
    margins.top: 0
    margins.left: xPos

    property string animState: "closed"

    // ── UI State ─────────────────────────────────────
    property string viewState: "list"
    property string targetSSID: ""
    property string targetSecurity: ""
    property string passwordText: ""
    readonly property int maxListHeight: 300

    Connections {
        target: SessionState
        function onWifiPopupVisibleChanged() {
            if (SessionState.wifiPopupVisible) {
                viewState = "list"
                passwordText = ""
                animState = "open"
                NetworkState.rescan()
            } else {
                animState = "closing"
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
        width: parent.width
        height: Math.min(contentCol.implicitHeight + 20, 500)
        radius: 10
        color: Colors.grey900
        border.color: NetworkState.wifiEnabled ? Colors.purple200 : Colors.grey700
        border.width: 2
        clip: true

        Behavior on height {
            SmoothedAnimation {
                velocity: 800
                easing.type: Easing.OutExpo
            }
        }
        
        y: 0
        opacity: 1.0

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges {
                    target: innerRect
                    y: 0
                    opacity: 1.0
                }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges {
                    target: innerRect
                    y: -20
                    opacity: 0.0
                }
            }
        ]

        transitions: [
            Transition {
                from: "*"
                to: "open"
                SequentialAnimation {
                    PropertyAction {
                        target: innerRect
                        property: "y"
                        value: -20
                    }
                    PropertyAction {
                        target: innerRect
                        property: "opacity"
                        value: 0.0
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: innerRect
                            property: "y"
                            to: 0
                            duration: 250
                            easing.type: Easing.OutExpo
                        }
                        NumberAnimation {
                            target: innerRect
                            property: "opacity"
                            to: 1.0
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            },
            Transition {
                from: "*"
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: innerRect
                            property: "y"
                            to: -20
                            duration: 180
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: innerRect
                            property: "opacity"
                            to: 0.0
                            duration: 150
                            easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction {
                        script: root.animState = "closed"
                    }
                }
            }
        ]

        Column {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 10
            spacing: 4

            Column {
                id: listView
                width: parent.width
                spacing: 4
                visible: root.viewState === "list"
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                // 1. WiFi Toggle
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    color: NetworkState.wifiEnabled ? Colors.purple200 : Colors.grey800
                    Rectangle {
                        visible: !NetworkState.wifiEnabled
                        width: 3
                        height: parent.height - 10
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.purple200
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: NetworkState.wifiEnabled ? "󰤨" : "󰤭"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: NetworkState.wifiEnabled ? Colors.grey900 : Colors.grey200
                        }
                        Text {
                            text: NetworkState.wifiEnabled ? "WiFi On" : "WiFi Off"
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: NetworkState.wifiEnabled ? Colors.grey900 : Colors.grey200
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            parent.opacity = 0.8
                        }
                        onExited: {
                            parent.opacity = 1.0
                        }
                        onClicked: {
                            NetworkState.toggleWifi()
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                // 2. Active Connection
                Rectangle {
                    visible: NetworkState.wifiEnabled && NetworkState.activeSSID !== ""
                    width: parent.width
                    height: visible ? 34 : 0
                    radius: 6
                    color: Colors.purple200
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: root.signalIcon(NetworkState.activeSignal)
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey900
                        }
                        Text {
                            text: NetworkState.activeSSID
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey900
                            elide: Text.ElideRight
                            width: parent.width - 23 - 8 - activeSigText.width - 8
                        }
                        Text {
                            id: activeSigText
                            text: NetworkState.activeSignal + "%"
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey900
                        }
                    }
                }

                Rectangle {
                    visible: NetworkState.wifiEnabled
                    width: parent.width
                    height: visible ? 1 : 0
                    color: Colors.grey800
                }

                // 3. Known Networks
                Repeater {
                    model: NetworkState.networks
                    delegate: Rectangle {
                        required property var modelData
                        visible: modelData.known && modelData.ssid !== NetworkState.activeSSID
                        width: parent.width
                        height: visible ? 34 : 0
                        radius: 6
                        color: Colors.grey800
                        Rectangle {
                            width: 3
                            height: parent.height - 10
                            radius: 2
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.purple200
                        }
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Text {
                                text: root.signalIcon(modelData.signal)
                                font.pixelSize: 15
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey200
                            }
                            Text {
                                text: modelData.ssid
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey200
                                elide: Text.ElideRight
                                width: parent.width - 23 - 8 - knownKeyIcon.width - 8
                            }
                            Text {
                                id: knownKeyIcon
                                text: "󰌆"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.purple200
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                parent.opacity = 0.8
                            }
                            onExited: {
                                parent.opacity = 1.0
                            }
                            onClicked: {
                                root.handleNetworkClick(modelData.ssid, modelData.security, true)
                            }
                        }
                    }
                }

                Rectangle {
                    visible: NetworkState.wifiEnabled && NetworkState.networks.some(function(n){ return n.known && n.ssid !== NetworkState.activeSSID })
                    width: parent.width
                    height: visible ? 1 : 0
                    color: Colors.grey800
                }
                
                // 4. Scan Button (DeepPurple200 Theme)
                Rectangle {
                    visible: NetworkState.wifiEnabled
                    width: parent.width
                    height: visible ? 34 : 0
                    radius: 6
                    color: NetworkState.isScanning ? Colors.deepPurple200 : Colors.grey800
                    Rectangle {
                        visible: !NetworkState.isScanning
                        width: 3; height: parent.height - 10; radius: 2
                        anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                        color: Colors.deepPurple200
                    }
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: "󰑐"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: NetworkState.isScanning ? Colors.grey900 : Colors.grey200
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
                            color: NetworkState.isScanning ? Colors.grey900 : Colors.grey200
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true
                        onEntered: { parent.opacity = 0.8 }
                        onExited: { parent.opacity = 1.0 }
                        onClicked: { NetworkState.rescan() }
                    }
                }

                // 5. Connecting State
                Rectangle {
                    visible: NetworkState.connecting
                    width: parent.width
                    height: visible ? 34 : 0
                    radius: 6
                    color: Colors.grey800
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰤨"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.purple200
                            SequentialAnimation on opacity {
                                running: NetworkState.connecting
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.3
                                    duration: 500
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 1.0
                                    duration: 500
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                        Text {
                            text: "Connecting..."
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey200
                        }
                    }
                }

                // 6. Action Buttons (nmtui)
                Rectangle {
                    visible: NetworkState.wifiEnabled
                    width: parent.width
                    height: visible ? 34 : 0
                    radius: 6
                    color: Colors.grey800
                    Rectangle {
                        width: 3
                        height: parent.height - 10
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.grey500
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: "󰈀"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey400
                        }
                        Text {
                            text: "Open nmtui..."
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey400
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            parent.opacity = 0.8
                        }
                        onExited: {
                            parent.opacity = 1.0
                        }
                        onClicked: {
                            Quickshell.execDetached(["ghostty", "--title=nmtui", "-e", "nmtui"])
                            SessionState.wifiPopupVisible = false
                        }
                    }
                }

                // 7. Other Networks
                Item {
                    visible: NetworkState.wifiEnabled && NetworkState.networks.some(function(n){ return !n.known })
                    width: parent.width
                    height: visible ? Math.min(otherNetCol.implicitHeight, root.maxListHeight) : 0
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
                                    width: otherNetCol.width
                                    height: visible ? 34 : 0
                                    radius: 6
                                    color: Colors.grey800
                                    Rectangle {
                                        width: 3
                                        height: parent.height - 10
                                        radius: 2
                                        anchors.left: parent.left
                                        anchors.leftMargin: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Colors.grey600
                                    }
                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8
                                        Text {
                                            text: root.signalIcon(modelData.signal)
                                            font.pixelSize: 15
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Colors.grey200
                                        }
                                        Text {
                                            text: modelData.ssid
                                            font.pixelSize: 13
                                            font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Colors.grey200
                                            elide: Text.ElideRight
                                            width: parent.width - 23 - 8 - lockIcon.width - 8
                                        }
                                        Text {
                                            id: lockIcon
                                            text: root.isSecured(modelData.security) ? "󰌾" : ""
                                            font.pixelSize: 12
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Colors.grey500
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: {
                                            parent.opacity = 0.8
                                        }
                                        onExited: {
                                            parent.opacity = 1.0
                                        }
                                        onClicked: {
                                            root.handleNetworkClick(modelData.ssid, modelData.security, false)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: !netFlick.atYBeginning
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 22
                        radius: 6
                        color: Colors.grey800
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰁄"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey500
                            }
                            Text {
                                text: "scroll up"
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey500
                            }
                        }
                    }

                    Rectangle {
                        visible: !netFlick.atYEnd
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 22
                        radius: 6
                        color: Colors.grey800
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰁆"
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey500
                            }
                            Text {
                                text: "scroll for more"
                                font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                color: Colors.grey500
                            }
                        }
                    }
                }
            }

            Column {
                id: passwordView
                width: parent.width
                spacing: 4
                visible: root.viewState === "password"
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    color: Colors.grey800
                    Rectangle {
                        width: 3
                        height: parent.height - 10
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.grey500
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: "󰁍"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey200
                        }
                        Text {
                            text: "Back"
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey200
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            parent.opacity = 0.8
                        }
                        onExited: {
                            parent.opacity = 1.0
                        }
                        onClicked: {
                            root.viewState = "list"
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    color: Colors.purple200
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: "󰤨"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey900
                        }
                        Text {
                            text: root.targetSSID
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey900
                            elide: Text.ElideRight
                            width: parent.width - 31
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    color: pwInput.activeFocus ? Qt.lighter(Colors.grey800, 1.15) : Colors.grey800
                    border.color: NetworkState.connectError !== "" ? Colors.red400 : (pwInput.activeFocus ? Colors.purple200 : "transparent")
                    border.width: pwInput.activeFocus || NetworkState.connectError !== "" ? 1 : 0
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Text {
                            text: "󰌾"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey400
                        }
                        TextInput {
                            id: pwInput
                            width: parent.width - 23 - 8 - toggleVis.width - 8
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey200
                            selectionColor: Colors.purple200
                            selectedTextColor: Colors.grey900
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
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: Colors.grey400
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    showPw.checked = !showPw.checked
                                }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            pwInput.forceActiveFocus()
                        }
                        z: -1
                    }
                    Text {
                        visible: pwInput.text === "" && !pwInput.activeFocus
                        anchors.left: parent.left
                        anchors.leftMargin: 37
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.grey600
                    }
                }
                Item {
                    id: showPw
                    property bool checked: false
                    visible: false
                }
                Rectangle {
                    visible: NetworkState.connectError !== ""
                    width: parent.width
                    height: visible ? 26 : 0
                    radius: 6
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: NetworkState.connectError
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.red400
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    color: root.passwordText.length > 0 ? Colors.purple200 : Colors.grey800
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰤨"
                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                            color: root.passwordText.length > 0 ? Colors.grey900 : Colors.grey500
                        }
                        Text {
                            text: "Connect"
                            font.pixelSize: 13
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: root.passwordText.length > 0 ? Colors.grey900 : Colors.grey500
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            if (root.passwordText.length > 0) {
                                parent.opacity = 0.8
                            }
                        }
                        onExited: {
                            parent.opacity = 1.0
                        }
                        onClicked: {
                            if (root.passwordText.length > 0) {
                                NetworkState.connect(root.targetSSID, root.passwordText)
                                root.viewState = "list"
                            }
                        }
                    }
                }
            }
        }
    }
    onViewStateChanged: {
        if (viewState === "password") {
            pwInput.forceActiveFocus()
        }
    }
}
