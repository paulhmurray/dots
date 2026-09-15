pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string ssid: ""
    readonly property bool connected: ssid !== ""

    Process {
        id: proc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.ssid = text.trim()
        }
    }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: proc.running = true }
}
