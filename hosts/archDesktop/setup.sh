#!/usr/bin/env bash
# archDesktop: services only. Never put disk operations in here — formatting
# the second NVMe is a deliberate, manual migration-day step.
set -euo pipefail

# Docker: socket-activated, so the daemon starts on first use rather than boot.
sudo systemctl enable docker.socket

# Ollama is optional; enable only if it got installed.
if pacman -Qq ollama >/dev/null 2>&1 || pacman -Qq ollama-cuda >/dev/null 2>&1; then
    sudo systemctl enable --now ollama
fi

# Second NVMe, if it has been prepared and added to /etc/crypttab + /etc/fstab.
if grep -q '^data ' /etc/crypttab 2>/dev/null; then
    sudo systemctl enable systemd-cryptsetup@data.service 2>/dev/null || true
fi

echo "archDesktop setup done"
