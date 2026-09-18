#!/usr/bin/env bash
# Status logic shared by bin/dots and the systemd timer. Sourced, never run.
# Every function here only reads: no sudo, no pacman transaction, no fetch.

DOTS="${DOTS:-$HOME/dots}"
DOTS_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dots"

# Tracked files the running system rewrites by itself. They stay in git on
# purpose — lazy-lock.json pins plugin versions so both machines match — but
# they must not make the bar report "uncommitted changes" every time a plugin
# updates, or the indicator stops meaning anything.
DOTS_SELF_WRITING=(
    dotfiles/nvim/lazy-lock.json
)

# Read package lists exactly as install.sh does: unquoted $(cat), so every
# whitespace-separated word is a package name. Keeps this check honest for
# lists that put several packages on one line, as desktop.txt does.
dots_words() {
    cat "$@" 2>/dev/null | tr -s '[:space:]' '\n' | grep -v '^$' | sort -u
}

dots_host() { cat /etc/hostname; }

# Everything this repo declares for this machine, plus what hardware.sh
# installed for the hardware it found (recorded in the cache, because
# re-deriving it would mean re-running detection).
#
# aur.txt counts here too: a package can move from the AUR into a repo —
# tauon-music-box did — and it is still declared, not drift.
dots_declared() {
    {
        dots_words "$DOTS"/packages/{base,desktop,system,dev,aur}.txt \
                   "$DOTS/hosts/$(dots_host)/packages.txt"
        sort -u "$DOTS_CACHE/hardware-pkgs" 2>/dev/null
    } | sort -u
}

# Explicitly installed, from a repo, declared nowhere: installed by hand and
# never written down. This is the number that should be zero.
dots_drift() {
    comm -23 <(pacman -Qqen | sort -u) <(dots_declared)
}

# The same question for foreign (AUR) packages, which pacman -Qqen never sees.
# yay bootstraps itself in install.sh, so it is legitimately in no list.
dots_aur_drift() {
    comm -23 <(pacman -Qqem | sort -u) \
             <({ dots_words "$DOTS/packages/aur.txt"
                 printf 'yay-bin\nyay-bin-debug\n'; } | sort -u)
}

# "behind<TAB>ahead" against the tracked upstream. Reports the last fetch
# rather than fetching, so it is cheap and safe to call as often as you like.
# Ahead matters: a `dots add` whose push failed leaves commits here, and the
# next pull --ff-only will refuse until they are dealt with.
dots_behind_ahead() {
    git -C "$DOTS" rev-list --count --left-right '@{u}...HEAD' 2>/dev/null \
        || printf '0\t0\n'
}

# Uncommitted changes, minus the files above. Paths only, one per line.
dots_dirty() {
    git -C "$DOTS" status --porcelain 2>/dev/null | cut -c4- | while read -r f; do
        for skip in "${DOTS_SELF_WRITING[@]}"; do
            [ "$f" = "$skip" ] && continue 2
        done
        printf '%s\n' "$f"
    done
}

# The theme this machine chose. Per-machine by design: it is not repo state,
# and a difference between machines is not drift.
dots_theme() {
    cat "$HOME/.config/current-theme" 2>/dev/null || echo unknown
}
