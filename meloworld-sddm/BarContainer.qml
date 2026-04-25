import QtQuick 2.15

Rectangle {
    id: container
    property alias spacing: innerRow.spacing
    default property alias children: innerRow.children

    height: 40
    radius: 8
    color: "#212121"
    width: innerRow.implicitWidth + 12

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: 6
    }
}
