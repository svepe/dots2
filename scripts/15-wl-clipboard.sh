#!/usr/bin/env bash
#
# Build wl-clipboard >= 2.3 from source when the distro ships something older.
#
# Why: wl-clipboard < 2.3 has no ext-data-control-v1 support, so on KWin/Wayland
# it grabs the clipboard by spawning a hidden "fake window" for every copy/paste.
# That window briefly steals activation, flipping the focused window to inactive
# for one frame — a visible flash under any inactive-window effect (translucency,
# dim). 2.3 uses the surfaceless ext-data-control-v1 protocol (which KWin
# implements), so no window, no flash. Ubuntu 26.04 LTS froze at 2.2.1.
#
# Idempotent: exits early once wl-copy reports >= 2.3.
#
set -euo pipefail

WL_MIN=2.3          # version gate
WL_TAG=v2.3.0       # tag to build when the gate isn't met
WL_REPO=https://github.com/bugaevc/wl-clipboard

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }

wl_version() { wl-copy --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)+' | head -1; }

# --- skip if a new-enough wl-copy is already on PATH ------------------------
if command -v wl-copy >/dev/null 2>&1; then
  current="$(wl_version)"
  if [ -n "$current" ] && dpkg --compare-versions "$current" ge "$WL_MIN"; then
    log "wl-clipboard $current already >= $WL_MIN — skipping"
    exit 0
  fi
  log "wl-clipboard ${current:-unknown} < $WL_MIN — building $WL_TAG from source"
else
  log "wl-clipboard not found — building $WL_TAG from source"
fi

# --- drop the distro package ------------------------------------------------
# Remove the apt wl-clipboard so it can't coexist with (or shadow, if PATH ever
# reorders) the /usr/local build we're about to install.
if dpkg-query -W -f='${Status}' wl-clipboard 2>/dev/null | grep -q "install ok installed"; then
  log "removing distro wl-clipboard package (sudo)"
  sudo apt-get remove -y wl-clipboard
fi

# --- build dependencies -----------------------------------------------------
# ext-data-control-v1 support is compiled in ONLY when wayland-protocols (>=1.39)
# provides the protocol XML at build time; without it meson silently drops the
# feature and the fake-window fallback (and the flash) comes right back.
need=(git meson ninja-build pkg-config libwayland-dev wayland-protocols scdoc)
missing=()
for p in "${need[@]}"; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || missing+=("$p")
done
if [ "${#missing[@]}" -gt 0 ]; then
  log "installing build deps: ${missing[*]} (sudo)"
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends "${missing[@]}"
fi

# --- fetch, build, install to /usr/local (shadows the apt binary on PATH) ---
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "clone $WL_TAG"
git clone --depth 1 --branch "$WL_TAG" "$WL_REPO" "$tmp/src"

log "build"
meson setup "$tmp/build" "$tmp/src"
ninja -C "$tmp/build"

log "install (sudo)"
sudo ninja -C "$tmp/build" install

# --- verify -----------------------------------------------------------------
hash -r
new="$(wl_version)"
if [ -n "$new" ] && dpkg --compare-versions "$new" ge "$WL_MIN"; then
  log "wl-clipboard $new installed ($(command -v wl-copy))"
else
  err "build finished but wl-copy reports '${new:-unknown}' (< $WL_MIN) — check that"
  err "/usr/local/bin precedes /usr/bin on PATH, and that wayland-protocols is >= 1.39"
  exit 1
fi
