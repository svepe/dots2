#!/usr/bin/env bash
#
# Keep apt from racing unattended-upgrades for the dpkg lock. On a fresh boot the
# apt-daily / unattended-upgrades units grab the lock, so the per-app installers
# (05, 15, 17, 19, 22, 40) can die with:
#   Could not get lock /var/lib/dpkg/lock-frontend ... held by process ...unattended-upgr
# Runs first so everything after it gets a clean apt.
#
# Two parts:
#   1. Stop the apt-daily timers + unattended-upgrades for THIS boot so nothing
#      new grabs the lock mid-install. `stop` (not `disable`) — they come back
#      after the reboot install.sh prompts for, so security updates resume.
#   2. A short lock-timeout drop-in as a safety net: if a run is already in
#      flight, apt WAITS for it (a ceiling — it proceeds the instant the lock
#      frees) instead of failing. All later apt-using scripts inherit it.
#
# Idempotent.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

log "holding off apt-daily/unattended-upgrades for this boot"
sudo systemctl stop \
  apt-daily.timer apt-daily-upgrade.timer \
  unattended-upgrades.service apt-daily.service apt-daily-upgrade.service 2>/dev/null || true

log "setting apt lock timeout (safety net for an in-flight run)"
echo 'DPkg::Lock::Timeout "60";' | sudo tee /etc/apt/apt.conf.d/99dots-lock-timeout >/dev/null
