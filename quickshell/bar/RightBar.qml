import QtQuick
import qs.bar.widgets

Row {
    spacing: 6

    TrayBar        { anchors.verticalCenter: parent.verticalCenter }
    BatteryWidget  { anchors.verticalCenter: parent.verticalCenter }
    NetworkWidget  { anchors.verticalCenter: parent.verticalCenter }
    BluetoothWidget{ anchors.verticalCenter: parent.verticalCenter }
    AudioWidget    { anchors.verticalCenter: parent.verticalCenter }
    DateWidget     { anchors.verticalCenter: parent.verticalCenter }
    SessionWidget  { anchors.verticalCenter: parent.verticalCenter }
}
