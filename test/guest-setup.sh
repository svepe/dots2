#!/usr/bin/env bash
#
# Run this INSIDE the Kubuntu guest to install the dotfiles from the repo shared
# by `./test/vm.sh run` (9p mount_tag 'dots'). It mounts the share, copies the
# repo into ~/.dots2 (so stow links to a guest-local copy and the host tree is
# never touched), and runs the full install with the private fonts that rode
# along in the copy — no GitHub or SSH access needed.
#
# Usage in the guest:   /mnt/dots/test/guest-setup.sh
#
set -euo pipefail

TAG="dots"
MNT="/mnt/dots"
DEST="$HOME/.dots2"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- mount the 9p share (read-only) -----------------------------------------
if ! mountpoint -q "$MNT"; then
  log "mounting 9p share '$TAG' -> $MNT (read-only)"
  sudo mkdir -p "$MNT"
  sudo mount -t 9p -o "trans=virtio,version=9p2000.L,ro" "$TAG" "$MNT" \
    || { echo "mount failed — did you boot with './test/vm.sh run'?"; exit 1; }
fi

# --- copy repo into the guest -----------------------------------------------
# tar is in the base image; rsync may not be.
#   --exclude=./test          drop the harness + heavy test/var (ISO+disk)
#   --exclude=./private/.git  private/ is its own git repo with an SSH remote to
#                             dots2-private; without its .git, scripts/20-private
#                             takes the "already present — using as-is" path
#                             instead of trying to `git pull` over SSH (no key in
#                             the guest → password prompt). The fonts still ride
#                             along, so --private below finds them locally.
log "copying repo -> $DEST"
mkdir -p "$DEST"
tar -C "$MNT" --exclude=./test --exclude=./private/.git -cf - . | tar -C "$DEST" -xf -

# --- bootstrap deps ---------------------------------------------------------
# install.sh assumes the base apt set is already present (bootstrap.sh installs
# it before cloning). We skip bootstrap.sh here (the repo is already copied), so
# install that same set ourselves — keep this in sync with bootstrap.sh.
log "installing bootstrap deps (git, stow, curl, build-essential)"
sudo apt-get -o DPkg::Lock::Timeout=60 update
sudo apt-get -o DPkg::Lock::Timeout=60 install -y git stow curl build-essential

# --- run the installer ------------------------------------------------------
# --private: private/ is already present (copied above), so scripts/20-private.sh
# uses it as-is instead of trying to clone dots2-private over SSH.
cd "$DEST"
log "running ./install.sh --private"
exec ./install.sh --private
