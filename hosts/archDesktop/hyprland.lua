-- archDesktop — Ryzen 7 5700X, RTX 3060, three displays.
--
-- NVIDIA driver, env vars and early KMS are NOT here: scripts/hardware.sh
-- detects the GPU and writes dotfiles/hypr/hardware.lua. Keep this file to
-- what is genuinely specific to this machine's desk.
--
-- Carried from Omarchy's ~/.config/hypr/monitors.conf, 17 Sep 2026. Only DP-1
-- was attached when this was captured; the other two were verified by Paul as
-- present but unplugged. Hyprland ignores rules for absent outputs, so leaving
-- all three listed is safe.

hl.monitor({ output = "DP-1",     mode = "3440x1440@99", position = "0x0",     scale = 1 })               -- Samsung C34H89x ultrawide
hl.monitor({ output = "DP-2",     mode = "1920x1080@60", position = "-1080x0", scale = 1, transform = 3 }) -- left, rotated 270
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "3440x0",  scale = 1, transform = 1 }) -- right, rotated 90

-- Anything else that appears gets a sane default rather than stacking at 0x0.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.workspace_rule({ workspace = "1", monitor = "DP-2",     default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1",     default = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", default = true })

-- Carried verbatim from the Omarchy config. Worth a second look: a global
-- GDK_SCALE of 2 on a 3440x1440 panel makes GTK apps very large. If GTK apps
-- look oversized on the ultrawide after migration, this line is why.
hl.env("GDK_SCALE", "2")

-- tiller scratchpad, about 80% of the panel height.
return { tiller_size = { 1300, 1150 } }
