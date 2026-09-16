import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    visible: false
    anchors.bottom: true
    margins.bottom: 40
    implicitWidth: 260
    implicitHeight: 48
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    property string icon: ""
    property real value: 0

    function show() { win.visible = true; hide.restart(); }
    Timer { id: hide; interval: 1500; onTriggered: win.visible = false }

    IpcHandler {
        target: "osd"
        function brightness(): void { bright.running = true; }
        function volume(): void { vol.running = true; }
    }

    Process {
        id: bright
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                win.icon = "󰃠";
                win.value = parseInt(f[3]) / 100;
                win.show();
            }
        }
    }

    Process {
        id: vol
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "Volume: 0.45 [MUTED]"
                const muted = text.includes("MUTED");
                const v = parseFloat(text.split(" ")[1]) || 0;
                win.icon = muted ? "󰖁" : v > 0.5 ? "󰕾" : "󰖀";
                win.value = muted ? 0 : v;
                win.show();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colours.bg
        border.color: Colours.surface
        border.width: 1
        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.icon
                color: Colours.accent
                font.family: Colours.font
                font.pixelSize: 18
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34
                height: 6
                radius: 3
                color: Colours.surface
                Rectangle {
                    width: parent.width * Math.min(win.value, 1)
                    height: parent.height
                    radius: 3
                    color: Colours.accent
                    Behavior on width { NumberAnimation { duration: 120 } }
                }
            }
        }
    }
}
