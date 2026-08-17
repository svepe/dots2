#!/usr/bin/env bash
#
# KDE (Plasma 6) desktop appearance / KWin effects — declarative and idempotent.
# Writes kwinrc/kcminputrc via kwriteconfig6, applies the global (dark) theme and
# cursor via the plasma-apply-* tools, and asks KWin to reconfigure.
#
set -euo pipefail

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "kwriteconfig6 not found (not a KDE Plasma 6 session), skipping KDE appearance"
  exit 0
fi

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- Translucency effect -----------------------------------------------------
# Make inactive windows slightly transparent (90% opacity).
kwriteconfig6 --file kwinrc --group Plugins --key "translucencyEnabled" "true"
kwriteconfig6 --file kwinrc --group "Effect-translucency" --key "Inactive" "90"
log "translucency: inactive windows at 90%"

# --- virtual desktops --------------------------------------------------------
# 5x3 grid, navigation wraps around, and the switch OSD is text-only with a
# short (400ms) duration.
kwriteconfig6 --file kwinrc --group Desktops --key "Number" "15"
kwriteconfig6 --file kwinrc --group Desktops --key "Rows" "3"
kwriteconfig6 --file kwinrc --group Windows --key "RollOverDesktops" "true"
kwriteconfig6 --file kwinrc --group Plugins --key "desktopchangeosdEnabled" "true"
kwriteconfig6 --file kwinrc --group "Script-desktopchangeosd" --key "TextOnly" "true"
kwriteconfig6 --file kwinrc --group "Script-desktopchangeosd" --key "PopupHideDelay" "400"
log "virtual desktops: 5x3, text-only OSD (400ms)"

# --- cursor ------------------------------------------------------------------
kwriteconfig6 --file kcminputrc --group Mouse --key "cursorSize" "24"
kwriteconfig6 --file kcminputrc --group Mouse --key "cursorTheme" "breeze_cursors"
if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
  plasma-apply-cursortheme breeze_cursors --size 24 >/dev/null 2>&1 || true
fi
log "cursor: breeze_cursors, size 24"

# --- global appearance: always dark ------------------------------------------
# Apply the Kubuntu dark global theme (BreezeDark colors + kubuntu-dark Plasma
# style + breeze-dark icons). No --resetLayout, so the panel (scripts/62) stays.
if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
  plasma-apply-lookandfeel --apply org.kubuntudark.desktop >/dev/null 2>&1 || true
  log "global theme: org.kubuntudark.desktop (dark)"
fi

# KWin picks up effect config changes on reconfigure (no re-login needed).
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi
log "requested KWin reconfigure"
