#!/usr/bin/env bash
#
# Install sudoers drop-ins from system/sudoers.d/ into /etc/sudoers.d/ (root,
# mode 0440). Each file is syntax-checked with `visudo` before install so a typo
# can't lock you out of sudo. Not stowed (/etc is root-owned). Needs sudo.
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$DOTS_DIR/system/sudoers.d"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }

[ -d "$SRC" ] || { log "no system/sudoers.d, nothing to do"; exit 0; }

for f in "$SRC"/*; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  # sudo ignores drop-ins whose name contains a '.', so reject those early.
  case "$name" in *.*) err "skip $name (dot in name — sudo would ignore it)"; continue;; esac
  if ! sudo visudo -cf "$f" >/dev/null 2>&1; then
    err "skip $name (failed visudo syntax check)"
    continue
  fi
  sudo install -m 0440 -o root -g root "$f" "/etc/sudoers.d/$name"
  log "installed /etc/sudoers.d/$name"
done

sudo visudo -c >/dev/null && log "sudoers OK" || err "sudoers validation FAILED"
