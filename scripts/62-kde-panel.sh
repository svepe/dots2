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

# --- panel appearance --------------------------------------------------------
# The snapshot above holds the panel's *contents* (which applets, in what order).
# Its looks — floating, transparent, 40px thick — live in plasmashellrc instead,
# keyed by the containment id: "Panel 27" is [Containments][27] in the snapshot.
# Restoring only the snapshot brings the widgets back on a stock-looking panel,
# so both halves have to be applied together. Written before the reload below so
# plasmashell picks them up in the same restart.
if command -v kwriteconfig6 >/dev/null 2>&1; then
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 27" --key floating 1
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 27" --key floatingApplets 1
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 27" --key panelOpacity 0
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 27" --key panelVisibility 0
  kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 27" --group Defaults \
    --key thickness 40
  log "panel appearance: floating, transparent, 40px thick"
fi

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
