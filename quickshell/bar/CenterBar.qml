import QtQuick
import "widgets"

Row {
    property alias clockWidget: clockWidget
    ClockWidget { id: clockWidget; anchors.verticalCenter: parent.verticalCenter }
}
