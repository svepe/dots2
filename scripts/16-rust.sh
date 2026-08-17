#!/usr/bin/env bash
#
# Rust toolchain via rustup: rustc + cargo, plus the components nvim uses —
# rustfmt (format, via conform), clippy (lint), rust-analyzer (LSP). Keeping
# these as rustup components means they stay matched to the active toolchain
# (rather than a mason copy that could drift).
#
# Idempotent: installs rustup only if missing; `rustup component add` is a no-op
# for components already present.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# Resolve rustup explicitly (~/.cargo/bin) rather than touching PATH — PATH is
# owned by dots.bash, and this script runs non-interactively (no dots.bash).
RUSTUP="$(command -v rustup 2>/dev/null || true)"
[ -z "$RUSTUP" ] && [ -x "$HOME/.cargo/bin/rustup" ] && RUSTUP="$HOME/.cargo/bin/rustup"

# --- rustup -----------------------------------------------------------------
# --no-modify-path: don't touch shell rc; dots.bash puts ~/.cargo/bin on PATH.
if [ -n "$RUSTUP" ]; then
  log "rustup already installed ($("$RUSTUP" --version 2>/dev/null | head -1))"
else
  log "installing rustup (rustc + cargo)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  RUSTUP="$HOME/.cargo/bin/rustup"
fi

# --- components -------------------------------------------------------------
log "ensuring components: rustfmt, clippy, rust-analyzer"
"$RUSTUP" component add rustfmt clippy rust-analyzer
