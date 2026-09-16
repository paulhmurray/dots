import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Shapes

PanelWindow {
    id: bar
    anchors { top: true; left: true; bottom: true }
    implicitWidth: 44
    color: Colours.bg

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    property var sink: Pipewire.defaultAudioSink
    property var bat: UPower.displayDevice

    function fmtTime(s) {
        if (!s || s <= 0) return "";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    // ---- hover popout, shared by every item ----
    PopupWindow {
        id: tip
        property Item target: null
        property string text: ""
        visible: target !== null && text !== ""
        anchor.window: bar
        anchor.rect.x: bar.width + 8
        anchor.rect.y: target ? target.mapToItem(null, 0, 0).y + target.height / 2 - height / 2 : 0
        implicitWidth: tipLabel.implicitWidth + 24
        implicitHeight: tipLabel.implicitHeight + 16
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            color: Colours.bg
            border.color: Colours.surface
            border.width: 1
            radius: 8
            Text {
                id: tipLabel
                anchors.centerIn: parent
                text: tip.text
                color: Colours.fg
                font.family: Colours.font
                font.pixelSize: 13
            }
        }
    }

    component Hover: MouseArea {
        property string label: ""
        width: 24; height: 24
        anchors.horizontalCenter: parent.horizontalCenter
        hoverEnabled: true
        onEntered: { tip.target = this; tip.text = label; }
        onExited: if (tip.target === this) tip.target = null
        onLabelChanged: if (tip.target === this) tip.text = label
    }

    component Icon: Text {
        anchors.centerIn: parent
        color: Colours.fg
        font.family: Colours.font
        font.pixelSize: 16
    }

    // ---- top: logo, workspaces ----
    Column {
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Hover {
            label: "Launcher"
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
            Icon { text: "󰣇"; color: Colours.accent; font.pixelSize: 20 }
        }

        Repeater {
            model: Hyprland.workspaces
            Hover {
                required property var modelData
                id: ws
                property var wins: Hyprland.toplevels.values.filter(t => t.workspace === modelData)
                label: wins.length > 0 ? wins.map(t => t.title).join("\n") : "empty"
                onClicked: modelData.activate()
                Icon {
                    text: modelData.id
                    color: modelData.active ? Colours.accent : Colours.dim
                    font.pixelSize: 14
                    font.bold: modelData.active
                }
                Rectangle {
                    width: 4; height: 4; radius: 2
                    color: modelData.active ? Colours.accent : Colours.dim
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: ws.wins.length > 0
                }
            }
        }
    }

    // ---- middle: clock ----
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
        hoverEnabled: true
        onEntered: { tip.target = clockCol; tip.text = Qt.formatDateTime(clock.date, "dddd d MMMM"); }
        onExited: if (tip.target === clockCol) tip.target = null
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "dashboard", "toggle"])
    }

    // ---- under the clock: weather, now playing ----
    Column {
        id: underClock
        anchors.top: clockCol.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Hover {
            label: Weather.text + "  ·  " + Weather.location
            Icon { text: Weather.icon; color: Colours.dim }
        }

        Hover {
            id: np
            property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
            visible: player !== null
            label: player ? (player.trackTitle || "Unknown") + (player.trackArtist ? " — " + player.trackArtist : "") : ""
            onClicked: if (player) player.togglePlaying()
            Icon { text: np.player && np.player.isPlaying ? "󰏤" : "󰐊"; color: Colours.accent }
        }
    }

    // ---- visualiser ----
    Column {
        anchors.top: underClock.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        visible: Cava.active
        Repeater {
            model: Cava.values
            Rectangle {
                required property var modelData
                anchors.horizontalCenter: parent.horizontalCenter
                height: 3
                radius: 1
                width: 4 + modelData / 100 * 26
                color: Colours.accent
                opacity: 0.4 + modelData / 100 * 0.6
                Behavior on width { NumberAnimation { duration: 60 } }
            }
        }
    }

    // ---- bottom: tray, wifi, volume, battery ----
    Column {
        id: bottomCol
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Hover {
            id: pomo
            property bool idle: !Pomodoro.running && Pomodoro.progress === 0 && !Pomodoro.onBreak
            label: (Pomodoro.onBreak ? "Break  " : "Focus  ") + Pomodoro.label
                + (Pomodoro.running ? "" : "  (paused)") + "\nclick: start/pause   right-click: reset"
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => mouse.button === Qt.RightButton ? Pomodoro.reset() : Pomodoro.toggle()
            Shape {
                anchors.centerIn: parent
                width: 22; height: 22
                ShapePath {
                    strokeColor: Colours.surface; strokeWidth: 3; fillColor: "transparent"
                    PathAngleArc { centerX: 11; centerY: 11; radiusX: 9; radiusY: 9; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: Pomodoro.onBreak ? Colours.green : Colours.accent
                    strokeWidth: 3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 11; centerY: 11; radiusX: 9; radiusY: 9; startAngle: -90; sweepAngle: 360 * Pomodoro.progress }
                }
            }
            Text {
                anchors.centerIn: parent
                text: pomo.idle ? "󰔛" : Math.ceil(Pomodoro.remaining / 60)
                color: pomo.idle ? Colours.dim : Colours.fg
                font.family: Colours.font
                font.pixelSize: pomo.idle ? 12 : 9
                font.bold: true
            }
        }

        Repeater {
            model: SystemTray.items
            Hover {
                required property var modelData
                label: modelData.tooltipTitle || modelData.title || modelData.id
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton && modelData.hasMenu) menu.open();
                    else modelData.activate();
                }
                IconImage { anchors.centerIn: parent; implicitSize: 18; source: modelData.icon }
                QsMenuAnchor {
                    id: menu
                    menu: modelData.menu
                    anchor.window: bar
                    anchor.rect.x: bar.width
                    anchor.rect.y: parent.mapToItem(null, 0, 0).y
                }
            }
        }

        Hover {
            label: Network.connected ? Network.ssid : "offline"
            onClicked: Quickshell.execDetached(["foot", "-e", "nmtui"])
            Icon {
                text: Network.connected ? "󰖩" : "󰖪"
                color: Network.connected ? Colours.fg : Colours.red
            }
        }

        Hover {
            id: volItem
            property bool muted: bar.sink && bar.sink.audio ? bar.sink.audio.muted : true
            property real vol: bar.sink && bar.sink.audio ? bar.sink.audio.volume : 0
            label: muted ? "muted" : Math.round(vol * 100) + "%"
            onClicked: Quickshell.execDetached(["sh", "-c",
                "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume"])
            onWheel: (wheel) => Quickshell.execDetached(["sh", "-c",
                "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%" + (wheel.angleDelta.y > 0 ? "+" : "-")
                + " && qs ipc call osd volume"])
            Icon { text: volItem.muted ? "󰖁" : volItem.vol > 0.5 ? "󰕾" : "󰖀" }
        }

        Hover {
            id: batItem
            property bool charging: bar.bat.state === UPowerDeviceState.Charging
            label: Math.round(bar.bat.percentage * 100) + "%"
                + (charging ? "  charging " + bar.fmtTime(bar.bat.timeToFull)
                            : "  " + bar.fmtTime(bar.bat.timeToEmpty) + " left")
            Icon {
                text: batItem.charging ? "󰂄"
                    : bar.bat.percentage > 0.8 ? "󰁹"
                    : bar.bat.percentage > 0.5 ? "󰁾"
                    : bar.bat.percentage > 0.2 ? "󰁻" : "󰁺"
                color: bar.bat.percentage < 0.2 && !batItem.charging ? Colours.red : Colours.fg
            }
        }
    }
}
