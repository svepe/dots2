#!/usr/bin/env bash
#
# Python toolchain:
#   python3-venv  system venv support — mason installs pip-based LSP servers
#                 (basedpyright) into a venv; without it `python3 -m venv` fails.
#   uv            fast Python package/venv/interpreter/tool manager (use it for
#                 your projects: `uv venv`, `uv pip`, `uv run`, `uv python`).
#   ruff          lint + format + LSP — installed on its own so the editor
#                 (conform + ruff LSP), the CLI and any git hooks share one
#                 version.
#
# Idempotent: each step is skipped when already satisfied.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- system venv support (for mason's pip-based servers) --------------------
if python3 -c 'import ensurepip' >/dev/null 2>&1; then
  log "python3 venv support present"
else
  log "installing python3-venv (apt, sudo)"
  sudo apt-get update -qq
  sudo apt-get install -y python3-venv
fi

# --- uv ---------------------------------------------------------------------
# *_NO_MODIFY_PATH=1 stops the installer editing shell rc files (dots.bash puts
# ~/.local/bin on PATH instead).
if command -v uv >/dev/null 2>&1; then
  log "uv already installed ($(uv --version))"
else
  log "installing uv -> ~/.local/bin"
  curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
fi

# --- ruff (standalone, independent of uv) -----------------------------------
# To pin a version, append it to the URL path, e.g. .../ruff/0.6.9/install.sh.
if command -v ruff >/dev/null 2>&1; then
  log "ruff already installed ($(ruff --version))"
else
  log "installing ruff -> ~/.local/bin"
  curl -LsSf https://astral.sh/ruff/install.sh | RUFF_NO_MODIFY_PATH=1 sh
fi
