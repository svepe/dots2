#!/usr/bin/env bash
#
# Symlink dotfiles into $HOME (via GNU stow) and run per-app installers.
# Safe to re-run: stow --restow re-links, installers should be idempotent.
#
# Run directly once the repo is cloned:
#   ./install.sh                 # prompts before fetching private assets
#   ./install.sh --no-private    # skip private assets (e.g. licensed fonts)
#   ./install.sh --private       # fetch private assets without prompting
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTS_DIR"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }

# --- flags ------------------------------------------------------------------
# Skip the interactive private-assets prompt (see scripts/20-private.sh) by
# exporting DOTS_PRIVATE for the imperative installers.
for arg in "$@"; do
  case "$arg" in
    --private)    export DOTS_PRIVATE=1 ;;
    --no-private) export DOTS_PRIVATE=0 ;;
    *) err "unknown flag: $arg"; exit 1 ;;
  esac
done

# --- stow packages ----------------------------------------------------------
# One directory per app, laid out mirroring $HOME. `stow <pkg>` symlinks its
# contents into $HOME. Add packages here as each task lands.
STOW_PACKAGES=(
  alacritty
  fontconfig
  kwin
  # bash
  # git
  # nvim
  # tmux
)

if ! command -v stow >/dev/null 2>&1; then
  err "stow not found — run ./bootstrap.sh first (it installs the deps)"
  exit 1
fi

# --- generate themed configs from the palette -------------------------------
# theme/generate.sh rebuilds each package's color files from theme/palette.sh.
# Run before stow so the generated files exist to be linked. Deterministic, so
# re-running produces no diff unless the palette changed.
if [ -x "$DOTS_DIR/theme/generate.sh" ]; then
  log "generate themed configs"
  "$DOTS_DIR/theme/generate.sh"
fi

# Per-package theme generators (generate-theme.sh) live inside packages but must
# not be symlinked into $HOME, so ignore them when stowing.
for pkg in "${STOW_PACKAGES[@]}"; do
  if [ ! -d "$pkg" ]; then
    err "package '$pkg' listed but directory missing, skipping"
    continue
  fi
  log "stow $pkg"
  stow --restow --target="$HOME" --ignore='generate-theme\.sh$' "$pkg"
done

# --- imperative installers --------------------------------------------------
# Things symlinks can't do: install packages, fonts, atuin, import KDE configs.
# Scripts in scripts/ run in filename order; prefix with NN- to control order.
if [ -d "$DOTS_DIR/scripts" ]; then
  for script in "$DOTS_DIR"/scripts/*.sh; do
    [ -e "$script" ] || continue
    log "run scripts/$(basename "$script")"
    bash "$script"
  done
fi

log "done"
