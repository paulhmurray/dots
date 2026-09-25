#!/usr/bin/env bash
# t470s: laptop power management.
set -euo pipefail

if systemctl cat tlp.service >/dev/null 2>&1; then
    sudo systemctl enable --now tlp
else
    echo "tlp.service not present — skipping"
fi

# Masked, not disabled: rfkill's save/restore fights tlp over the wifi radio
# across suspend. Masking is idempotent and needs no package to be present.
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
