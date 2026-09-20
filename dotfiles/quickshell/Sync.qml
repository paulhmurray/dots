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

    // Available updates, deliberately NOT part of status.json and never shown
    // on the bar: Arch always has updates, so an indicator driven by them is
    // permanently lit and therefore means nothing. Fetched when the Dashboard
    // opens — a deliberate "tell me where things stand" — rather than on a
    // timer or on hover, either of which would hit a mirror constantly.
    property int  updates: -1        // -1 = not checked yet this session
    property int  aurUpdates: -1
    property string lastUpgrade: ""
    property bool checking: false

    function refreshUpdates() {
        if (updateProc.running) return;
        root.checking = true;
        updateProc.running = true;
    }

    Process {
        id: updateProc
        // checkupdates syncs into its own temp database, so this needs no sudo
        // and cannot cause a partial upgrade. It exits 2 when there is nothing
        // to report, which is why the count comes from wc rather than $?.
        command: ["sh", "-c",
            "checkupdates 2>/dev/null | wc -l; " +
            "yay -Qua 2>/dev/null | wc -l; " +
            "grep 'starting full system upgrade' /var/log/pacman.log 2>/dev/null " +
            "| tail -1 | sed 's/^\\[//; s/T.*//'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.updates    = Number(l[0] ?? 0);
                root.aurUpdates = Number(l[1] ?? 0);
                root.lastUpgrade = (l[2] ?? "").trim();
                root.checking = false;
            }
        }
    }

    // The git side, one entry per thing that is true. A single line would have
    // to pick a winner, and "3 commits to pull" while quietly sitting on 2
    // uncommitted files is exactly the half-truth the Dashboard exists to
    // avoid. Empty when there is nothing to say.
    readonly property var gitLines: {
        const out = [];
        if (behind > 0) out.push(behind + " commit(s) to pull");
        if (ahead > 0)  out.push(ahead + " commit(s) to push");
        if (dirty > 0)  out.push(dirty + " uncommitted file(s)");
        return out;
    }

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

    // Run a command in a terminal that stays open if it fails.
    //
    // `foot -e dots sync` closes the moment the command exits, so a failure —
    // "uncommitted changes would be overwritten" — flashed up and vanished,
    // and clicking the icon looked like it did nothing at all. On success it
    // still closes straight away; only failure waits for a keypress.
    //
    // bash -lc, not plain -c: a login shell picks up ~/.local/bin from
    // .bashrc, so this cannot fail merely because the bar was started with a
    // thinner PATH.
    function runInTerminal(cmd) {
        Quickshell.execDetached(["foot", "-e", "bash", "-lc",
            cmd + ' || { printf "\n\n[%s exited %s]\npress any key to close" "' + cmd + '" "$?"; read -rsn1; }']);
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
