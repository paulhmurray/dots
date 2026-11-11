-- Hyprland configuration. Lua, because Hyprland 0.57 dropped the hyprlang
-- format that hyprland.conf was written in: a 0.57 login ignores that file,
-- logs "No config file found" and writes a stock example here instead.
--
-- Three machine-specific modules are loaded first, in the order the old
-- `source` lines used. Each is optional: a fresh machine without a hosts/
-- folder, or one where theme/apply.sh has not run yet, gets a working desktop
-- rather than a parse error.
--   colours.lua  — written by theme/apply.sh from theme/<name>.sh
--   host.lua     — symlink to hosts/<hostname>/hyprland.lua, made by install.sh
--   hardware.lua — written by scripts/hardware.sh from the detected GPU
-- `hyprctl reload` rebuilds the Lua state, so require() re-reads them and a
-- theme change reaches the borders without a restart.
local function optional(name)
    local ok, mod = pcall(require, name)
    if ok and type(mod) == "table" then return mod end
    return {}
end

local C = optional("colours")
local H = optional("host")
optional("hardware")

local mod  = "SUPER"
local term = "foot"

-- Window rules take pixel sizes, so the tiller scratchpad height is chosen per
-- screen: hosts/<name>/hyprland.lua returns { tiller_size = { w, h } }. The
-- home screen trims its lists to fit whatever it gets, but more rows means
-- more journal days and notes on show.
local tiller_size = H.tiller_size or { 1300, 850 }

hl.config({
    input = {
        kb_layout  = "us",
        kb_options = "ctrl:nocaps",
        touchpad   = { natural_scroll = true },
        -- The scratchpads (tiller, mail, music, news) are floating windows on
        -- special workspaces. Without this, a special workspace that holds
        -- only floating windows swallows focus, so you cannot scroll or click
        -- a browser showing underneath tiller. With it, focus follows the
        -- mouse between the two: hover the browser to read or copy, hover
        -- tiller to type.
        special_fallthrough = true,
    },
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,
        layout      = "dwindle",
        col = {
            active_border   = C.accent or "rgb(cba6f7)",
            inactive_border = C.dim    or "rgb(6c7086)",
        },
    },
    decoration = {
        rounding = 6,
    },
})

----------------------------------------------------------------------------
-- Autostart. hyprland.start fires once per session, not on reload, which is
-- what exec-once did.
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("mako")
    -- --no-tray. --smart-tray looks like the right answer and is not: it
    -- hides the icon only when nothing removable is attached, and the backup
    -- drive lives plugged in at /run/media/paulm/backup, which udisks reports
    -- as HOTPLUG. So the icon would be permanent anyway — the same "always
    -- lit, therefore meaningless" problem the bar avoids elsewhere.
    --
    -- Automounting and the notifications are untouched; only the icon goes.
    -- To unmount by hand: udiskie-umount /run/media/paulm/<name>, or -a.
    hl.exec_cmd("udiskie --automount --notify --no-tray")
    hl.exec_cmd("~/dots/theme/wall.sh")
    -- Relay syncs and reminds only while open; the mail-home rule hides it.
    hl.exec_cmd("mail ensure")
end)

----------------------------------------------------------------------------
-- Binds. Every one carries a description: that is what Super+/ lists (the
-- bar reads `hyprctl -j binds`), so it is the user-facing name of the key.
local function bind(keys, dsp, desc, opts)
    opts = opts or {}
    opts.description = desc
    return hl.bind(keys, dsp, opts)
end
local function run(cmd) return hl.dsp.exec_cmd(cmd) end

bind(mod .. " + R",         run("pkill quickshell; quickshell &"),     "Restart the bar")
bind(mod .. " + Return",    run(term),                                 "Terminal")
bind(mod .. " + Q",         hl.dsp.window.close(),                     "Close the focused window")
bind(mod .. " + SHIFT + Q", hl.dsp.exit(),                             "Log out of Hyprland")
bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen(),                "Fullscreen the focused window")
bind(mod .. " + V",         hl.dsp.window.float({ action = "toggle" }), "Float or tile the focused window")
bind(mod .. " + space",     run("qs ipc call launcher toggle"),        "App launcher")
bind(mod .. " + B",         run("firefox"),                            "Firefox")

-- Resize the focused window. Repeats while the keys are held, and in the
-- dwindle layout this moves the split rather than floating anything.
local rep = { repeating = true }
bind(mod .. " + CTRL + H", hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), "Make the window narrower", rep)
bind(mod .. " + CTRL + L", hl.dsp.window.resize({ x =  40, y = 0,   relative = true }), "Make the window wider",    rep)
bind(mod .. " + CTRL + K", hl.dsp.window.resize({ x =   0, y = -40, relative = true }), "Make the window shorter",  rep)
bind(mod .. " + CTRL + J", hl.dsp.window.resize({ x =   0, y = 40,  relative = true }), "Make the window taller",   rep)

-- Drag with the mouse: hold Super and use either button anywhere in the
-- window, so there is no hunting for a one-pixel border.
bind(mod .. " + mouse:272", hl.dsp.window.drag(),   "Drag to move the window",   { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Drag to resize the window", { mouse = true })

bind(mod .. " + H", hl.dsp.focus({ direction = "left" }),  "Focus the window to the left")
bind(mod .. " + L", hl.dsp.focus({ direction = "right" }), "Focus the window to the right")
bind(mod .. " + K", hl.dsp.focus({ direction = "up" }),    "Focus the window above")
bind(mod .. " + J", hl.dsp.focus({ direction = "down" }),  "Focus the window below")

for i = 1, 9 do
    bind(mod .. " + " .. i,            hl.dsp.focus({ workspace = i }),       "Go to workspace " .. i)
    bind(mod .. " + SHIFT + " .. i,    hl.dsp.window.move({ workspace = i }), "Send window to workspace " .. i)
end

-- Media keys work on the lock screen too (locked), and the steps repeat.
local held = { locked = true, repeating = true }
bind("XF86MonBrightnessUp",   run("brightnessctl set 5%+ && qs ipc call osd brightness"),                 "Backlight, 5% steps",        held)
bind("XF86MonBrightnessDown", run("brightnessctl set 5%- && qs ipc call osd brightness"),                 "Backlight, 5% steps",        held)
bind("XF86AudioRaiseVolume",  run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && qs ipc call osd volume"), "Speaker volume, 5% steps",   held)
bind("XF86AudioLowerVolume",  run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && qs ipc call osd volume"), "Speaker volume, 5% steps",   held)
bind("XF86AudioMute",         run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume"), "Toggle speaker mute", { locked = true })

bind(mod .. " + Escape", run("hyprlock"), "Lock the screen")

-- Screenshots: region to clipboard, full screen to ~/Pictures.
bind(mod .. " + SHIFT + S", run([[grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "region copied"]]),                       "Screenshot a region to the clipboard")
bind("Print",               run([[mkdir -p ~/Pictures && grim ~/Pictures/$(date +%Y%m%d-%H%M%S).png && notify-send "Screenshot" "saved"]]), "Screenshot the screen to ~/Pictures")

bind(mod .. " + F",         run("foot -e yazi"),               "Files (yazi)")
bind(mod .. " + SHIFT + W", run("foot -e bluetui"),            "Bluetooth devices")
bind(mod .. " + D",         run("qs ipc call dashboard toggle"), "Dashboard — calendar, system, weather, dots")

----------------------------------------------------------------------------
-- Scratchpads. Each lives on its own special workspace: it overlays whatever
-- you are doing when you ask for it and vanishes again, without ever taking
-- one of the nine numbered workspaces or moving you off the one you are on.
-- "silent" opens it without showing it; the bin/* scripts bring it up.

-- Tauon, the music player.
hl.window_rule({
    name  = "tauon-home",
    match = { class = "^(tauonmb)$" },
    workspace = "special:music silent",
    float = true,
    size  = { 1100, 720 },
})

-- The news reader is a terminal program, so the window is a foot instance
-- with its own app-id — matching that rather than "foot" keeps every other
-- terminal out of the scratchpad.
hl.window_rule({
    name  = "news-home",
    match = { class = "^(dots-news)$" },
    workspace = "special:news silent",
    float = true,
    size  = { 1300, 850 },
})

-- Mail gets the same treatment as the music player. Relay only syncs and
-- fires reminders while its window exists, so `mail ensure` above starts it
-- at login and this rule keeps it out of sight.
hl.window_rule({
    name  = "mail-home",
    match = { class = [[^(app\.relay\.Relay)$]] },
    workspace = "special:mail silent",
    float = true,
    size  = { 1400, 900 },
    -- Hyprland refuses to resize or move a maximised window, so a client that
    -- maximises itself on startup would silently ignore the size above.
    suppress_event = "maximize",
})

-- tiller is a terminal program like the news reader: a foot instance with its
-- own app-id on its own scratchpad, so the journal is one key away from
-- whatever you are doing and gone again when you are done.
hl.window_rule({
    name  = "tiller-home",
    match = { class = "^(dots-tiller)$" },
    workspace = "special:tiller silent",
    float = true,
    size  = tiller_size,
})

bind(mod .. " + E",         run("mail window"),              "Email — show or hide it over your work")
bind(mod .. " + SHIFT + E", run("mail pane"),                "Email — as a tile on this workspace")
bind(mod .. " + O",         run("tiller-window"),            "Tiller — journal, notes and goals over your work")
bind(mod .. " + M",         run("qs ipc call music toggle"), "Search and play from the music library")
bind(mod .. " + SHIFT + M", run("music window"),             "Show or hide the music player")
bind(mod .. " + N",         run("news window"),              "News reader")
bind(mod .. " + SHIFT + N", run("qs ipc call music next"),   "Skip to the next shuffled track")
bind(mod .. " + SHIFT + P", run("music toggle"),             "Play or pause the music")
bind("XF86AudioPlay",       run("playerctl play-pause"),     "Play or pause whatever is playing", { locked = true })
bind("XF86AudioNext",       run("playerctl next"),           "Next track in the running player",  { locked = true })
bind("XF86AudioPrev",       run("playerctl previous"),       "Previous track in the running player", { locked = true })
bind(mod .. " + T",         run("qs ipc call themes toggle"),   "Theme picker")
bind(mod .. " + P",         run("qs ipc call pomodoro toggle"), "Pomodoro timer")
bind(mod .. " + SHIFT + T", run("~/dots/theme/wall.sh"),        "New wallpaper")
bind(mod .. " + slash",     run("qs ipc call keybinds toggle"), "Show this list")
