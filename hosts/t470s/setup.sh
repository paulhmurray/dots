#!/usr/bin/env bash
set -euo pipefail
sudo systemctl enable --now tlp
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
