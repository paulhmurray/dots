#!/usr/bin/env bash
set -euo pipefail
DOTS="$HOME/dots"

# Host selection, most explicit wins:  ./install.sh <name>  >  DOTS_HOST=<name>
# >  /etc/hostname.  A machine with no hosts/ folder is a supported case, not an
# error: scripts/hardware.sh detects CPU and GPU so a new box needs no host layer.
HOST="${1:-${DOTS_HOST:-$(cat /etc/hostname)}}"

echo "==> Packages (pacman)"
sudo pacman -S --needed --noconfirm $(cat "$DOTS"/packages/{desktop,system,dev}.txt)

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

echo "==> Dotfiles"
mkdir -p "$HOME/.config"
for dir in "$DOTS"/dotfiles/*/; do
    name=$(basename "$dir")
    rm -rf "$HOME/.config/$name"
    ln -sfn "$dir" "$HOME/.config/$name"
    echo "    linked $name"
done

echo "==> Home files"
for f in "$DOTS"/home/.[!.]*; do
    name=$(basename "$f")
    rm -f "$HOME/$name"
    ln -sfn "$f" "$HOME/$name"
    echo "    linked $name"
done

echo "==> Command"
mkdir -p "$HOME/.local/bin"
ln -sfn "$DOTS/bin/dots" "$HOME/.local/bin/dots"
echo "    linked dots"

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

echo "==> System scripts"
for s in "$DOTS"/scripts/*.sh; do "$s"; done


echo "==> Verifying"
for bin in Hyprland foot quickshell nvim; do
    command -v "$bin" >/dev/null || { echo "MISSING: $bin"; exit 1; }
done
for f in host.conf hardware.conf; do
    [ -f "$DOTS/dotfiles/hypr/$f" ] || { echo "MISSING: dotfiles/hypr/$f"; exit 1; }
done

echo "==> Done"

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
