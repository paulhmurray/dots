import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: win
    visible: false
    implicitWidth: 780
    implicitHeight: 460
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "dashboard"
        function toggle(): void { win.visible = !win.visible; }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    component Txt: Text {
        color: Colours.fg
        font.family: Colours.font
        font.pixelSize: 13
    }

    component Card: Rectangle {
        property string title
        default property alias content: body.data
        color: Colours.surface
        radius: 10
        Txt { x: 14; y: 10; text: title; color: Colours.dim; font.pixelSize: 11; font.bold: true }
        Item { id: body; anchors.fill: parent; anchors.margins: 14; anchors.topMargin: 34 }
    }

    component Meter: Item {
        property string name
        property real value: 0
        property string detail
        width: parent.width
        height: 34
        Txt { text: name; anchors.left: parent.left }
        Txt { text: detail; anchors.right: parent.right; color: Colours.dim }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 6; radius: 3
            color: Colours.bg
            Rectangle {
                width: parent.width * Math.min(value, 1); height: parent.height; radius: 3
                color: value > 0.85 ? Colours.red : Colours.accent
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.bg
        radius: 12
        border.color: Colours.accent
        border.width: 2
        focus: true
        Keys.onEscapePressed: win.visible = false

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // header: date + power buttons
            Item {
                width: parent.width
                height: 40
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                    font.pixelSize: 20
                    font.bold: true
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Repeater {
                        model: [
                            ["󰌾", "hyprlock"],
                            ["󰍃", "hyprctl dispatch exit"],
                            ["󰤄", "systemctl suspend"],
                            ["󰜉", "systemctl reboot"],
                            ["󰐥", "systemctl poweroff"]
                        ]
                        Rectangle {
                            required property var modelData
                            width: 36; height: 36; radius: 8
                            color: hover.containsMouse ? Colours.accent : Colours.surface
                            Text {
                                anchors.centerIn: parent
                                text: modelData[0]
                                color: hover.containsMouse ? Colours.bg : Colours.fg
                                font.family: Colours.font
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    win.visible = false;
                                    Quickshell.execDetached(["sh", "-c", modelData[1]]);
                                }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: parent.height - 52
                spacing: 12

                Card {
                    title: "CALENDAR"
                    width: (parent.width - 24) / 3
                    height: parent.height
                    MonthGrid {
                        id: grid
                        anchors.fill: parent
                        month: clock.date.getMonth()
                        year: clock.date.getFullYear()
                        locale: Qt.locale("en_AU")
                        delegate: Txt {
                            required property var model
                            text: model.day
                            horizontalAlignment: Text.AlignHCenter
                            opacity: model.month === grid.month ? 1 : 0.3
                            color: model.today ? Colours.accent : Colours.fg
                            font.bold: model.today
                        }
                    }
                }

                Card {
                    title: "SYSTEM"
                    width: (parent.width - 24) / 3
                    height: parent.height
                    Column {
                        anchors.fill: parent
                        spacing: 10
                        Meter { name: "CPU"; value: Stats.cpu; detail: Math.round(Stats.cpu * 100) + "%" }
                        Meter { name: "Memory"; value: Stats.mem
                                detail: Stats.memUsedGb.toFixed(1) + " / " + Stats.memTotalGb.toFixed(1) + " GB" }
                        Meter { name: "Disk /"; value: Stats.disk; detail: Math.round(Stats.disk * 100) + "%" }
                        Meter {
                            property var bat: UPower.displayDevice
                            name: "Battery"
                            value: bat.percentage
                            detail: Math.round(bat.percentage * 100) + "%"
                                + (bat.state === UPowerDeviceState.Charging ? " charging" : "")
                        }
                    }
                }

                Card {
                    title: "STATUS"
                    width: (parent.width - 24) / 3
                    height: parent.height
                    Column {
                        anchors.fill: parent
                        spacing: 10
                        Txt { text: (Network.connected ? "󰖩  " + Network.ssid : "󰖪  offline") }
                        Txt { text: "󰂯  bluetooth — stage 2"; color: Colours.dim }
                        Txt { text: "󰝚  media — stage 2"; color: Colours.dim }
                        Txt { text: "󰖙  weather — stage 2"; color: Colours.dim }
                    }
                }
            }
        }
    }
}
