pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The bar's view of the music: MPD over MPRIS (mpd-mpris), driven through
// bin/music.
//
// MPD has a real queue, so none of the old Tauon workarounds are needed: no
// track index, no handing over one file at a time. Play with nothing queued
// shuffles the whole library (`music toggle`); searching and choosing music
// happen in Cadence (Super+M).
Singleton {
    id: root

    readonly property var player:
        Mpris.players.values.find(p => (p.dbusName ?? "").indexOf("mpd") !== -1) ?? null
    readonly property bool playing: player ? player.isPlaying : false

    readonly property string nowTitle:  player ? (player.trackTitle  || "") : ""
    readonly property string nowArtist: player ? (player.trackArtist || "") : ""

    function run(args) { Quickshell.execDetached(args) }

    function toggle()    { run(["music", "toggle"]) }
    function nextTrack() { run(["music", "next"]) }
    function search()    { run(["music", "window"]) }
}
