#!/usr/bin/env bash
set -euo pipefail
# The repo this script lives in, not a hardcoded ~/dots: bin/dots,
# scripts/hardware.sh and theme/apply.sh all resolve themselves the same way,
# so a clone anywhere works instead of silently operating on a path that may
# not exist.
DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Host selection, most explicit wins:  ./install.sh <name>  >  DOTS_HOST=<name>
# >  /etc/hostname.  A machine with no hosts/ folder is a supported case, not an
# error: scripts/hardware.sh detects CPU and GPU so a new box needs no host layer.
HOST="${1:-${DOTS_HOST:-$(cat /etc/hostname)}}"

echo "==> Packages (pacman)"
# One list at a time, and on failure one package at a time. A single renamed or
# mistyped name used to abort the whole run under set -e, before any symlink was
# made — so a machine could end up with packages and no configuration at all.
# Now the good ones land, the bad ones are named, and the run continues.
PKG_FAILED=()
install_list() {
    local file="$1" name pkg
    name=$(basename "$file" .txt)
    # shellcheck disable=SC2046  # word splitting is the point: see the list format
    if sudo pacman -S --needed --noconfirm $(cat "$file"); then
        return 0
    fi
    echo "    '$name' failed as a batch — retrying one at a time to find the culprit"
    for pkg in $(cat "$file"); do
        sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1 \
            || { echo "      could not install: $pkg"; PKG_FAILED+=("$pkg"); }
    done
}
for list in desktop system dev; do
    install_list "$DOTS/packages/$list.txt"
done

echo "==> AUR helper"
if ! command -v yay >/dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    rm -rf /tmp/yay-bin
fi

echo "==> Packages (AUR)"
yay -S --needed --noconfirm $(cat "$DOTS"/packages/aur.txt)

echo "==> Host: $HOST"
if [ -d "$DOTS/hosts/$HOST" ]; then
    [ -f "$DOTS/hosts/$HOST/packages.txt" ] && \
        sudo pacman -S --needed --noconfirm $(cat "$DOTS/hosts/$HOST/packages.txt")
    [ -f "$DOTS/hosts/$HOST/hyprland.conf" ] && \
        ln -sfn "$DOTS/hosts/$HOST/hyprland.conf" "$DOTS/dotfiles/hypr/host.conf"
    [ -x "$DOTS/hosts/$HOST/setup.sh" ] && "$DOTS/hosts/$HOST/setup.sh"
else
    echo "    no hosts/$HOST folder — using auto-detected defaults"
    echo "monitor = , preferred, auto, 1" > "$DOTS/dotfiles/hypr/host.conf"
    NO_HOST=1
fi

echo "==> Theme"
# Before the symlinks, not after. The generated colour files are untracked, so
# on a fresh clone dotfiles/{foot,mako,zathura} and nvim/lua do not exist at
# all — apply.sh is what creates them, and the loop below only links
# directories that are already there. Bare, so an existing machine keeps the
# theme it chose; a new one gets mocha.
"$DOTS/theme/apply.sh"

echo "==> Dotfiles"
mkdir -p "$HOME/.config"
# rm -rf on a symlink removes the link, which is what we want on a re-run. On a
# real directory it would remove someone's actual config, so that gets moved
# aside instead. A fresh archinstall has a real ~/.bashrc from /etc/skel, so
# this is the normal first-run path, not an edge case.
link_over() {
    local src="$1" dest="$2" name="$3"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local keep="$dest.pre-dots.$(date +%Y%m%d-%H%M%S)"
        mv "$dest" "$keep"
        echo "    kept your existing $name as $(basename "$keep")"
    else
        rm -rf "$dest"
    fi
    ln -sfn "$src" "$dest"
    echo "    linked $name"
}

for dir in "$DOTS"/dotfiles/*/; do
    name=$(basename "$dir")
    link_over "$dir" "$HOME/.config/$name" "$name"
done

echo "==> Home files"
for f in "$DOTS"/home/.[!.]*; do
    name=$(basename "$f")
    link_over "$f" "$HOME/$name" "$name"
done

echo "==> Command"
mkdir -p "$HOME/.local/bin"
for b in "$DOTS"/bin/*; do
    ln -sfn "$b" "$HOME/.local/bin/$(basename "$b")"
    echo "    linked $(basename "$b")"
done

echo "==> Music index"
# Guarded: a fresh machine may have no library yet, and an empty index is not
# a reason to fail an install.
if [ -d "$HOME/Music" ]; then
    "$DOTS/bin/music-index" || echo "    index failed — run music-index by hand"
else
    echo "    no ~/Music yet, skipping"
fi

echo "==> Desktop entries"
# Overrides for launcher entries, e.g. routing Thunderbird through `mail show`
# so picking it from the launcher brings the scratchpad into view instead of
# opening a window you cannot see. The filename must match the one the package
# ships (org.mozilla.Thunderbird.desktop, not thunderbird.desktop) or it adds a
# second entry beside it rather than replacing it.
if [ -d "$DOTS/desktop" ]; then
    mkdir -p "$HOME/.local/share/applications"
    for d in "$DOTS"/desktop/*.desktop; do
        [ -e "$d" ] || continue
        ln -sfn "$d" "$HOME/.local/share/applications/$(basename "$d")"
        echo "    linked $(basename "$d")"
    done
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo "==> Hooks"
# Per clone, so a fork or a fresh machine gets the secret scan without anyone
# remembering to turn it on.
git -C "$DOTS" config core.hooksPath hooks
echo "    pre-commit secret scan enabled"

echo "==> Remote"
# HTTPS, not SSH: reading a public repo needs no credentials, so the status
# timer can fetch with nobody present. An SSH remote would need a passphrase
# or an agent, and this repo has no business touching ~/.ssh. Pushing uses a
# repo-scoped token instead — see "Committing from a new machine" in README.
# Only the URL we know about is rewritten, so a fork keeps its own remote.
case "$(git -C "$DOTS" remote get-url origin 2>/dev/null || true)" in
    git@github.com:paulhmurray/dots.git|ssh://git@github.com/paulhmurray/dots.git)
        git -C "$DOTS" remote set-url origin https://github.com/paulhmurray/dots.git
        echo "    origin switched to https"
        ;;
    *) echo "    origin left as is" ;;
esac

echo "==> Services"
# User units, not system ones: they run as you, need no sudo, and only ever
# write ~/.cache/dots/status.json. Detection is automatic; applying anything
# stays a deliberate click.
mkdir -p "$HOME/.config/systemd/user"
for u in "$DOTS"/systemd/*; do
    ln -sfn "$u" "$HOME/.config/systemd/user/$(basename "$u")"
done
systemctl --user daemon-reload
systemctl --user enable --now dots-status.timer dots-pacman.path dots-mail.timer dots-news.timer
echo "    dots-status.timer, dots-pacman.path, dots-mail.timer, dots-news.timer"

echo "==> System scripts"
for s in "$DOTS"/scripts/*.sh; do "$s"; done


echo "==> Verifying"
for bin in Hyprland foot quickshell nvim; do
    command -v "$bin" >/dev/null || { echo "MISSING: $bin"; exit 1; }
done
for f in host.conf hardware.conf colours.conf; do
    [ -f "$DOTS/dotfiles/hypr/$f" ] || { echo "MISSING: dotfiles/hypr/$f"; exit 1; }
done
# The generated set, none of it tracked: if apply.sh failed, say so here rather
# than leaving Hyprland with a dangling source and nvim unable to require().
for f in foot/foot.ini quickshell/Colours.qml mako/config tmux/colours.conf \
         nvim/lua/theme.lua zathura/zathurarc; do
    [ -f "$DOTS/dotfiles/$f" ] || { echo "MISSING: dotfiles/$f — theme/apply.sh did not finish"; exit 1; }
done
for d in "$HOME"/.config/{foot,mako,zathura}; do
    [ -e "$d" ] || { echo "MISSING: $d"; exit 1; }
done

echo "==> Done"

# Printed after "Done", where it is still on screen. A package that failed to
# install is the one thing here you have to act on.
if [ ${#PKG_FAILED[@]} -gt 0 ]; then
    cat <<EOF

    NOTE: these packages could not be installed:
        ${PKG_FAILED[*]}

    Everything else was installed and all configuration was linked. Usually a
    package has been renamed or dropped from the repos: check with
    'pacman -Ss <name>', then fix the list and 'dots add' the new name.
EOF
fi

# Printed last, where it is still on screen after a long install.
if [ -n "${NO_HOST:-}" ]; then
    cat <<EOF

    NOTE: no hosts/$HOST/ folder, so displays fall back to "preferred, auto".
    Hardware (microcode, GPU driver, Hyprland env) was detected and configured
    regardless. To pin a monitor layout for this machine:

        mkdir -p "$DOTS/hosts/$HOST"
        hyprctl monitors -j | jq -r '.[] | "monitor = \(.name), \(.width)x\(.height)@\(.refreshRate|floor), \(.x)x\(.y), 1"' \
            > "$DOTS/hosts/$HOST/hyprland.conf"
        ./install.sh
EOF
fi
