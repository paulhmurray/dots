#!/usr/bin/env bash
set -euo pipefail
xdg-mime default org.pwmt.zathura.desktop application/pdf application/epub+zip
xdg-mime default imv.desktop image/png image/jpeg image/webp
xdg-mime default firefox.desktop x-scheme-handler/http x-scheme-handler/https text/html
