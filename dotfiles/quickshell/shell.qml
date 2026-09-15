import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick

ShellRoot {
    id: root


    property string ssid: "offline"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // track the default sink so its volume is live
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // wifi name, polled via nmcli
    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
        running: true
        stdout: SplitParser {
            onRead: data => root.ssid = data.trim() === "" ? "offline" : data.trim()
        }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: wifiProc.running = true }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 30
            color: Colours.bg

            // left: workspaces
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                MouseArea {
                    width: logo.width
                    height: logo.height
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: Quickshell.execDetached(["fuzzel"])
                    Text {
                        id: logo
                        text: "󰣇"
                        color: Colours.accent
                        font.family: Colours.font
                        font.pixelSize: 18
                    }
                }
                Repeater {
                    model: Hyprland.workspaces
                    Text {
                        required property var modelData
                        text: modelData.id
                        color: modelData.active ? Colours.accent : Colours.dim
                        font.family: Colours.font
                        font.pixelSize: 14
                    }
                }
            }

            // centre: clock
            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                color: Colours.fg
                font.family: Colours.font
                font.pixelSize: 14
            }

            // right: wifi, volume, battery
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                Text {
                    text: "󰖩 " + root.ssid
                    color: Colours.fg
                    font.family: Colours.font
                    font.pixelSize: 14
                }

                Text {
                    property var sink: Pipewire.defaultAudioSink
                    text: sink && sink.audio
                        ? (sink.audio.muted ? "󰖁 muted" : "󰕾 " + Math.round(sink.audio.volume * 100) + "%")
                        : "󰖁 --"
                    color: Colours.fg
                    font.family: Colours.font
                    font.pixelSize: 14
                }

                Text {
                    property var bat: UPower.displayDevice
                    property bool charging: bat.state === UPowerDeviceState.Charging
                    text: (charging ? "󰂄 " : "󰁹 ") + Math.round(bat.percentage * 100) + "%"
                    color: bat.percentage < 0.2 && !charging ? Colours.red : Colours.fg
                    font.family: Colours.font
                    font.pixelSize: 14
                }
            }
        }
    }
}
