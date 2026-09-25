#!/usr/bin/env bash
# Default applications for the file types you actually double-click.
#
# Each association is set independently. They used to be three bare commands
# under set -e, so if the first one failed — which it does when the .desktop
# file it names is not installed yet — the second and third never ran, and you
# were left wondering why Firefox was not the default browser.
set -uo pipefail

failed=()
set_default() {
    local app="$1"; shift
    xdg-mime default "$app" "$@" 2>/dev/null || failed+=("$app")
}

set_default org.pwmt.zathura.desktop application/pdf application/epub+zip
set_default imv.desktop               image/png image/jpeg image/webp
set_default firefox.desktop           x-scheme-handler/http x-scheme-handler/https text/html

if [ ${#failed[@]} -gt 0 ]; then
    echo "defaults.sh: could not set: ${failed[*]} (is the application installed?)" >&2
    exit 1
fi
