#!/usr/bin/env bash
#
# Regenerate every tool's themed config from the single source of truth
# (theme/palette.sh). Thin driver — the tool-specific logic lives in each
# package's generate-theme.sh. Run after editing the palette; commit the output.
#
#   ./theme/generate.sh
#
set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

found=0
for gen in "$DOTS_DIR"/*/generate-theme.sh; do
  [ -e "$gen" ] || continue
  found=1
  log "$(basename "$(dirname "$gen")")"
  bash "$gen"
done

[ "$found" = 1 ] || log "no */generate-theme.sh found"
log "done"
