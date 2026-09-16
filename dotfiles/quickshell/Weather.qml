pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string location: "Ballarat"
    property string text: "…"
    readonly property string icon: {
        const t = text.toLowerCase();
        return t.includes("thunder") ? "󰖓" : t.includes("snow") ? "󰖘"
            : t.includes("rain") || t.includes("drizzle") || t.includes("shower") ? "󰖗"
            : t.includes("fog") || t.includes("mist") ? "󰖑"
            : t.includes("cloud") || t.includes("overcast") ? "󰖐"
            : t.includes("sun") || t.includes("clear") ? "󰖙" : "󰖙";
    }

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
