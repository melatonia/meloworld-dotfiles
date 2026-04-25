import QtQuick
import qs.bar.widgets

Row {
    spacing: 6

    property alias audioWidget: audioWidget
    property alias bluetoothWidget: bluetoothWidget
    property alias batteryWidget: batteryWidget
    property alias sessionWidget: sessionWidget
    property alias networkWidget: networkWidget

    TrayBar          { anchors.verticalCenter: parent.verticalCenter }
    BrightnessWidget { anchors.verticalCenter: parent.verticalCenter }
    AudioWidget      { id: audioWidget; anchors.verticalCenter: parent.verticalCenter }
    BluetoothWidget  { id: bluetoothWidget; anchors.verticalCenter: parent.verticalCenter }
    NetworkWidget    { id: networkWidget; anchors.verticalCenter: parent.verticalCenter }
    BatteryWidget    { id: batteryWidget; anchors.verticalCenter: parent.verticalCenter }
    DateWidget       { anchors.verticalCenter: parent.verticalCenter }
    SessionWidget    { id: sessionWidget; anchors.verticalCenter: parent.verticalCenter }
}
