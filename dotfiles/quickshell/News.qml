pragma Singleton
import Quickshell
import Quickshell.Io
import QtCore
import QtQuick

// Headlines for the Dashboard, written by the dots-news timer.
//
// Deliberately has no bar indicator. Unread news is always high, so a badge
// driven by it would be permanently lit and therefore meaningless — the same
// reason the update count never reached the bar. This is something you look at
// when you open the Dashboard, not something that interrupts.
Singleton {
    id: root

    property var  stories: []
    property int  sources: 0
    property int  failed: 0
    property string checkedAt: ""

    readonly property bool ready: stories.length > 0

    function open(url) {
        if (url) Quickshell.execDetached(["firefox", url]);
    }

    FileView {
        id: view
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
                  .toString().replace(/^file:\/\//, "") + "/dots/news.json"
        watchChanges: true
        onFileChanged: view.reload()     // watchChanges does not re-read on its own
        onLoaded: {
            try {
                const d = JSON.parse(view.text());
                root.stories   = d.stories ?? [];
                root.sources   = d.sources ?? 0;
                root.failed    = d.failed ?? 0;
                root.checkedAt = d.checked_at ?? "";
            } catch (e) {
                console.log("News: could not parse news.json:", e);
            }
        }
        onLoadFailed: root.stories = []
    }
}
