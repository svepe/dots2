#!/usr/bin/env bash
#
# Install the patched MonoLisaCode Nerd Font into the user font dir (not stowed
# — keeps the binaries out of the $HOME dotfile tree and lets fc-cache own them).
# The fonts come from private/fonts/patched (MonoLisa patched with Nerd Font
# glyphs; supplied out-of-band via scripts/20-private.sh). Re-runnable.
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$DOTS_DIR/private/fonts/patched"
DEST="$HOME/.local/share/fonts"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

mkdir -p "$DEST"
count=0
if [ -d "$SRC" ]; then
  while IFS= read -r -d '' f; do
    install -Dm644 "$f" "$DEST/$(basename "$f")"
    count=$((count + 1))
  done < <(find "$SRC" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0)
fi

fc-cache -f "$DEST" >/dev/null 2>&1 || true
log "installed $count font file(s) to $DEST"

# --- KDE default monospace font ----------------------------------------------
# Only set it if MonoLisaCode is actually installed (it's supplied out-of-band,
# so it may be absent when private assets were skipped). Spec captured verbatim
# from System Settings (Plasma 6 / Qt6 format).
if command -v kwriteconfig6 >/dev/null 2>&1; then
  if fc-list | grep -i 'MonoLisaCode Nerd Font' >/dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key "fixed" \
      "MonoLisaCode Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    log "set KDE monospace font to MonoLisaCode Nerd Font"
  else
    log "MonoLisaCode Nerd Font not installed — leaving KDE monospace font unchanged"
  fi
fi
