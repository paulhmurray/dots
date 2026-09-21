#!/usr/bin/env bash
# Pick a random wallpaper for the current (or given) theme.
#
# Images live in ~/Pictures/wallpapers, NOT in this repo: the repo is public and
# small on purpose, and ~/Pictures is already carried between machines by
# Syncthing, so wallpapers follow you without bloating git.
#
#   ~/Pictures/wallpapers/<theme>/   offered only while that theme is active
#   ~/Pictures/wallpapers/           offered whatever the theme
#
# Both are pooled together rather than the theme folder winning outright, so a
# wallpaper you like everywhere stays in the rotation after you add
# theme-specific ones.
#
# With neither, it falls back to the Hyprland default, which is why pressing
# the key used to appear to do nothing.
set -euo pipefail
DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="${1:-$(cat ~/.config/current-theme 2>/dev/null || echo mocha)}"
WALLDIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
FALLBACK=/usr/share/hypr/wall0.png

shopt -s nocaseglob nullglob
candidates=()
# Note these are the directories themselves, not a recursive search: images in
# ~/Pictures/wallpapers/<theme>/ are found by the first entry, and the shared
# folder's own files by the second, without the theme folders being swept up
# into it twice.
for dir in "$WALLDIR/$THEME" "$WALLDIR" "$DOTS/wallpapers/$THEME"; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.jpg "$dir"/*.jpeg "$dir"/*.png "$dir"/*.webp; do
        [ -f "$f" ] && candidates+=("$f")
    done
done
shopt -u nocaseglob nullglob

# What is on screen now, so a shuffle of two or more never picks it again —
# otherwise pressing the key looks broken about half the time.
current=$(pgrep -a swaybg 2>/dev/null | sed -n 's/.* -i \(.*\) -m .*/\1/p' | head -1 || true)
if [ ${#candidates[@]} -gt 1 ] && [ -n "$current" ]; then
    filtered=()
    for f in "${candidates[@]}"; do
        [ "$f" = "$current" ] || filtered+=("$f")
    done
    [ ${#filtered[@]} -gt 0 ] && candidates=("${filtered[@]}")
fi

if [ ${#candidates[@]} -gt 0 ]; then
    WALL=$(printf '%s\n' "${candidates[@]}" | shuf -n1)
else
    WALL="$FALLBACK"
    # Said once, on the only path where the key genuinely cannot do anything,
    # so an empty folder is not silent.
    if [ ! -d "$WALLDIR" ] || [ -z "$(ls -A "$WALLDIR" 2>/dev/null)" ]; then
        command -v notify-send >/dev/null && notify-send \
            "No wallpapers yet" "Put images in $WALLDIR (or $WALLDIR/$THEME)" || true
    fi
fi

pkill swaybg || true
setsid swaybg -i "$WALL" -m fill >/dev/null 2>&1 &
