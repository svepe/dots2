#!/usr/bin/env bash
#
# Install the Alacritty terminal. Its config is the stowed `alacritty` package;
# this installs the binary. The apt package also drops Alacritty.desktop into
# /usr/share/applications, which the Ctrl+Alt+T launcher shortcut (see
# scripts/90-kde-shortcuts.sh) targets — so install it before the shortcuts run.
#
# Ubuntu 26.04 ships 0.16.x, matching the host, so apt is the right source (no
# need for a cargo build).
#
# Idempotent: skips if alacritty is already on PATH.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if command -v alacritty >/dev/null 2>&1; then
  log "alacritty already installed ($(alacritty --version 2>/dev/null))"
else
  log "installing alacritty (apt)"
  sudo apt-get update -qq
  sudo apt-get install -y alacritty
fi
