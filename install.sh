#!/usr/bin/env bash
#
# Symlink dotfiles into $HOME (via GNU stow) and run per-app installers.
# Safe to re-run: stow --restow re-links, installers should be idempotent.
#
# Run directly once the repo is cloned:
#   ./install.sh                 # prompts before fetching private assets
#   ./install.sh --no-private    # skip private assets (e.g. licensed fonts)
#   ./install.sh --private       # fetch private assets without prompting
#   ./install.sh -y              # auto-accept the end-of-install reboot prompt
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTS_DIR"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }

# --- flags ------------------------------------------------------------------
# --private/--no-private set DOTS_PRIVATE for the private-assets step (see
# scripts/20-private.sh). -y auto-accepts the reboot prompt (private assets have
# their own flag and are unaffected).
DOTS_YES=0
for arg in "$@"; do
  case "$arg" in
    --private)    export DOTS_PRIVATE=1 ;;
    --no-private) export DOTS_PRIVATE=0 ;;
    -y|--yes)     DOTS_YES=1 ;;
    *) err "unknown flag: $arg"; exit 1 ;;
  esac
done

# --- stow packages ----------------------------------------------------------
# One directory per app, laid out mirroring $HOME. `stow <pkg>` symlinks its
# contents into $HOME. Add packages here as each task lands.
STOW_PACKAGES=(
  alacritty
  atuin
  bash
  kwin
  nvim
  starship
  tmux
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
  # --no-folding: link individual files, never turn a whole ~/.config/<app> into
  # a symlink into the repo (apps write runtime state there, e.g. tmux plugins).
  stow --restow --no-folding --target="$HOME" --ignore='generate-theme\.sh$' "$pkg"
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

# --- offer a reboot ---------------------------------------------------------
# Several changes only fully apply after a restart: KDE global shortcuts
# (kglobalacceld reloads kglobalshortcutsrc at login), keyd, the appearance/panel
# session settings, and any freshly-installed kernel/driver bits. A reboot is the
# clean way to pick them all up. -y accepts without asking; otherwise prompt on
# the controlling terminal (default No), logging a note when there's none.
# SIGKILL kglobalacceld right before rebooting so it can't save its stale
# in-memory shortcuts over what 90-kde-shortcuts.sh just wrote (it may have
# respawned while this prompt waited). Then reboot immediately — the fresh boot
# loads the correct kglobalshortcutsrc. See 90-kde-shortcuts.sh for the why.
do_reboot() {
  pkill -9 -x kglobalacceld 2>/dev/null || true
  log "rebooting"
  systemctl reboot 2>/dev/null || sudo reboot
}
if [ "$DOTS_YES" = "1" ]; then
  do_reboot
elif [ -t 1 ] && [ -r /dev/tty ]; then
  # Read the controlling terminal, not stdin, so this still prompts under
  # `curl … | bash` (where stdin is the piped script, not a TTY).
  read -rp "$(printf '\033[1;34m==>\033[0m Reboot now to apply all changes? [y/N] ')" ans < /dev/tty || ans=""
  if [[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    do_reboot
  else
    log "skipped reboot — reboot (or at least log out/in) later to apply shortcuts/keyd/appearance"
  fi
else
  log "non-interactive — skipped reboot; reboot manually to apply shortcuts/keyd/appearance"
fi
