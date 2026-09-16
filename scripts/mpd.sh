#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/Music ~/.local/state/mpd/playlists
systemctl --user enable --now mpd mpd-mpris
