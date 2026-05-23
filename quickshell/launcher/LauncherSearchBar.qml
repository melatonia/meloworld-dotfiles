// LauncherSearchBar.qml
// Self-contained search bar with an optional mode pill on the left.
// The pill is shown whenever pillText is non-empty.
import QtQuick
import "../theme"

Rectangle {
    id: root

    // ── API ───────────────────────────────────────────────────────────────
    property alias  text:        input.text
    property string pillText:    ""
    property string placeholder: "Search..."

    signal returnPressed()
    signal escapePressed()
    signal upPressed()
    signal downPressed()
    signal leftPressed()
    signal rightPressed()
    signal tabPressed()
    signal backtabPressed()
    signal deletePressed()

    function forceActiveFocus() { input.forceActiveFocus() }
    function clear()            { input.text = "" }

    // ── Appearance ────────────────────────────────────────────────────────
    height: 42
    radius: 6
    color:  PanelColors.textBox
    Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }

    border.color: "transparent"
    border.width: 0

    // ── Inner layout ──────────────────────────────────────────────────────
    Item {
        anchors {
            fill:          parent
            leftMargin:    16
            rightMargin:   16
            topMargin:     9
            bottomMargin:  9
        }

        // Mode pill
        Rectangle {
            id: pill
            visible:                root.pillText !== ""
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 24
            width:  pillLabel.implicitWidth + 16
            radius: 12
            color:  PanelColors.rowBackground
            Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }

            Text {
                id: pillLabel
                anchors.centerIn: parent
                text:             root.pillText
                font.pixelSize:   13
                font.bold:        true
                font.family:      "JetBrainsMono Nerd Font"
                color:            PanelColors.launcher
            }
        }

        // Placeholder
        Text {
            anchors {
                left:       pill.visible ? pill.right : parent.left
                leftMargin: pill.visible ? 8 : 0
                right:      parent.right
                top:        parent.top
                bottom:     parent.bottom
            }
            text:              root.placeholder
            font.pixelSize:    16
            font.bold:         true
            font.family:       "JetBrainsMono Nerd Font"
            color:             PanelColors.textBoxDim
            verticalAlignment: Text.AlignVCenter
            visible:           input.text === ""
        }

        // Input
        TextInput {
            id: input
            anchors {
                left:       pill.visible ? pill.right : parent.left
                leftMargin: pill.visible ? 8 : 0
                right:      parent.right
                top:        parent.top
                bottom:     parent.bottom
            }
            color:             PanelColors.textMain
            font.pixelSize:    16
            font.bold:         true
            font.family:       "JetBrainsMono Nerd Font"
            selectByMouse:     true
            clip:              true
            verticalAlignment: TextInput.AlignVCenter
            activeFocusOnTab:  false

            Keys.onReturnPressed:  root.returnPressed()
            Keys.onEscapePressed:  root.escapePressed()

            Keys.onPressed: (event) => {
                switch (event.key) {
                    case Qt.Key_Up:      root.upPressed();      event.accepted = true; break
                    case Qt.Key_Down:    root.downPressed();    event.accepted = true; break
                    case Qt.Key_Left:    root.leftPressed();    event.accepted = true; break
                    case Qt.Key_Right:   root.rightPressed();   event.accepted = true; break
                    case Qt.Key_Tab:     root.tabPressed();     event.accepted = true; break
                    case Qt.Key_Backtab: root.backtabPressed(); event.accepted = true; break
                    case Qt.Key_Delete:  root.deletePressed();  event.accepted = true; break
                }
            }
        }
    }
}
