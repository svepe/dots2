#!/usr/bin/env bash
#
# Install the keyd config and enable the service. keyd remaps keys at the evdev
# layer (below the compositor), which is the only way to get tap/hold dual-role
# keys and a grave "nav" layer on Wayland. Config lives in the repo at
# system/keyd/default.conf (not stowed — /etc is root-owned).
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$DOTS_DIR/system/keyd/default.conf"
DST=/etc/keyd/default.conf

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# Debian/Ubuntu ship the binary as keyd.rvaiya (name-clash workaround); the
# systemd unit is 'keyd' either way.
if ! command -v keyd >/dev/null 2>&1 && ! command -v keyd.rvaiya >/dev/null 2>&1; then
  log "keyd not installed — install it (e.g. 'sudo apt install keyd') and re-run"
  exit 0
fi

sudo install -Dm644 "$SRC" "$DST"
log "installed $DST"

sudo systemctl enable --now keyd
sudo systemctl restart keyd   # reload config (name-agnostic vs 'keyd reload')
log "keyd enabled and restarted"
