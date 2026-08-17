#!/usr/bin/env bash
#
# Install atuin (shell history). Binary via atuin's cargo-dist installer with
# no PATH editing — it lands in ~/.atuin/bin, which dots.bash adds to PATH.
# Shell integration is wired in bash/.config/bash/dots.bash; config is the
# stowed atuin package. Local DB only — no sync/account.
#
# Idempotent: skips the install when atuin is already on PATH; seeds the DB from
# existing shell history only on first setup (empty DB) to avoid duplicates.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }

if ! command -v curl >/dev/null 2>&1; then
  err "curl not found — install it first (e.g. 'sudo apt install curl')"
  exit 1
fi

# Resolve atuin explicitly (installer default is ~/.atuin/bin) rather than
# touching PATH here — PATH is owned by dots.bash. This script runs
# non-interactively (no dots.bash), so we can't rely on it being on PATH.
ATUIN="$(command -v atuin 2>/dev/null || true)"
[ -z "$ATUIN" ] && [ -x "$HOME/.atuin/bin/atuin" ] && ATUIN="$HOME/.atuin/bin/atuin"

# --- install ----------------------------------------------------------------
if [ -n "$ATUIN" ]; then
  log "atuin already installed ($("$ATUIN" --version))"
else
  log "installing atuin -> ~/.atuin/bin"
  curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh \
    | ATUIN_NO_MODIFY_PATH=1 INSTALLER_NO_MODIFY_PATH=1 sh
  ATUIN="$HOME/.atuin/bin/atuin"
fi

# --- seed history from the shell's history file (first run only) -------------
if [ -x "$ATUIN" ] && [ ! -f "$HOME/.local/share/atuin/history.db" ]; then
  log "importing existing shell history (atuin import auto)"
  "$ATUIN" import auto || true
fi
