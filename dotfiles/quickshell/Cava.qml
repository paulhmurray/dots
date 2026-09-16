pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    readonly property bool active: Mpris.players.values.some(p => p.isPlaying)
    property var values: []

    Process {
        running: root.active
        command: ["cava"]
        stdout: SplitParser {
            onRead: data => root.values = data.split(";").filter(s => s !== "").map(Number)
        }
    }
    onActiveChanged: if (!active) values = []
}
