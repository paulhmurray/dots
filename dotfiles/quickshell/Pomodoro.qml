pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property int workMin: 25
    property int breakMin: 5
    property bool running: false
    property bool onBreak: false
    property int remaining: workMin * 60
    readonly property int total: (onBreak ? breakMin : workMin) * 60
    readonly property real progress: 1 - remaining / total
    readonly property string label: Math.floor(remaining / 60) + ":" + String(remaining % 60).padStart(2, "0")

    function toggle() { running = !running; }
    function reset() { running = false; onBreak = false; remaining = workMin * 60; }
    function finish() {
        running = false;
        onBreak = !onBreak;
        remaining = (onBreak ? breakMin : workMin) * 60;
        Quickshell.execDetached(["notify-send", "-u", "critical",
            onBreak ? "Break time" : "Back to work",
            onBreak ? breakMin + " minutes. Click the ring to start." : workMin + " minutes. Click the ring to start."]);
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: { root.remaining--; if (root.remaining <= 0) root.finish(); }
    }
}
