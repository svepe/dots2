# dots2 interactive bash config. Sourced from ~/.bashrc (see scripts/10-bash.sh).
# Kept as a fragment so the stock ~/.bashrc stays intact.

# --- vi keybindings ----------------------------------------------------------
set -o vi

# --- history -----------------------------------------------------------------
#   HISTSIZE/HISTFILESIZE : ~unlimited in-memory and on-disk history
#   HISTCONTROL=ignoreboth: ignore space-prefixed commands and consecutive dups
#   histappend            : append to the history file, don't overwrite it
#   cmdhist               : keep a multi-line command as one history entry
#   checkwinsize          : keep $LINES/$COLUMNS correct after a resize
#   PROMPT_COMMAND        : append each command immediately, so history survives
#                           crashes / non-clean exits (not just clean logouts)
HISTSIZE=1000000
HISTFILESIZE=1000000
HISTCONTROL=ignoreboth
shopt -s histappend cmdhist checkwinsize
PROMPT_COMMAND='history -a'

# --- node (nvm) --------------------------------------------------------------
# nvm is installed by scripts/18-node.sh with rc-file editing disabled, so we
# source it here. Provides node/npm, needed by nvim's mason-managed tools
# (prettier, pyright, and the json/yaml language servers).
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- prompt (starship) + command timing --------------------------------------
# bash-preexec (installed by scripts/35-starship.sh) gives us a preexec hook to
# stamp the command *start* time that starship shows; it also preserves the
# PROMPT_COMMAND above. starship init comes last.
if [ -f ~/.config/bash/bash-preexec.sh ]; then
  source ~/.config/bash/bash-preexec.sh
  _dots_cmd_start() { export STARSHIP_CMD_START="$(date +%R)"; }
  preexec_functions+=(_dots_cmd_start)
fi
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
