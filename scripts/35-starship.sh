#!/usr/bin/env bash
#
# Install starship (the shell prompt) and wire up bash: bash-preexec + a preexec
# hook that records each command's *start* time (STARSHIP_CMD_START), which the
# prompt shows in place of a wall-clock. starship.toml itself is stowed.
#
# The .bashrc block is a stopgap until task 3 (bash) manages .bashrc properly.
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

# --- .bashrc integration (guarded / idempotent) -----------------------------
if ! grep -qF '>>> dots2 starship/prompt >>>' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'RC'

# >>> dots2 starship/prompt >>>
[ -f ~/.config/bash/bash-preexec.sh ] && source ~/.config/bash/bash-preexec.sh
_dots_cmd_start() { export STARSHIP_CMD_START="$(date +%R)"; }
preexec_functions+=(_dots_cmd_start)
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
# <<< dots2 starship/prompt <<<
RC
  log "added starship+preexec block to ~/.bashrc"
fi

log "done — open a new shell (or 'exec bash') to load the prompt"
