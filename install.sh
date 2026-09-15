#!/usr/bin/env bash
set -euo pipefail
DOTS="$HOME/dots"

echo "==> Packages"
sudo pacman -S --needed --noconfirm $(cat "$DOTS"/packages/*.txt)

echo "==> Dotfiles"
mkdir -p "$HOME/.config"
for dir in "$DOTS"/dotfiles/*/; do
	name=$(basename "$dir")
	rm -rf "$HOME/.config/$name"
	ln -sfn "$dir" "$HOME/.config/$name"
	echo "	linked $name"
done

echo "==> Done"
