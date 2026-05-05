import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    
    property var screenObj: null
    property int barHeight: 55
    property int gap: 12
    property string animState: "closed"
    
    screen: screenObj
    
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    
    color: "transparent"
    
    margins.top: 0
    margins.left: gap
    margins.bottom: gap
    
    implicitWidth: 420
    implicitHeight: screenObj ? screenObj.height - margins.bottom : 1000
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: animState !== "closed"
    
    Connections {
        target: SessionState
        function onDashboardVisibleChanged() {
            root.animState = SessionState.dashboardVisible ? "open" : "closing"
        }
    }

    Rectangle {
        id: innerPanel
        width: parent.width
        height: parent.height
        radius: 12
        color: PanelColors.popupBackground
        border.color: PanelColors.border
        border.width: 4
        clip: true

        opacity: 0.0
        x: -20

        states: [
            State {
                name: "open"
                when: root.animState === "open"
                PropertyChanges { target: innerPanel; x: 0; opacity: 1.0 }
            },
            State {
                name: "closing"
                when: root.animState === "closing"
                PropertyChanges { target: innerPanel; x: -20; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                to: "open"
                SequentialAnimation {
                    PropertyAction { target: innerPanel; property: "x"; value: -20 }
                    PropertyAction { target: innerPanel; property: "opacity"; value: 0.0 }
                    ParallelAnimation {
                        NumberAnimation { target: innerPanel; property: "x"; to: 0; duration: 250; easing.type: Easing.OutExpo }
                        NumberAnimation { target: innerPanel; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                    }
                }
            },
            Transition {
                to: "closing"
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: innerPanel; property: "x"; to: -20; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { target: innerPanel; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                    }
                    ScriptAction { script: root.animState = "closed" }
                }
            }
        ]

        HoverHandler { id: panelHover }
        Timer {
            interval: 3000
            running: root.animState === "open" && !panelHover.hovered
            onTriggered: SessionState.dashboardVisible = false
        }

        Item {
            anchors.fill: parent
            anchors.margins: 16

            ProfileSection { id: profile; anchors.top: parent.top; width: parent.width }
            
            // Media Player now placed directly under Profile for better UX
            MediaPlayerSection { id: media; anchors.top: profile.bottom; anchors.topMargin: 12; width: parent.width }
            
            SystemStatsSection { 
                id: stats
                anchors.top: media.visible ? media.bottom : profile.bottom
                anchors.topMargin: 12
                width: parent.width 
            }
            
            // Notification Section fills the rest
            NotificationSection { 
                anchors {
                    top: stats.bottom
                    topMargin: 12
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
            }
        }
    }
}
