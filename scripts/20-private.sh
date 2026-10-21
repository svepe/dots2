#!/usr/bin/env bash
#
# Fetch out-of-band private assets (licensed fonts, etc.) into private/ from a
# private repo. Runs before the installers that consume them (e.g. fonts).
#
# private/ is gitignored in this repo. Cloning needs access to the private repo;
# failure is non-fatal — the rest of the install continues. If the SSH clone
# fails and we have a terminal, offer to install gh and print the login commands
# to run, then retry.
#
# Interactive by default; set DOTS_PRIVATE to skip the prompt:
#   DOTS_PRIVATE=1  -> fetch without asking
#   DOTS_PRIVATE=0  -> skip without asking
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="git@github.com:svepe/dots2-private.git"
DEST="$DOTS_DIR/private"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- decide whether to fetch private assets ---------------------------------
want_private() {
  case "${DOTS_PRIVATE:-}" in
    1|y|yes|true)  return 0 ;;
    0|n|no|false)  return 1 ;;
  esac
  if [ -t 1 ] && [ -r /dev/tty ]; then
    # Read the controlling terminal, not stdin, so this prompts under
    # `curl … | bash` too (stdin is the piped script there, not a TTY).
    read -rp "Fetch private assets from $REPO? [y/N] " ans < /dev/tty || ans=""
    [[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]
  else
    log "non-interactive and DOTS_PRIVATE unset — skipping private assets"
    return 1
  fi
}

if ! want_private; then
  log "skipping private assets"
  exit 0
fi

# --- offer gh when the SSH clone fails --------------------------------------
# Interactive only. Installs gh on request, shows the login commands, waits for
# the user to run one, then retries the clone. The login (and any logout) is
# theirs to run, so nothing here holds a token.
gh_assist() {
  [ -t 1 ] && [ -r /dev/tty ] || return 1
  local ans="" slug="${REPO#*:}"
  slug="${slug%.git}"

  if ! command -v gh >/dev/null 2>&1; then
    read -rp "SSH clone failed. Install gh (GitHub CLI) to authenticate? [y/N] " ans < /dev/tty || return 1
    [[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]] || return 1
    sudo apt-get -o DPkg::Lock::Timeout=60 install -y gh || return 1
  fi

  cat <<EOF

Log in with ONE of these (browser device flow, so 2FA works and the one-time
code can be approved on any device):

  temporary — revoke it when the install is done:
      gh auth login --hostname github.com --git-protocol https --web
      gh auth logout --hostname github.com

  permanent — adds an SSH key to your GitHub account:
      gh auth login --hostname github.com --git-protocol ssh --web

EOF
  read -rp "Press Enter once logged in, or 's' to skip: " ans < /dev/tty || return 1
  [[ "$ans" =~ ^[Ss] ]] && return 1

  gh repo clone "$slug" "$DEST"
}

# --- fetch / update ----------------------------------------------------------
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only && log "updated private/" || log "could not update private/ (continuing)"
elif [ -d "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  log "private/ already present (not a git clone) — using as-is"
else
  # BatchMode + a known-hosts bypass so an unattended install (VM harness, CI,
  # `curl | bash` on a machine with no GitHub key) fails fast instead of blocking
  # on a passphrase or an "authenticity of host github.com" prompt with no one
  # there to answer. Failure here is non-fatal by design.
  if GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
       git clone "$REPO" "$DEST"; then
    log "cloned private/"
  elif gh_assist; then
    log "cloned private/ (via gh)"
  else
    log "could not clone $REPO (no access?) — skipping private assets"
  fi
fi
