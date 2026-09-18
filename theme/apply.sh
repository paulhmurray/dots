#!/usr/bin/env bash
# Regenerates every colour file from one palette.
#
# Order matters: all files are written first, then things that can fail are
# done. The generated files are not tracked, so a run that dies half way leaves
# the machine with no colours at all — nvim's init.lua does require("theme"),
# and Hyprland and quickshell both error on a missing file.
set -euo pipefail
DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# With no argument, keep the theme this machine already chose. The theme is a
# per-machine choice and is not repo state, so defaulting to a fixed name would
# let any automated caller — install.sh, dots sync — silently switch it.
THEME="${1:-}"
[ -n "$THEME" ] || THEME=$(cat "$HOME/.config/current-theme" 2>/dev/null || true)
if [ -z "$THEME" ]; then
    THEME=mocha                          # fresh machine, nothing chosen yet
elif [ ! -f "$DOTS/theme/$THEME.sh" ]; then
    echo "theme '$THEME' has no palette; falling back to mocha" >&2
    THEME=mocha
fi
source "$DOTS/theme/$THEME.sh"

# ---- write everything ----------------------------------------------------
# Every directory, because four of these files are the only tracked thing in
# theirs — foot, mako, nvim/lua and zathura simply do not exist in a fresh
# clone now that the generated files are untracked.
mkdir -p "$DOTS"/dotfiles/{hypr,foot,quickshell,mako,tmux,zathura} \
         "$DOTS/dotfiles/nvim/lua"

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

echo "return \"$NVIM\"" > "$DOTS/dotfiles/nvim/lua/theme.lua"

cat > "$DOTS/dotfiles/zathura/zathurarc" << ZATH
set font "JetBrainsMono Nerd Font 11"
set default-bg "#$BG"
set default-fg "#$FG"
set statusbar-bg "#$BG_ALT"
set statusbar-fg "#$FG"
set inputbar-bg "#$BG_ALT"
set inputbar-fg "#$FG"
set completion-bg "#$SURFACE"
set completion-fg "#$FG"
set completion-highlight-bg "#$ACCENT"
set completion-highlight-fg "#$BG"
set index-bg "#$BG"
set index-fg "#$FG"
set index-active-bg "#$ACCENT"
set index-active-fg "#$BG"
set highlight-color "rgba($(printf '%d,%d,%d' 0x${YELLOW:0:2} 0x${YELLOW:2:2} 0x${YELLOW:4:2}),0.5)"
set recolor true
set recolor-lightcolor "#$BG"
set recolor-darkcolor "#$FG"
set recolor-keephue true
set selection-clipboard clipboard
set adjust-open "best-fit"
set guioptions ""
map r recolor
ZATH

# Recorded only once every file above exists, so a failed run does not leave
# this machine claiming a theme it has not actually got.
echo "$THEME" > "$HOME/.config/current-theme"

# ---- then tell everything to pick it up ----------------------------------
# Past this point nothing writes a colour file, so a failure here costs a
# reload, not a machine with half a theme.

hyprctl reload >/dev/null 2>&1 || true
pkill quickshell || true
setsid quickshell >/dev/null 2>&1 &
makoctl reload 2>/dev/null || true
tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
"$DOTS/theme/wall.sh" "$THEME" || true

echo "theme applied: $THEME"
