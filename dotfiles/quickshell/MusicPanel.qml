import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Search the library and play anything in it. Opened deliberately — right-click
// the bar item or Super+M — rather than on hover, because a search box wants
// keyboard focus and a panel that vanishes when the pointer leaves is no use.
PanelWindow {
    id: win
    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var results: []

    function refilter() {
        const q = search.text.trim().toLowerCase();
        const all = Music.tracks;
        const out = [];
        if (q === "") {
            // Nothing typed: a sample of the library rather than the first few
            // hundred alphabetically, so it looks like a library and not like
            // whatever sorts first.
            for (let i = 0; i < all.length && out.length < 300; i += Math.max(1, Math.floor(all.length / 300)))
                out.push(i);
        } else {
            // "s" is pre-lowered by music-index: title, artist and album in one
            // string, so a search spans all three without touching three fields.
            const terms = q.split(/\s+/);
            for (let i = 0; i < all.length; i++) {
                const hay = all[i].s;
                let ok = true;
                for (let t = 0; t < terms.length; t++)
                    if (hay.indexOf(terms[t]) === -1) { ok = false; break; }
                if (ok && out.push(i) >= 500) break;
            }
        }
        win.results = out;
        list.currentIndex = out.length > 0 ? 0 : -1;
    }

    IpcHandler {
        target: "music"
        function toggle(): void { win.visible = !win.visible; }
        function shuffle(): void { Music.shuffleAll(); }
        function next(): void { Music.nextTrack(); }
    }

    onVisibleChanged: {
        if (visible) { search.text = ""; refilter(); search.forceActiveFocus(); }
    }

    MouseArea { anchors.fill: parent; onClicked: win.visible = false }

    Rectangle {
        width: 760
        height: 520
        anchors.centerIn: parent
        color: Colours.bg
        radius: 12
        border.color: Colours.accent
        border.width: 2
        MouseArea { anchors.fill: parent }   // swallow clicks on the panel

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ---- search box ----
            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: Colours.surface
                Text {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    color: Colours.dim
                    font.family: Colours.font
                    font.pixelSize: 15
                }
                TextInput {
                    id: search
                    x: 38
                    width: parent.width - 50
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.fg
                    font.family: Colours.font
                    font.pixelSize: 15
                    selectionColor: Colours.accent
                    selectedTextColor: Colours.bg
                    focus: true
                    onTextChanged: win.refilter()

                    Keys.onEscapePressed: win.visible = false
                    Keys.onReturnPressed: win.playSelected()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: search.text === ""
                        text: Music.ready
                              ? "Search " + Music.tracks.length + " tracks"
                              : "No index yet — run music-index"
                        color: Colours.dim
                        font.family: Colours.font
                        font.pixelSize: 15
                    }
                }
            }

            // ---- results ----
            ListView {
                id: list
                width: parent.width
                height: parent.height - 40 - 36 - 24
                clip: true
                model: win.results
                highlightMoveDuration: 0
                highlight: Rectangle { color: Colours.surface; radius: 6 }

                delegate: Item {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 34
                    readonly property var track: Music.tracks[modelData]

                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        elide: Text.ElideRight
                        text: (track.a !== "" ? track.a + "  ·  " : "") + track.t
                        color: index === list.currentIndex ? Colours.accent : Colours.fg
                        font.family: Colours.font
                        font.pixelSize: 14
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: track.b
                        color: Colours.dim
                        font.family: Colours.font
                        font.pixelSize: 11
                        width: parent.width * 0.3
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { list.currentIndex = index; win.playSelected(); }
                    }
                }
            }

            // ---- footer ----
            Item {
                width: parent.width
                height: 24
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.results.length + (search.text === "" ? " shown" : " matching")
                    color: Colours.dim
                    font.family: Colours.font
                    font.pixelSize: 11
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "enter play    ·    esc close    ·    shuffling continues from your pick"
                    color: Colours.dim
                    font.family: Colours.font
                    font.pixelSize: 11
                }
            }
        }
    }

    // test hook: drive the filter without a keyboard
    function searchFor(q) { search.text = q; refilter(); }

    function playSelected() {
        if (list.currentIndex < 0 || list.currentIndex >= results.length) return;
        Music.playTrackAndContinue(results[list.currentIndex]);
        win.visible = false;
    }
}
