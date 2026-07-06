#!/usr/bin/env bash
#
# Enable bundled KWin scripts (Plasma 6). The script packages themselves are
# stowed to ~/.local/share/kwin/scripts/ by the `kwin` stow package; here we
# just flip them on in kwinrc and ask KWin to reload.
#
set -euo pipefail

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "kwriteconfig6 not found (not a KDE Plasma 6 session), skipping KWin scripts"
  exit 0
fi

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# Plugin ids (the "Id" from each script's metadata.json).
SCRIPTS=(borderless-tiled spatial-focus)

for s in "${SCRIPTS[@]}"; do
  kwriteconfig6 --file kwinrc --group Plugins --key "${s}Enabled" true
  log "enabled KWin script: $s"
done

# Nudge KWin to reload. Fully loading a newly-enabled script may still need a
# re-login; this makes the config change take on the next reconfigure at latest.
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi
log "requested KWin reconfigure — a fresh login guarantees scripts are loaded"
