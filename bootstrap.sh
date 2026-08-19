#!/usr/bin/env bash
#
# Fresh-machine bootstrap. Installs required dependencies, clones the repo,
# then hands off to install.sh.
#
# Usage on a brand new system:
#   curl -fsSL https://raw.githubusercontent.com/svepe/dots2/main/bootstrap.sh | bash
#
set -euo pipefail

REPO_URL="${DOTS_REPO:-https://github.com/svepe/dots2.git}"
DOTS_DIR="${DOTS_DIR:-$HOME/.dots2}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- required dependencies for bootstrapping -------------------------------
# git             : clone the repo
# stow            : symlink the dotfiles into place (see install.sh)
# curl            : fetch this script and other installers
# build-essential : C/C++ toolchain — needed to build wl-clipboard (script 15,
#                   which runs before the cpp toolchain) and by 17-cpp.sh
# -o DPkg::Lock::Timeout: wait (bounded) for the lock rather than failing if
# unattended-upgrades is mid-run on a fresh boot. scripts/01-apt.sh makes this
# the default for the rest of the install, but that runs later, so set it here.
log "installing bootstrap dependencies (git, stow, curl, build-essential)"
sudo apt-get -o DPkg::Lock::Timeout=60 update
sudo apt-get -o DPkg::Lock::Timeout=60 install -y git stow curl build-essential

# --- fetch the repo ---------------------------------------------------------
if [ -d "$DOTS_DIR/.git" ]; then
  log "repo already present at $DOTS_DIR, pulling latest"
  git -C "$DOTS_DIR" pull --ff-only
else
  log "cloning $REPO_URL -> $DOTS_DIR"
  mkdir -p "$(dirname "$DOTS_DIR")"
  git clone "$REPO_URL" "$DOTS_DIR"
fi

# --- apply everything -------------------------------------------------------
cd "$DOTS_DIR"
exec ./install.sh
