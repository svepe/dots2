#!/usr/bin/env bash
#
# Install starship (the shell prompt) and bash-preexec. The shell wiring
# (sourcing bash-preexec, the preexec start-time hook, and `starship init`)
# lives in the bash fragment ~/.config/bash/dots.bash (see #3); starship.toml
# is stowed.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- starship (into ~/.local/bin, no sudo) ----------------------------------
if ! command -v starship >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/starship" ]; then
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
  log "installed starship"
fi

# --- bash-preexec (enables the preexec hook that stamps command start time) --
BP="$HOME/.config/bash/bash-preexec.sh"
if [ ! -f "$BP" ]; then
  mkdir -p "$(dirname "$BP")"
  curl -fsSL -o "$BP" \
    https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh
  log "installed bash-preexec"
fi

log "done — open a new shell (or 'exec bash') to load the prompt"
