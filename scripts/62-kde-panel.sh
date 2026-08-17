#!/usr/bin/env bash
#
# Restore the Plasma panel + desktop layout from a snapshot. The layout lives in
# plasma-org.kde.plasma.desktop-appletsrc — an interdependent tree (panels,
# widgets, their configs) that can't be expressed via kwriteconfig, so we
# snapshot the whole file and copy it into place.
#
# NOT stowed: plasmashell rewrites this file constantly at runtime, so a symlink
# into the repo would spew churn. It's also machine/screen-specific. After GUI
# tweaks, re-snapshot with:
#   cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc kde/
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$DOTS_DIR/kde/plasma-org.kde.plasma.desktop-appletsrc"
DST="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

[ -f "$SRC" ] || { log "no panel snapshot at $SRC — skipping"; exit 0; }

# Back up the existing layout (once) before overwriting.
if [ -f "$DST" ] && [ ! -f "$DST.dots-bak" ]; then
  cp -f "$DST" "$DST.dots-bak"
  log "backed up existing layout to $DST.dots-bak"
fi
install -Dm644 "$SRC" "$DST"
log "restored panel layout to $DST"

# Reload plasmashell so the new layout takes effect (only if it's running).
if pgrep -x plasmashell >/dev/null 2>&1; then
  if systemctl --user restart plasma-plasmashell.service >/dev/null 2>&1; then
    log "restarted plasmashell (systemd)"
  elif command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell >/dev/null 2>&1 || true
    (setsid kstart plasmashell >/dev/null 2>&1 &) || true
    log "restarted plasmashell"
  fi
fi
