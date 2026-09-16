import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick

PanelWindow {
    anchors { top: true; left: true; bottom: true }
    implicitWidth: 44
    color: Colours.bg

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // top: logo, workspaces
    Column {
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        MouseArea {
            width: 24; height: 24
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
            Text {
                anchors.centerIn: parent
                text: "󰣇"
                color: Colours.accent
                font.family: Colours.font
                font.pixelSize: 20
            }
        }

        Repeater {
            model: Hyprland.workspaces
            MouseArea {
                required property var modelData
                width: 24; height: 24
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: modelData.activate()
                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    color: modelData.active ? Colours.accent : Colours.dim
                    font.family: Colours.font
                    font.pixelSize: 14
                    font.bold: modelData.active
                }
            }
        }
    }

    // middle: clock
    Column {
        id: clockCol
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH")
            color: Colours.fg
            font.family: Colours.font
            font.pixelSize: 14
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            color: Colours.fg
            font.family: Colours.font
            font.pixelSize: 14
        }
    }

    MouseArea {
        anchors.fill: clockCol
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "dashboard", "toggle"])
    }

    // bottom: wifi, volume, battery
    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        MouseArea {
            width: 24; height: 24
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: Quickshell.execDetached(["foot", "-e", "nmtui"])
            Text {
                anchors.centerIn: parent
                text: Network.connected ? "󰖩" : "󰖪"
                color: Network.connected ? Colours.fg : Colours.red
                font.family: Colours.font
                font.pixelSize: 16
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            property var sink: Pipewire.defaultAudioSink
            text: !sink || !sink.audio || sink.audio.muted ? "󰖁"
                : sink.audio.volume > 0.5 ? "󰕾" : "󰖀"
            color: Colours.fg
            font.family: Colours.font
            font.pixelSize: 16
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            property var bat: UPower.displayDevice
            property bool charging: bat.state === UPowerDeviceState.Charging
            text: charging ? "󰂄"
                : bat.percentage > 0.8 ? "󰁹"
                : bat.percentage > 0.5 ? "󰁾"
                : bat.percentage > 0.2 ? "󰁻" : "󰁺"
            color: bat.percentage < 0.2 && !charging ? Colours.red : Colours.fg
            font.family: Colours.font
            font.pixelSize: 16
        }
    }
}
