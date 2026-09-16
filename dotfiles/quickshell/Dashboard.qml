import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: win
    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "dashboard"
        function toggle(): void { win.visible = !win.visible; }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    property var player: Mpris.players.values.find(p => p.isPlaying)
        ?? Mpris.players.values[0] ?? null

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

    component IconButton: Rectangle {
        property string icon
        property var action
        property bool active: true
        width: 36; height: 36; radius: 8
        color: hover.containsMouse && active ? Colours.accent : Colours.surface
        opacity: active ? 1 : 0.4
        Text {
            anchors.centerIn: parent
            text: icon
            color: hover.containsMouse && active ? Colours.bg : Colours.fg
            font.family: Colours.font
            font.pixelSize: 16
        }
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (active) action()
        }
    }

    // click outside the panel closes it
    MouseArea {
        anchors.fill: parent
        onClicked: win.visible = false
    }

    Rectangle {
        width: 780
        height: 540
        anchors.centerIn: parent
        color: Colours.bg
        radius: 12
        border.color: Colours.accent
        border.width: 2
        focus: true
        Keys.onEscapePressed: win.visible = false

        // swallow clicks on the panel itself
        MouseArea { anchors.fill: parent }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

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
                        IconButton {
                            required property var modelData
                            icon: modelData[0]
                            action: () => { win.visible = false; Quickshell.execDetached(["sh", "-c", modelData[1]]); }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: parent.height - 40 - 72 - 24
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
                        spacing: 12

                        Txt {
                            text: Network.connected ? "󰖩  " + Network.ssid : "󰖪  offline"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { win.visible = false; Quickshell.execDetached(["foot", "-e", "nmtui"]); }
                            }
                        }

                        Txt {
                            property var adapter: Bluetooth.defaultAdapter
                            property var connected: Bluetooth.devices.values.filter(d => d.connected)
                            text: !adapter || !adapter.enabled ? "󰂲  bluetooth off"
                                : connected.length > 0 ? "󰂱  " + connected.map(d => d.name).join(", ")
                                : "󰂯  bluetooth on"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { win.visible = false; Quickshell.execDetached(["foot", "-e", "bluetui"]); }
                            }
                        }

                        Txt { text: "󰖙  " + Weather.text }
                        Txt { text: Weather.location; color: Colours.dim; font.pixelSize: 11 }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 72
                radius: 10
                color: Colours.surface

                Image {
                    id: art
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44; height: 44
                    source: win.player ? win.player.trackArtUrl : ""
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                }

                Column {
                    anchors.left: art.visible ? art.right : parent.left
                    anchors.leftMargin: 14
                    anchors.right: controls.left
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Txt {
                        width: parent.width
                        elide: Text.ElideRight
                        font.bold: true
                        text: win.player ? (win.player.trackTitle || "Unknown title") : "Nothing playing"
                    }
                    Txt {
                        width: parent.width
                        elide: Text.ElideRight
                        color: Colours.dim
                        text: win.player ? win.player.trackArtist : ""
                    }
                }

                Row {
                    id: controls
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    IconButton { icon: "󰒮"; active: win.player?.canGoPrevious ?? false
                                 action: () => win.player.previous() }
                    IconButton { icon: win.player?.isPlaying ? "󰏤" : "󰐊"
                                 active: win.player?.canTogglePlaying ?? false
                                 action: () => win.player.togglePlaying() }
                    IconButton { icon: "󰒭"; active: win.player?.canGoNext ?? false
                                 action: () => win.player.next() }
                }
            }
        }
    }
}
