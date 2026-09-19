import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    visible: false
    implicitWidth: 620
    // Tall enough for every binding, so a cheatsheet does not need scrolling —
    // but never taller than the screen it is on, for the laptop's sake.
    implicitHeight: Math.min(win.binds.length * 28 + 60,
                             (screen ? screen.height : 900) - 120)
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var binds: []

    Process {
        id: loader
        command: ["sh", "-c", "grep -E '^bind[a-z]* *=' ~/.config/hypr/hyprland.conf"]
        stdout: StdioCollector {
            onStreamFinished: {
                win.binds = text.trim().split("\n").map(line => {
                    let [body, comment] = line.split("#");
                    const rhs = body.substring(body.indexOf("=") + 1);
                    const parts = rhs.split(",").map(s => s.trim());
                    const mods = parts[0].replace("$mod", "Super").replace("SHIFT", "Shift")
                        .replace("CTRL", "Ctrl").replace("ALT", "Alt").split(" ").filter(s => s);
                    // Hyprland's key names are not what anyone calls these keys.
                    const nicer = {
                        RETURN: "Enter", SPACE: "Space", ESCAPE: "Esc", SLASH: "/",
                        PRINT: "PrtSc", MonBrightnessUp: "Brightness up",
                        MonBrightnessDown: "Brightness down",
                        AudioRaiseVolume: "Volume up", AudioLowerVolume: "Volume down",
                        AudioMute: "Mute", AudioPlay: "Play", AudioNext: "Next",
                        AudioPrev: "Previous",
                        "mouse:272": "Left-drag", "mouse:273": "Right-drag"
                    };
                    const raw = parts[1].replace("XF86", "");
                    const key = nicer[raw] ?? raw.replace(/^([a-z])/, c => c.toUpperCase());
                    const combo = [...mods, key].join(" + ");
                    const desc = comment ? comment.trim()
                        : parts[2] === "exec" ? parts.slice(3).join(",").replace("$term", "terminal")
                        : parts.slice(2).join(" ");
                    return { combo: combo, desc: desc };
                });

                // Collapse runs that differ only by a trailing number, so the
                // nine workspace binds read as one line instead of burying
                // everything below them under eighteen near-identical rows.
                const rolled = [];
                for (const b of win.binds) {
                    const m = b.desc.match(/^(.*?) (\d+)$/);
                    const prev = rolled[rolled.length - 1];
                    if (m && prev && prev._stem === m[1]) {
                        prev._last = m[2];
                        prev.combo = prev._first + "…" + m[2];
                        prev.desc = m[1];
                        continue;
                    }
                    if (m) {
                        rolled.push({ combo: b.combo, desc: b.desc, _stem: m[1],
                                      _first: b.combo, _last: m[2] });
                    } else {
                        rolled.push({ combo: b.combo, desc: b.desc });
                    }
                }
                win.binds = rolled;
            }
        }
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void {
            win.visible = !win.visible;
            if (win.visible) { loader.running = true; list.forceActiveFocus(); }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.bg
        border.color: Colours.accent
        border.width: 2
        radius: 10

        Text {
            x: 16; y: 12
            text: "KEYBINDINGS"
            color: Colours.dim
            font.family: Colours.font
            font.pixelSize: 11
            font.bold: true
        }

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 36
            clip: true
            model: win.binds
            Keys.onEscapePressed: win.visible = false
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_J || e.key === Qt.Key_Down) contentY = Math.min(contentY + 40, contentHeight - height);
                if (e.key === Qt.Key_K || e.key === Qt.Key_Up) contentY = Math.max(contentY - 40, 0);
            }

            delegate: Item {
                required property var modelData
                width: list.width
                height: 28
                Text {
                    x: 8
                    width: 200
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.combo
                    color: Colours.accent
                    font.family: Colours.font
                    font.pixelSize: 13
                    font.bold: true
                }
                Text {
                    x: 216
                    width: parent.width - 224
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.desc
                    color: Colours.fg
                    font.family: Colours.font
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: win.visible = false
        }
    }
}
