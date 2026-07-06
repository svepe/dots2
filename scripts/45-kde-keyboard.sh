#!/usr/bin/env bash
#
# KDE (Plasma 6) keyboard / XKB options — declarative and idempotent.
# Writes ~/.config/kxkbrc via kwriteconfig6. Applied by install.sh; XKB options
# take effect at next login.
#
#   caps:escape          Caps Lock acts as Escape
#   grp:alt_shift_toggle Alt+Shift cycles input-language layouts
#
set -euo pipefail

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "kwriteconfig6 not found (not a KDE Plasma 6 session), skipping KDE keyboard"
  exit 0
fi

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

kwriteconfig6 --file kxkbrc --group Layout --key "Options" "caps:escape,grp:alt_shift_toggle"
kwriteconfig6 --file kxkbrc --group Layout --key "ResetOldOptions" "true"
log "set XKB options: caps:escape, grp:alt_shift_toggle"

# Input-language layouts: US + Bulgarian (phonetic). VariantList is positional
# (one entry per layout in LayoutList), so us has an empty variant.
kwriteconfig6 --file kxkbrc --group Layout --key "Use" "true"
kwriteconfig6 --file kxkbrc --group Layout --key "LayoutList" "us,bg"
kwriteconfig6 --file kxkbrc --group Layout --key "VariantList" ",phonetic"
kwriteconfig6 --file kxkbrc --group Layout --key "DisplayNames" ","
log "set layouts: us, bg(phonetic)"

# Suppress the on-screen popup that appears on every layout switch.
kwriteconfig6 --file plasmarc --group OSD --key "kbdLayoutChangedEnabled" "false"
log "disabled layout-change OSD"
