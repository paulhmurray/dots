pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string location: "Ballarat"
    property string text: "…"

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "10", "wttr.in/" + root.location + "?format=%t+%C&m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.text = text.trim() === "" ? "unavailable" : text.trim()
        }
    }
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: proc.running = true }
}
