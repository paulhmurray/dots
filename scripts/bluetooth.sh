#!/usr/bin/env bash
# Guarded on the unit existing rather than assuming it. A machine without bluez
# has a missing package, which is worth saying — but this script runs from
# install.sh, and a bare failure here used to take every later script with it.
set -euo pipefail
if systemctl cat bluetooth.service >/dev/null 2>&1; then
    sudo systemctl enable --now bluetooth
else
    echo "bluetooth.service not present (bluez not installed?) — skipping"
fi
