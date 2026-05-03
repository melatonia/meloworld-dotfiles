import QtQuick
import QtQml.Models
import Quickshell
import "../theme"

PopupBase {
    id: root
    implicitWidth: 200
    borderColor: PanelColors.tray
    contentHeight: contentCol.implicitHeight

    Connections {
        target: TrayState
        function onVisibleChanged() {
            root.animState = TrayState.visible ? "open" : "closing"
        }
    }

    QsMenuOpener {
        id: menuOpener
        menu: TrayState.activeItem ? TrayState.activeItem.menu : null
    }

    Column {
        id: contentCol
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
        spacing: 4

        Text {
            width: parent.width
            visible: TrayState.activeItem !== null && TrayState.activeItem.title !== ""
            text: TrayState.activeItem ? TrayState.activeItem.title : ""
            font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono Nerd Font"
            color: PanelColors.textDim
            bottomPadding: 4
        }

        Instantiator {
            id: menuInstantiator
            model: menuOpener.children
            asynchronous: false

            delegate: Item {
                id: entryDelegate
                required property QsMenuEntry modelData
                required property int index
                width: contentCol.width
                height: modelData.isSeparator ? 9 : 34

                Rectangle {
                    visible: entryDelegate.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width; height: 2
                    color: PanelColors.border
                }

                Rectangle {
                    visible: !entryDelegate.modelData.isSeparator
                    width: parent.width; height: 34; radius: 6
                    color: entryMouse.containsMouse
                        ? Qt.lighter(PanelColors.rowBackground, 1.15)
                        : PanelColors.rowBackground
                    opacity: entryDelegate.modelData.enabled ? 1.0 : 0.4

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Rectangle {
                        width: 3; height: parent.height - 10; radius: 2
                        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                        color: PanelColors.textDim
                    }

                    Row {
                        anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 8

                        property bool hasIcon: entryDelegate.modelData.icon && entryDelegate.modelData.icon !== ""

                        Image {
                            visible: parent.hasIcon
                            width: parent.hasIcon ? 16 : 0   // ← collapse to 0 when no icon
                            height: 16
                            source: parent.hasIcon ? entryDelegate.modelData.icon : ""
                            sourceSize.width: 16; sourceSize.height: 16
                            smooth: true; mipmap: true
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: entryDelegate.modelData.text || ""
                            font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: PanelColors.textMain
                            anchors.verticalCenter: parent.verticalCenter

                            // Add these:
                            width: parent.width - x  // remaining width after icon + spacing
                            elide: Text.ElideRight   // truncate with … instead of overflowing
                        }
                    }

                    MouseArea {
                        id: entryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: entryDelegate.modelData.enabled
                        onClicked: {
                            entryDelegate.modelData.triggered()
                            TrayState.hide()
                        }
                    }
                }
            }

            onObjectAdded: (index, object) => {
                object.parent = contentCol
            }
            onObjectRemoved: (index, object) => {
                object.parent = null
            }
        }
    }
}
