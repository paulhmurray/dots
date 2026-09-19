pragma Singleton
import Quickshell
import Quickshell.Io
import QtCore
import QtQuick

// Unread count for the bar, written by the dots-mail timer.
//
// Nothing here talks to Thunderbird. bin/mail-count reads the IMAP folder
// status with its own credential, so the number is right whether the mail
// client is running or not, and stays right across Thunderbird upgrades.
Singleton {
    id: root

    property int  unread: 0
    property bool ok: true          // false once a check has failed
    property string error: ""
    property string checkedAt: ""

    readonly property string summary: {
        if (!ok && error === "no credentials")
            return "Mail not set up yet\nrun: mail setup";
        const n = unread === 0 ? "No unread mail"
                : unread === 1 ? "1 unread message"
                : unread + " unread messages";
        return ok ? n : n + "\n(last check failed: " + error + ")";
    }

    FileView {
        id: view
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
                  .toString().replace(/^file:\/\//, "") + "/dots/mail.json"
        watchChanges: true
        onFileChanged: view.reload()     // watchChanges does not re-read on its own
        onLoaded: {
            try {
                const d = JSON.parse(view.text());
                root.unread    = d.unread ?? 0;
                root.ok        = d.ok ?? false;
                root.error     = d.error ?? "";
                root.checkedAt = d.checked_at ?? "";
            } catch (e) {
                console.log("Mail: could not parse mail.json:", e);
            }
        }
        onLoadFailed: { root.unread = 0; root.ok = false; root.error = "no credentials"; }
    }
}
