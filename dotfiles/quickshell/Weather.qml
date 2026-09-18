pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The location is not in this repo: it is a home address, and the repo is
// public. It comes from ~/.config/dots/location, one line, untracked. With no
// such file wttr.in geolocates by IP, which follows a laptop around but
// resolves to the ISP rather than the machine — accurate to the nearest city,
// which is why the desktop is better off naming its own.
Singleton {
    id: root
    property string location: "…"
    property string text: "…"
    readonly property string icon: {
        const t = text.toLowerCase();
        return t.includes("thunder") ? "󰖓" : t.includes("snow") ? "󰖘"
            : t.includes("rain") || t.includes("drizzle") || t.includes("shower") ? "󰖗"
            : t.includes("fog") || t.includes("mist") ? "󰖑"
            : t.includes("cloud") || t.includes("overcast") ? "󰖐"
            : t.includes("sun") || t.includes("clear") ? "󰖙" : "󰖙";
    }

    Process {
        id: proc
        // %l first so the reply names the place it actually used, whether that
        // came from the file or from the IP lookup.
        command: ["sh", "-c",
            "L=$(cat \"${XDG_CONFIG_HOME:-$HOME/.config}/dots/location\" 2>/dev/null || true); " +
            "curl -s --max-time 10 \"wttr.in/${L}?format=%l:%t+%C&m\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const reply = text.trim();
                if (reply === "") { root.text = "unavailable"; return; }
                const i = reply.indexOf(":");
                if (i === -1) { root.text = reply; return; }
                root.location = reply.slice(0, i).trim();
                root.text = reply.slice(i + 1).trim();
            }
        }
    }
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: proc.running = true }
}
