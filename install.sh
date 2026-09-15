#!/usr/bin/env bash
set -euo pipefail
DOTS="$HOME/dots"

echo "==> Packages (pacman)"
sudo pacman -S --needed --noconfirm $(cat "$DOTS"/packages/{desktop,system}.txt)

echo "==> AUR helper"
if ! command -v yay >/dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    rm -rf /tmp/yay-bin
fi

echo "==> Packages (AUR)"
yay -S --needed --noconfirm $(cat "$DOTS"/packages/aur.txt)

echo "==> Dotfiles"
mkdir -p "$HOME/.config"
for dir in "$DOTS"/dotfiles/*/; do
    name=$(basename "$dir")
    rm -rf "$HOME/.config/$name"
    ln -sfn "$dir" "$HOME/.config/$name"
    echo "    linked $name"
done

echo "==> System scripts"
for s in "$DOTS"/scripts/*.sh; do "$s"; done

echo "==> Done"
