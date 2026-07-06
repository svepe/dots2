#!/usr/bin/env bash
#
# Dolphin (file manager) settings — declarative and idempotent. Writes
# ~/.config/dolphinrc via kwriteconfig6; Dolphin reads it on next launch.
# Volatile keys (Version, ViewPropsTimestamp) and the environment-specific
# thumbnail-plugin list are intentionally not captured.
#
set -euo pipefail

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "kwriteconfig6 not found (not a KDE Plasma 6 session), skipping Dolphin"
  exit 0
fi

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

kwriteconfig6 --file dolphinrc --group General --key "RememberOpenedTabs" "false"
kwriteconfig6 --file dolphinrc --group General --key "ShowStatusBar" "FullWidth"
kwriteconfig6 --file dolphinrc --group MainWindow --key "MenuBar" "Disabled"
kwriteconfig6 --file dolphinrc --group "KFileDialog Settings" --key "Places Icons Auto-resize" "false"
kwriteconfig6 --file dolphinrc --group "KFileDialog Settings" --key "Places Icons Static Size" "22"
log "wrote Dolphin settings"
