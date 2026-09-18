pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtCore
import QtQuick

// Shuffle play and search over the whole library, on top of Tauon.
//
// Tauon exposes no MPRIS TrackList or Playlists interface, so it cannot be
// told "play my library". OpenUri plays one file immediately and appends it to
// Tauon's playlist; there is no way to enqueue without playing. So the order
// lives here: we play one track, and hand over the next when this one ends.
Singleton {
    id: root

    property var  tracks: []          // from ~/.cache/dots/music.json
    property bool ready: false
    property var  order: []           // shuffled indices into tracks
    property int  cursor: -1
    property bool shuffling: false    // are we driving playback?

    readonly property var player:
        Mpris.players.values.find(p => (p.dbusName ?? "").indexOf("tauon") !== -1) ?? null
    readonly property bool playing: player ? player.isPlaying : false

    readonly property string nowTitle:  player ? (player.trackTitle  || "") : ""
    readonly property string nowArtist: player ? (player.trackArtist || "") : ""

    // ---- the index -------------------------------------------------------
    FileView {
        id: index
        path: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
                  .toString().replace(/^file:\/\//, "") + "/dots/music.json"
        watchChanges: true
        onFileChanged: index.reload()      // watchChanges alone does not re-read
        onLoaded: {
            try {
                root.tracks = JSON.parse(index.text());
                root.ready = root.tracks.length > 0;
            } catch (e) {
                console.log("Music: could not parse music.json:", e);
            }
        }
        onLoadFailed: root.ready = false   // no index yet; run music-index
    }

    function run(args) { Quickshell.execDetached(args) }

    // ---- playing ---------------------------------------------------------
    function playPath(path) {
        run(["music", "play", path]);
        lastHandover = Date.now();   // do not hand over again immediately
    }

    function playIndex(i) {
        if (i < 0 || i >= tracks.length) return;
        playPath(tracks[i].p);
    }

    // Fisher-Yates over the whole library, so every track appears once before
    // any repeats — which a random pick per track would not give you.
    function shuffleAll() {
        if (!ready) return;
        const idx = [];
        for (let i = 0; i < tracks.length; i++) idx.push(i);
        for (let i = idx.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [idx[i], idx[j]] = [idx[j], idx[i]];
        }
        order = idx;
        cursor = 0;
        shuffling = true;
        playIndex(order[0]);
    }

    // Jumping to a searched track keeps the shuffle running from there, so the
    // panel does not end your listening session.
    function playTrackAndContinue(i) {
        if (!ready) return;
        if (order.length === 0) shuffleAll();
        shuffling = true;
        playIndex(i);
    }

    function nextTrack() {
        if (!shuffling || order.length === 0) { shuffleAll(); return; }
        cursor = (cursor + 1) % order.length;
        playIndex(order[cursor]);
    }

    function toggle() {
        if (!ready) return;
        // Nothing going: start the whole library. Something going: just pause.
        if (!player || player.playbackState === MprisPlaybackState.Stopped) shuffleAll();
        else run(["music", "toggle"]);
    }

    // ---- handing over at the end of a track -------------------------------
    // Tauon auto-advances into whatever else is in its playlist, which is not
    // our shuffle order, so we hand over just before the track ends.
    //
    // Checked every couple of seconds rather than computed once when the track
    // starts: a one-shot timer is wrong the moment anything seeks, and drifts
    // besides. Polling position costs nothing and corrects itself.
    readonly property real leadSec: 2.5
    property double lastHandover: 0

    Timer {
        id: watch
        interval: 2000
        repeat: true
        running: root.shuffling && root.playing
        onTriggered: {
            const p = root.player;
            if (!p || !p.isPlaying || !(p.length > 0)) return;
            if (p.length - p.position > root.leadSec) return;
            // Tauon needs a moment to report the new track; without this the
            // next tick would see the old position and skip twice.
            const now = Date.now();
            if (now - root.lastHandover < 6000) return;
            root.lastHandover = now;
            root.nextTrack();
        }
    }

    // Re-arm whenever the track changes underneath us, including when you
    // press play in Tauon's own window rather than in the bar.
    // Pressing stop in Tauon's own window means you wanted it to stop.
    Connections {
        target: root.player
        function onIsPlayingChanged() {
            if (root.player && root.player.playbackState === MprisPlaybackState.Stopped)
                root.shuffling = false;
        }
    }
}
