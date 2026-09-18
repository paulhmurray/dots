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

# Files theme/apply.sh generates into tracked paths. They are derived from the
# palette, so discarding them loses nothing — which is what lets `dots sync`
# clear them before pulling. Without that, two machines on different themes can
# never fast-forward: every one of these differs, permanently.
DOTS_GENERATED=(
    dotfiles/hypr/colours.conf
    dotfiles/hypr/hyprlock.conf
    dotfiles/foot/foot.ini
    dotfiles/quickshell/Colours.qml
    dotfiles/mako/config
    dotfiles/tmux/colours.conf
    dotfiles/nvim/lua/theme.lua
    dotfiles/zathura/zathurarc
)

# Packages whose upgrade means the running system no longer matches what is on
# disk. The 18 Sep upgrade here bumped amd-ucode, linux-firmware and mesa and
# would have reported nothing under a linux/nvidia/systemd-only list.
# The || true matters: grep exits 1 when nothing matches, and this runs inside
# a command substitution under set -euo pipefail, so an empty result would kill
# the upgrade rather than report "nothing worth rebooting for".
dots_reboot_watch() {
    pacman -Q 2>/dev/null | grep -E \
        '^(linux|linux-lts|linux-zen|linux-hardened|linux-firmware[^ ]*|nvidia[^ ]*|systemd|amd-ucode|intel-ucode|mesa|aquamarine) ' \
        || true
}

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

# Two different questions, deliberately two functions.
#
# dots_dirty is "is there anything I should be nagged about?" — it drops the
# self-writing files, so a plugin update does not light the bar indicator.
#
# dots_dirty_all is "is there anything that will stop a fast-forward?" — it
# drops nothing, because git does not care why a file is modified. Using the
# first for the second means sync hits a raw git error on exactly the files it
# claimed to have handled.
dots_dirty_all() {
    git -C "$DOTS" status --porcelain --untracked-files=no 2>/dev/null | cut -c4-
}

dots_dirty() {
    dots_dirty_all | while read -r f; do
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
