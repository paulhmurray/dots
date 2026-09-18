pragma Singleton
import Quickshell
import Quickshell.Io
import QtCore
import QtQuick

// Reads what `dots status --write` leaves in ~/.cache/dots/status.json.
// Nothing here runs a process: the file is written by a systemd user timer and
// by a path unit watching pacman, so the bar only ever reads.
Singleton {
    id: root

    property int  behind: 0
    property int  ahead: 0
    property int  dirty: 0
    property var  drift: []
    property var  aurDrift: []
    property bool stale: false
    property bool clean: true
    property string theme: ""

    // One number for the badge. Commits and packages are different kinds of
    // thing, but the bar only needs "how many things want attention".
    readonly property int count:
        behind + ahead + dirty + drift.length + aurDrift.length

    readonly property string summary: {
        const bits = [];
        if (behind > 0)         bits.push(behind + " commit(s) to pull");
        if (ahead > 0)          bits.push(ahead + " commit(s) not pushed");
        if (dirty > 0)          bits.push(dirty + " uncommitted file(s)");
        if (drift.length > 0)   bits.push("not in any list: " + drift.join(" "));
        if (aurDrift.length > 0) bits.push("AUR, not listed: " + aurDrift.join(" "));
        if (stale)              bits.push("(last check could not reach GitHub)");
        return bits.length > 0 ? bits.join("\n") : "up to date";
    }

    function ingest(text) {
        try {
            const d = JSON.parse(text);
            root.behind   = d.behind ?? 0;
            root.ahead    = d.ahead ?? 0;
            root.dirty    = (d.dirty ?? []).length;
            root.drift    = d.drift ?? [];
            root.aurDrift = d.aur_drift ?? [];
            root.stale    = d.stale ?? false;
            root.theme    = d.theme ?? "";
            root.clean    = d.clean ?? true;
        } catch (e) {
            // A half-written file is possible; the next write fixes it.
            console.log("Sync: could not parse status.json:", e);
        }
    }

    FileView {
        id: view
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
                  .toString().replace(/^file:\/\//, "") + "/dots/status.json"
        watchChanges: true

        // watchChanges reports that the file changed but does not re-read it:
        // text() keeps returning the previous contents until reload() runs, and
        // onLoaded does not fire again on its own. Verified — without this the
        // bar would show the first reading for the rest of the session.
        onFileChanged: view.reload()
        onLoaded: root.ingest(view.text())

        // No file yet (first boot, before the timer has run). Say nothing
        // rather than claiming something is wrong.
        onLoadFailed: root.clean = true
    }
}
