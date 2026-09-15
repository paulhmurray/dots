#!/usr/bin/env bash
set -euo pipefail
DOTS="$HOME/dots"
source "$DOTS/theme/${1:-mocha}.sh"

cat > "$DOTS/dotfiles/hypr/colours.conf" << CONF
\$bg = rgb($BG)
\$accent = rgb($ACCENT)
\$dim = rgb($DIM)
CONF

{
  echo "font=JetBrainsMono Nerd Font:size=11"
  echo "pad=8x8"
  echo
  echo "[colors]"
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

echo "singleton Colours 1.0 Colours.qml" > "$DOTS/dotfiles/quickshell/qmldir"

hyprctl reload >/dev/null 2>&1 || true
pkill quickshell || true
setsid quickshell >/dev/null 2>&1 &
echo "theme applied: ${1:-mocha}"
