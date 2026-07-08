#!/usr/bin/env bash
#
# Wire the dots2 bash fragment into ~/.bashrc. The fragment itself
# (~/.config/bash/dots.bash) is stowed by the `bash` package; here we just make
# the stock ~/.bashrc source it (guarded / idempotent).
#
set -euo pipefail

RC="$HOME/.bashrc"
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# Migrate: the starship init used to be its own appended block; dots.bash owns
# it now, so drop the old block if present.
if grep -qF '>>> dots2 starship/prompt >>>' "$RC" 2>/dev/null; then
  sed -i '/# >>> dots2 starship\/prompt >>>/,/# <<< dots2 starship\/prompt <<</d' "$RC"
  log "removed old starship block from .bashrc"
fi

if ! grep -qF '>>> dots2 bash >>>' "$RC" 2>/dev/null; then
  cat >> "$RC" <<'RCX'

# >>> dots2 bash >>>
[ -f ~/.config/bash/dots.bash ] && source ~/.config/bash/dots.bash
# <<< dots2 bash <<<
RCX
  log "added dots.bash source to .bashrc"
fi
