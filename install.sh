#!/usr/bin/env bash
set -euo pipefail
DOTS="$HOME/dots"
HOST=$(cat /etc/hostname)

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
    echo "    no hosts/$HOST folder — using defaults"
    echo "monitor = , preferred, auto, 1" > "$DOTS/dotfiles/hypr/host.conf"
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

echo "==> System scripts"
for s in "$DOTS"/scripts/*.sh; do "$s"; done


echo "==> Verifying"
for bin in Hyprland foot quickshell nvim; do
    command -v "$bin" >/dev/null || { echo "MISSING: $bin"; exit 1; }
done

echo "==> Done"
