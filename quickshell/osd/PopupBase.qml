import QtQuick
import Quickshell
import "../theme"

// ── Shared base component for all bar popups ──────────────────────────────
// Usage:
//   PopupBase {
//       implicitWidth:  240
//       borderColor:    Colors.teal200
//       clipContent:    false          // set false only when children need to overflow (e.g. tooltips)
//       contentHeight:  myColumn.implicitHeight
//
//       Connections { target: SomeSingleton; function onFlagChanged() { animState = flag ? "open" : "closing" } }
//
//       Column { id: myColumn; anchors { top: parent.top; left: parent.left; right: parent.right; margins: parent.padding } ... }
//   }
//
// Children declared inside a PopupBase instance are placed directly inside the
// inner panel Rectangle (via the default property alias).
PopupWindow {
    id: root

    // ── Configuration ─────────────────────────────
    property string animState:     "closed"
    property color  borderColor:   PanelColors.border
    property bool   clipContent:   true
    // Bind this to your content Column's implicitHeight:
    property int    contentHeight: 0
    property int    padding:       12

    // ── Children go directly into the inner panel ──
    default property alias panelContent: innerRect.data

    visible:        animState !== "closed"
    implicitHeight: 600
    color:          "transparent"

    // ── Inner panel ───────────────────────────────
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
    }
}
