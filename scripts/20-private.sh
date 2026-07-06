#!/usr/bin/env bash
#
# Fetch out-of-band private assets (licensed fonts, etc.) into private/ from a
# private repo. Runs before the installers that consume them (e.g. fonts).
#
# private/ is gitignored in this repo. Cloning needs access (SSH key) to the
# private repo; failure is non-fatal — the rest of the install continues.
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
  if [ ! -t 0 ]; then
    log "no terminal and DOTS_PRIVATE unset — skipping private assets"
    return 1
  fi
  read -rp "Fetch private assets from $REPO? [y/N] " ans
  [[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]
}

if ! want_private; then
  log "skipping private assets"
  exit 0
fi

# --- fetch / update ----------------------------------------------------------
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only && log "updated private/" || log "could not update private/ (continuing)"
elif [ -d "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  log "private/ already present (not a git clone) — using as-is"
else
  git clone "$REPO" "$DEST" && log "cloned private/" \
    || log "could not clone $REPO (no access?) — skipping private assets"
fi
