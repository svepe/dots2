#!/usr/bin/env bash
#
# tmux: install deps, the tpm plugin manager, plugins, and build the native
# tmux-mem-cpu-load binary. Config is stowed (tmux package); this handles the
# imperative bits. Re-runnable.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- dependencies ------------------------------------------------------------
# tmux, fzf (extrakto), wl-clipboard (yank on Wayland), build-essential + cmake
# (compile tmux-mem-cpu-load).
PKGS=(tmux fzf wl-clipboard build-essential cmake)
missing=()
for p in "${PKGS[@]}"; do
  dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done
if [ "${#missing[@]}" -gt 0 ]; then
  log "installing: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
fi

# --- tpm ---------------------------------------------------------------------
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  log "cloned tpm"
fi

# --- plugins -----------------------------------------------------------------
"$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || true
log "installed tmux plugins"

# --- build tmux-mem-cpu-load -------------------------------------------------
MCL="$HOME/.config/tmux/plugins/tmux-mem-cpu-load"
if [ -d "$MCL" ] && [ ! -x "$MCL/tmux-mem-cpu-load" ]; then
  ( cd "$MCL" && cmake . >/dev/null && make >/dev/null ) \
    && log "built tmux-mem-cpu-load" \
    || log "tmux-mem-cpu-load build failed (status bar cpu/mem segment will be blank)"
fi

log "done — reload with: tmux source ~/.config/tmux/tmux.conf"
