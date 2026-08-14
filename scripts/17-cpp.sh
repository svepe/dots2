#!/usr/bin/env bash
#
# C/C++ toolchain (apt): compilers + build tools, plus the tools nvim uses —
# clangd (LSP) and clang-format (format, via conform). Kept system-managed so
# the editor, CLI and CI share one LLVM version.
#
#   build-essential  gcc, g++, make
#   clang            the Clang compiler
#   clangd           C/C++ language server
#   clang-format     formatter (honours a project's .clang-format)
#   cmake            common build system
#
# Idempotent: only installs packages not already present.
#
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

pkgs=(build-essential clang clangd clang-format cmake)
missing=()
for p in "${pkgs[@]}"; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" || missing+=("$p")
done

if [ "${#missing[@]}" -eq 0 ]; then
  log "C/C++ toolchain already installed (${pkgs[*]})"
else
  log "installing: ${missing[*]} (apt, sudo)"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
fi
