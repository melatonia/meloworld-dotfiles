// LauncherSearchBar.qml
import QtQuick
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root

    // ── API ───────────────────────────────────────────────────────────────
    property alias  text:        input.text
    property string pillText:    ""
    property string placeholder: "Search..."

    property string rightPillText:        ""
    property bool   rightPillDestructive: false
    property string rightPillTooltip:     ""

    signal returnPressed()
    signal escapePressed()
    signal upPressed()
    signal downPressed()
    signal leftPressed()
    signal rightPressed()
    signal tabPressed()
    signal backtabPressed()
    signal deletePressed()
    signal rightPillClicked()

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
            fill:         parent
            leftMargin:   8
            rightMargin:  8
            topMargin:    8
            bottomMargin: 8
        }

        // Left mode pill
        Rectangle {
            id: pill
            visible:                root.pillText !== ""
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 26
            width:  pillLabel.implicitWidth + 16
            radius: 4
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

        // Right action pill
        Rectangle {
            id: rightPill
            visible:                root.rightPillText !== ""
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 26
            width:  rightPillLabel.implicitWidth + 16
            radius: 4
            color:  rightPillMouse.containsMouse
                        ? (root.rightPillDestructive ? PanelColors.error
                                                     : Qt.lighter(PanelColors.rowBackground, 1.15))
                        : PanelColors.rowBackground
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                id: rightPillLabel
                anchors.centerIn: parent
                text:             root.rightPillText
                font.pixelSize:   13
                font.bold:        true
                font.family:      "JetBrainsMono Nerd Font"
                color: root.rightPillDestructive
                           ? (rightPillMouse.containsMouse ? PanelColors.pillForeground
                                                           : PanelColors.error)
                           : PanelColors.textMain
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            MouseArea {
                id:           rightPillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.rightPillClicked()
            }

            ToolTip.visible: rightPillMouse.containsMouse && root.rightPillTooltip !== ""
            ToolTip.text:    root.rightPillTooltip
            ToolTip.delay:   500
        }

        // Placeholder
        Text {
            anchors {
                left:        pill.visible ? pill.right : parent.left
                leftMargin:  pill.visible ? 8 : 0
                right:       rightPill.visible ? rightPill.left : parent.right
                rightMargin: rightPill.visible ? 8 : 0
                top:         parent.top
                bottom:      parent.bottom
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
                left:        pill.visible ? pill.right : parent.left
                leftMargin:  pill.visible ? 8 : 0
                right:       rightPill.visible ? rightPill.left : parent.right
                rightMargin: rightPill.visible ? 8 : 0
                top:         parent.top
                bottom:      parent.bottom
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
