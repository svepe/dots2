#!/usr/bin/env bash
#
# Install Neovim. The config (stowed `nvim` package) targets 0.12+ — vim.pack and
# the 0.11 vim.lsp.enable/config API — which is newer than apt's 0.11.x. The snap
# (classic) tracks stable and matches the host (0.12.4), so use that.
#
# Plugins and LSP servers install themselves on the first `nvim` launch (vim.pack
# + mason), drawing on the language toolchains and node installed by scripts
# 16-19 — hence this runs after them.
#
# Idempotent: skips if nvim is already on PATH.
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- install the binary -----------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  log "neovim already installed ($(nvim --version 2>/dev/null | head -1))"
else
  # snapd ships on Kubuntu, but install it if this is a stripped-down system.
  if ! command -v snap >/dev/null 2>&1; then
    log "installing snapd (needed for the neovim snap)"
    sudo apt-get update -qq
    sudo apt-get install -y snapd
  fi
  log "installing neovim (snap, classic) — provides /snap/bin/nvim"
  sudo snap install nvim --classic
fi

# --- warm up headlessly -----------------------------------------------------
# Pre-install what the config pulls on first launch (plugins via vim.pack;
# LSPs/formatters via mason; treesitter parsers) so the editor is ready offline.
# Best-effort and bounded (see scripts/nvim-warmup.lua) — anything not finished
# tops off on the first interactive launch. Needs the language toolchains + node
# (scripts 16-19), which is why this runs after them.
NVIM="$(command -v nvim 2>/dev/null || true)"
[ -z "$NVIM" ] && [ -x /snap/bin/nvim ] && NVIM=/snap/bin/nvim
if [ -n "$NVIM" ]; then
  log "warming up neovim (plugins, LSPs, formatters, treesitter parsers)"
  "$NVIM" --headless -c "luafile $HERE/nvim-warmup.lua" -c "qa!" \
    || log "nvim warm-up incomplete — the first launch will finish it"
fi
