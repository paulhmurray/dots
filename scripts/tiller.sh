#!/usr/bin/env bash
set -euo pipefail
# tiller: the personal command centre over ~/orgfiles (journal, notes, goals).
# Lives in its own public repo so this stays an anonymous fetch like every
# other install step; go is in packages/dev.txt. GOPRIVATE skips the module
# proxy and checksum database, so a push is visible here at once instead of
# whenever the proxy next looks, and it works the same on a brand new machine.
# Re-running install.sh (or this script) updates to the latest commit.
command -v go >/dev/null || { echo "    go not installed, skipping tiller"; exit 0; }
echo "==> tiller"
GOPRIVATE=github.com/paulhmurray go install github.com/paulhmurray/tiller/cmd/tiller@latest
echo "    $(go env GOPATH)/bin/tiller  ($(tiller quote 2>/dev/null | tail -1 || true))"
