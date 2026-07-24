#!/usr/bin/env bash
#
# Install nvm (Node Version Manager) per-user, then the latest node/npm.
# node is needed by nvim's mason-managed tools (prettier, pyright, and the
# json/yaml language servers).
#
# The nvm installer is told NOT to edit any shell rc file (PROFILE=/dev/null);
# sourcing lives in bash/.config/bash/dots.bash instead. Per-user, no sudo.
# Idempotent: skips the nvm install when already present; `nvm install node`
# is safe to re-run.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }

if ! command -v curl >/dev/null 2>&1; then
  err "curl not found — install it first (e.g. 'sudo apt install curl')"
  exit 1
fi

export NVM_DIR="$HOME/.nvm"

# --- install nvm ------------------------------------------------------------
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  # Resolve the latest nvm release tag via the /releases/latest redirect, with
  # a pinned fallback if the lookup fails.
  ver="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
         https://github.com/nvm-sh/nvm/releases/latest 2>/dev/null \
         | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$' || true)"
  ver="${ver:-v0.40.3}"
  log "installing nvm $ver"
  PROFILE=/dev/null bash -c \
    "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$ver/install.sh | bash"
else
  log "nvm already installed"
fi

# --- install latest node/npm ------------------------------------------------
# nvm.sh is not `set -eu`-clean, so relax while sourcing and driving nvm.
set +eu
# shellcheck disable=SC1091
\. "$NVM_DIR/nvm.sh"
log "installing latest node"
nvm install node
nvm alias default node
set -eu

if ! command -v node >/dev/null 2>&1; then
  err "node not found on PATH after install"
  exit 1
fi
log "node $(node --version) / npm $(npm --version)"
