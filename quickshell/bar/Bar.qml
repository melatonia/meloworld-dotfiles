import QtQuick
import "."
import "widgets"
import "../theme"

Item {
    id: root

    property alias rightContainer: rightContainer
    property alias rightBar: rightBar

    Rectangle {
        id: leftContainer
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 15
        color: PanelColors.barBackground
        radius: 8
        width: leftBar.implicitWidth + 12

        LeftBar {
            id: leftBar
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: centerContainer
        anchors.centerIn: parent
        height: parent.height - 15
        color: PanelColors.barBackground
        radius: 8
        width: centerBar.implicitWidth + 12

        CenterBar {
            id: centerBar
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: rightContainer
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 15
        color: PanelColors.barBackground
        radius: 8
        width: rightBar.implicitWidth + 12

        RightBar {
            id: rightBar
            anchors.centerIn: parent
        }
    }
}
