#!/usr/bin/env bash
# set a random wallpaper for the current (or given) theme; solid colour if none
set -euo pipefail
DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="${1:-$(cat ~/.config/current-theme 2>/dev/null || echo mocha)}"
source "$DOTS/theme/$THEME.sh"
pkill swaybg || true
WALL=$(find "$DOTS/wallpapers/$THEME" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | shuf -n1 || true)
if [ -n "$WALL" ]; then
    setsid swaybg -i "$WALL" -m fill >/dev/null 2>&1 &
else
    setsid swaybg -i /usr/share/hypr/wall0.png -m fill >/dev/null 2>&1 &
fi
