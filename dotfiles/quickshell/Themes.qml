import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    visible: false
    implicitWidth: 300
    implicitHeight: 40 + themes.length * 36
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var themes: []
    property string current: ""

    Process {
        id: lister
        command: ["sh", "-c", "ls ~/dots/theme/*.sh | xargs -n1 basename | sed 's/.sh$//'; cat ~/.config/current-theme 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                win.current = lines[lines.length - 1];
                win.themes = lines.slice(0, -1).filter(t => t !== win.current || true);
                list.currentIndex = Math.max(0, win.themes.indexOf(win.current));
            }
        }
    }

    IpcHandler {
        target: "themes"
        function toggle(): void {
            win.visible = !win.visible;
            if (win.visible) { lister.running = true; list.forceActiveFocus(); }
        }
    }

    function apply() {
        const t = win.themes[list.currentIndex];
        if (t) { Quickshell.execDetached(["sh", "-c", "~/dots/theme/apply.sh " + t]); win.visible = false; }
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.bg
        border.color: Colours.accent
        border.width: 2
        radius: 10

        Text {
            x: 16; y: 12
            text: "THEME"
            color: Colours.dim
            font.family: Colours.font
            font.pixelSize: 11
            font.bold: true
        }

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 8
            anchors.topMargin: 32
            model: win.themes
            highlightMoveDuration: 0
            highlight: Rectangle { color: Colours.surface; radius: 6 }
            Keys.onReturnPressed: win.apply()
            Keys.onEscapePressed: win.visible = false
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onPressed: (e) => { if (e.key === Qt.Key_J) incrementCurrentIndex(); if (e.key === Qt.Key_K) decrementCurrentIndex(); }

            delegate: Item {
                required property var modelData
                required property int index
                width: list.width
                height: 36
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    text: modelData + (modelData === win.current ? "  ●" : "")
                    color: index === list.currentIndex ? Colours.accent : Colours.fg
                    font.family: Colours.font
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { list.currentIndex = index; win.apply(); }
                }
            }
        }
    }
}
