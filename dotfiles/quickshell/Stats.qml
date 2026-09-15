pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property real cpu: 0
    property real mem: 0
    property real disk: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property var prev: null

    Process {
        id: proc
        command: ["sh", "-c",
            "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable)' /proc/meminfo; df --output=pcent / | tail -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const c = lines[0].split(/\s+/).slice(1).map(Number);
                const idle = c[3] + c[4];
                const total = c.reduce((a, b) => a + b, 0);
                if (root.prev) {
                    const dt = total - root.prev.total;
                    if (dt > 0) root.cpu = 1 - (idle - root.prev.idle) / dt;
                }
                root.prev = { total: total, idle: idle };
                const memTotal = Number(lines[1].split(/\s+/)[1]);
                const memAvail = Number(lines[2].split(/\s+/)[1]);
                root.memTotalGb = memTotal / 1048576;
                root.memUsedGb = (memTotal - memAvail) / 1048576;
                root.mem = (memTotal - memAvail) / memTotal;
                root.disk = Number(lines[3].trim().replace("%", "")) / 100;
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: proc.running = true }
}
