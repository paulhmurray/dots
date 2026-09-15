#!/usr/bin/env bash
set -euo pipefail
DOTS="$HOME/dots"
source "$DOTS/theme/${1:-mocha}.sh"

cat > "$DOTS/dotfiles/hypr/colours.conf" << CONF
\$bg = rgb($BG)
\$bg_hex = $BG
\$accent = rgb($ACCENT)
\$dim = rgb($DIM)
CONF

{
  echo "font=JetBrainsMono Nerd Font:size=11"
  echo "pad=8x8"
  echo
  echo "[colors-dark]"
  echo "background=$BG"
  echo "foreground=$FG"
  for i in {0..7};  do echo "regular$i=${ANSI[$i]}"; done
  for i in {8..15}; do echo "bright$((i-8))=${ANSI[$i]}"; done
} > "$DOTS/dotfiles/foot/foot.ini"

cat > "$DOTS/dotfiles/quickshell/Colours.qml" << QML
pragma Singleton
import Quickshell

Singleton {
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string bg: "#$BG"
    readonly property string bgAlt: "#$BG_ALT"
    readonly property string surface: "#$SURFACE"
    readonly property string fg: "#$FG"
    readonly property string dim: "#$DIM"
    readonly property string accent: "#$ACCENT"
    readonly property string red: "#$RED"
    readonly property string green: "#$GREEN"
    readonly property string yellow: "#$YELLOW"
    readonly property string blue: "#$BLUE"
}
QML

cat > "$DOTS/dotfiles/hypr/hyprlock.conf" << LOCK
general {
    hide_cursor = true
}

background {
    monitor =
    color = rgb($BG)
}

label {
    monitor =
    text = \$TIME
    color = rgb($FG)
    font_size = 48
    font_family = JetBrainsMono Nerd Font
    position = 0, 80
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 250, 50
    position = 0, -20
    halign = center
    valign = center
    outer_color = rgb($ACCENT)
    inner_color = rgb($SURFACE)
    font_color = rgb($FG)
    placeholder_text = <i>password</i>
}
LOCK

mkdir -p "$DOTS/dotfiles/mako"
cat > "$DOTS/dotfiles/mako/config" << MAKO
font=JetBrainsMono Nerd Font 11
background-color=#$BG
text-color=#$FG
border-color=#$ACCENT
border-size=2
border-radius=6
default-timeout=5000
anchor=top-right
margin=10
MAKO

hyprctl reload >/dev/null 2>&1 || true
pkill quickshell || true
setsid quickshell >/dev/null 2>&1 &
pkill swaybg || true
setsid swaybg -c "#$BG" >/dev/null 2>&1 &
makoctl reload 2>/dev/null || true
echo "theme applied: ${1:-mocha}"

cat > "$DOTS/dotfiles/tmux/colours.conf" << TMUX
set -g status-style "bg=#$BG_ALT,fg=#$FG"
set -g status-left-length 30
set -g status-left "#[bg=#$ACCENT,fg=#$BG,bold]  #S #[bg=#$BG_ALT,fg=#$ACCENT]#[default] "
set -g status-right "#[fg=#$BLUE] #(cat /etc/hostname)  #[fg=#$GREEN]󰥔 %H:%M #[fg=#$YELLOW]󰃭 %a %d %b "
set -g window-status-format "#[fg=#$DIM] #I #W "
set -g window-status-current-format "#[bg=#$SURFACE,fg=#$ACCENT,bold] #I #W #[default]"
set -g window-status-separator ""
set -g pane-border-style "fg=#$SURFACE"
set -g pane-active-border-style "fg=#$ACCENT"
set -g message-style "bg=#$SURFACE,fg=#$FG"
TMUX
tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
