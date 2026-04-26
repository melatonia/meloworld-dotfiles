import QtQuick

Item {
    id: container
    property alias spacing: innerRow.spacing
    property color bgColor: "#212121"
    default property alias children: innerRow.children

    height: 40
    width: innerRow.implicitWidth + 12

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: container.bgColor
    }

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: 6
    }
}