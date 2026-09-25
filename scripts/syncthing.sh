#!/usr/bin/env bash
# User unit, so no sudo. Guarded the same way as bluetooth.sh.
set -euo pipefail
if systemctl --user cat syncthing.service >/dev/null 2>&1; then
    systemctl --user enable --now syncthing
else
    echo "syncthing.service not present (syncthing not installed?) — skipping"
fi
